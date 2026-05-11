# SPDX-FileCopyrightText: 2026 b0nn133 <b0nn133@noreply.codeberg.org>
# SPDX-License-Identifier: LGPL-3.0-only

## libcarryon - archive.nim

import std/[osproc, tempfiles, strformat, strutils, os, tables]
import types, utils, parser

# extract the archive
proc extract*(archive: CRNArchive, dest: string) =
    try:
        if not fileExists archive.path:
            raise newException(ArchiveError, fmt"archive not found: {archive.path}")

        if not dirExists dest: createDir dest # create destination directory if it doesnt exist

        let errorCode = execCmd fmt"tar -xf {archive.path} -C {dest}" # extract the archive
  
        if errorCode != 0:
            raise newException(ArchiveError, fmt"tar failed with exit code {errorCode}")
        else:
            archive.isLoaded = true

    except CatchableError as e: 
        raise newException(ArchiveError, fmt"failed to extract: {e.msg}")

# apply the archive
proc apply*(archive: CRNArchive) = 
    try:
        let tmp = genTempPath("CRN_", "EXTRACTED")
        if not archive.isLoaded: archive.extract tmp

        # install packages
        for p in archive.packages:
            let cmd = fmt"{p.manager} {p.installCommand}" % p.name
            if execCmd(cmd) != 0:
                raise newException(ArchiveError, "failed to install package: " & p.name)

        # move configs
        for pc in walkDirRec(tmp / "home", yieldFilter = {pcFile}):
            # get hash
            let relPath = pc.relativePath(tmp) 
            
            if archive.hashes.hasKey(relPath):
                if compareFileHash(archive.hashes[relPath], pc):
                    # get dest path
                    let dest = getHomeDir() / pc.relativePath(tmp / "home")
                    createDir(dest.parentDir()) 
                    moveFile(pc, dest)
                else:
                    raise newException(IntegrityError, fmt"file is corrupted: {relPath}")

    except CatchableError as e:
        raise newException(ArchiveError, fmt"failed to apply: {e.msg}")


# make the archive
proc make*(archive: CRNArchive) = 
    try:
        let tmp = genTempPath("CRN_BUILD_", "WORK")
        createDir tmp / "home"
        createDir tmp / "packages"

        # save metadata & hashes
        writeFile tmp / "metadata.json", archive.saveMetadata
        writeFile tmp / "hashes.json", archive.saveHashes

        # save into packages/ dir
        for p in archive.packages:
            let pPath = tmp / "packages" / (p.name & ".json")
            writeFile pPath, p.savePackage

        # pack to .crn
        let cmd = fmt"tar -cJf {archive.path} -C {tmp} ."
        let exitCode = execCmd(cmd)
        if exitCode != 0:
            raise newException(ArchiveError, fmt"tar failed with exit code {exitCode}")
            
    except CatchableError as e:
        raise newException(ArchiveError, fmt"failed to create: {e.msg}")
