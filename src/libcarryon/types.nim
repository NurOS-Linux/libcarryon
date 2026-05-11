# SPDX-FileCopyrightText: 2026 b0nn133 <b0nn133@noreply.codeberg.org>
# SPDX-License-Identifier: LGPL-3.0-only

## libcarryon - types.nim
 
import std/tables

type
    # the base exception for everything in the lib
    CarryonError* = object of CatchableError
  
    # specific errors
    IntegrityError* = object of CarryonError # occurs when a file is corrupted
    ParserError* = object of CarryonError # occurs when parser encountered an error
    ArchiveError* = object of CarryonError # occurs when an archive is corrupted

    # objects
    Metadata* = ref object # object for metadata.json
        version*: string
        timestamp*: int64
    HashMapping* = ref Table[string, uint64] # mapping for a hash from hashes.json
    Package* = ref object
        name*: string
        installCommand*: string
        version*: string
        manager*: string

    CRNArchive* = ref object # object for a .crn archive
        path*: string
        metadata*: Metadata
        hashes*: HashMapping
        packages*: seq[Package]
        isLoaded*: bool

# constructor for CRNArchive object
proc newCRNArchive*(path: string = ""): CRNArchive =
  return CRNArchive(
    path: path,
    metadata: Metadata(),
    hashes: newTable[string, uint64](),
    packages: @[],
    isLoaded: false
  )
