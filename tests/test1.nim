import unittest
import std/[tables, strutils, os]
import libcarryon

suite "libcarryon":

  test "metadata parsing and saving":
    let arch = newCRNArchive "test.crn"
    let jsonIn = """{"version": "0.1.0", "timestamp": 1212121212}"""
    arch.loadMetadata jsonIn
    check arch.metadata.version == "0.1.0"
    check arch.metadata.timestamp == 1212121212
    let jsonOut = arch.saveMetadata
    check jsonOut.contains "\"version\":\"0.1.0\""

  test "hash mapping with uint64":
    let arch = newCRNArchive "test.crn"
    let json = """{"home/.config/hi.txt": 123123123123}"""
    arch.loadHashes json
    check arch.hashes.hasKey "home/.config/hi.txt"
    check arch.hashes["home/.config/hi.txt"] == 123123123123.uint64

  test "package handling":
    let arch = newCRNArchive "test.crn"
    arch.addPackage "firefox", "130", "tulpar", "install -y %s" 
    check arch.packages.len == 1
    check arch.packages[0].name == "firefox"

  test "full cycle: create -> extract -> verify":
    let testCrn = "test_system.crn"
    let arch = newCRNArchive testCrn
    
    arch.metadata.version = "0.1.0"
    arch.metadata.timestamp = 123456789
    arch.addPackage "test-pkg", "1.0", "tulpar", "install %s"
    
    let sloganFile = "slogan.txt"
    writeFile sloganFile, "Shine brighter than the rest by thinking different"
    let fHash = getFileHash sloganFile
    arch.hashes["home/dummy.txt"] = fHash
    
    arch.make
    check fileExists testCrn

    let extractDir = "test_extracted"
    if dirExists extractDir: removeDir extractDir
    
    arch.extract extractDir
    
    check dirExists extractDir
    check fileExists extractDir / "metadata.json"
    check fileExists extractDir / "hashes.json"

    removeFile testCrn
    removeFile sloganFile
    removeDir extractDir
