# SPDX-FileCopyrightText: 2026 b0nn133 <b0nn133@noreply.codeberg.org>
# SPDX-License-Identifier: LGPL-3.0-only

## libcarryon - parser.nim

import std/[json, tables, strutils, strformat, os]
import types

# general function for all load* functions
proc load(jsonStr: string, exceptionMessage: string, hook: proc(n: JsonNode)) = 
    try:
        let parsedJson = parseJson jsonStr
        hook parsedJson
    except CatchableError as e:
        raise newException(ParserError, exceptionMessage % e.msg)

# load metadata
proc loadMetadata*(archive: CRNArchive, jsonStr: string) =
    load(jsonStr, "failed to parse metadata: $#") do (metadata: JsonNode):
        archive.metadata.version = metadata["version"].getStr
        archive.metadata.timestamp = metadata["timestamp"].getBiggestInt 

# load hashes
proc loadHashes*(archive: CRNArchive, jsonStr: string) =
    load(jsonStr, "failed to parse hashes: $#") do (hashes: JsonNode):
        for path, hash in hashes.getFields:
            archive.hashes[path] = hash.getBiggestInt.uint64

# load package
proc loadPackage*(archive: CRNArchive, jsonStr: string) =
    load(jsonStr, "failed to parse package: $#") do (node: JsonNode):
        let pkg = Package(
            name: node["name"].getStr,
            version: node["version"].getStr,
            manager: node["manager"].getStr
        )
        archive.packages.add pkg

# load all packages
proc loadAllPackages*(archive: CRNArchive, packagesDir: string) =
    if not dirExists packagesDir: return

    for file in walkFiles(fmt"{packagesDir}/*.json"):
        let content = readFile file
        archive.loadPackage content

# save metadata
proc saveMetadata*(archive: CRNArchive): string =
    let j = %* {
        "version": archive.metadata.version,
        "timestamp": archive.metadata.timestamp
    }
    return $j

# save hashes
proc saveHashes*(archive: CRNArchive): string =
    return $(%archive.hashes)

# add package
proc addPackage*(archive: CRNArchive, name, version, manager, installCmd: string) =
    let pkg = Package(
        name: name,
        version: version,
        manager: manager,
        installCommand: installCmd
    )
    archive.packages.add pkg

# save package
proc savePackage*(pkg: Package): string =
    let j = %* {
        "name": pkg.name,
        "version": pkg.version,
        "manager": pkg.manager,
        "installCommand": pkg.installCommand
    }
    return $j