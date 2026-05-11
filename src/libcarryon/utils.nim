# SPDX-FileCopyrightText: 2026 b0nn133 <b0nn133@noreply.codeberg.org>
# SPDX-License-Identifier: LGPL-3.0-only

## libcarryon - utils.nim

import std/[os, streams], xxhash
export XXH64 

proc getFileHash*(path: string): uint64 =
    if not fileExists path: return 0
  
    # create stream to read the file
    var fs = openFileStream(path, fmRead)
    defer: fs.close # close it

    # init hash state
    var state = newXxh64()

    # read the file in chunks (8kb each)
    var buffer: array[8192, byte]
    while not fs.atEnd:
        let bytesRead = fs.readData(addr(buffer), buffer.len)
        if bytesRead > 0:
            var chunk = newString bytesRead
            copyMem addr(chunk[0]), addr(buffer), bytesRead
            state.update chunk

    result = state.digest

proc compareHashes*(hash: uint64, str: string): bool =
    # convert string to a xxh64, then compare 
    return XXH64(str) == hash

proc compareHashes*(originalHash: uint64, hashToCompare: uint64): bool =
    # compare hash with a hash
    return hashToCompare == originalHash

proc compareFileHash*(originalHash: uint64, filePath: string): bool =
    # convert file contents to a xxh64, then compare
    return compareHashes(originalHash, getFileHash(filePath))