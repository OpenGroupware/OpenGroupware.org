#!/usr/bin/python

import sys, os, stat

excludeList = (
    ".svn", "obj",
    "config.guess", "config.status", "config.log", "config.cache",
    #"Resources",
    "ix86", "core"
)
excludeSuffixes = (
    ".xcode", ".o", ".so", "_obj", ".gdladaptor", ".sax", ".sxp",
    ".zsp", ".woa", ".bundle", ".tmp", ".ds", ".model", ".lso",
    ".cmd", ".odr"
)

def usage():
    print "usage: %s <tree a> <tree b>" % ( sys.argv[0], )
    sys.exit(1)

if len(sys.argv) < 3:
    usage()

treeA = sys.argv[1]
treeB = sys.argv[2]

# funcs

def compareLists(pathA, pathB):
    "returns a triple containing paths in both, paths added and paths removed"
    both    = []
    added   = []
    removed = []
    for p in pathA:
        if shouldHideFile(p):
            continue
        if p in pathB:
            both.append(p)
        else:
            removed.append(p)
    for p in pathB:
        if shouldHideFile(p):
            continue
        if not p in pathA:
            added.append(p)
    return (both, added, removed)

# end compareLists

def shouldHideFile(filename):
    if filename in excludeList:
        return 1
    for s in excludeSuffixes:
        if filename.endswith(s):
            return 1
    return 0

def makeRelPath(base, path):
    prefixlen=len(base)
    relpath=path[prefixlen:]
    if len(relpath) < 2:
        return relpath
    if relpath[0] == "/":
        relpath = relpath[1:]
    if relpath[-1:] != "/":
        relpath = relpath + "/"
    #print "relpath:", relpath
    return relpath

def compareChangeLogs(pathA, pathB):
    #print "COMP:", pathA, "and", pathB
    if os.stat(pathA)[stat.ST_SIZE] == os.stat(pathB)[stat.ST_SIZE]:
        "sufficiently correct in practice, ChangeLogs should always grow ..."
        return None
    sA = open(pathA, "r").read()
    sB = open(pathB, "r").read()
    if len(sA) > len(sB):
        t = sA
        sA = sB
        sB = t
    t = sB[:-len(sA)]
    del sA, sB
    return t

def compareDirectories(pathA, pathB, recurse=0):
    contentsA = os.listdir(pathA)
    contentsB = os.listdir(pathB)
    same, added, removed = compareLists(contentsA, contentsB)
    result = { 'added': [], 'removed': [], 'children': {} }
    
    bothHaveChangeLog = "ChangeLog" in contentsA and "ChangeLog" in contentsB
    if bothHaveChangeLog:
        txt = compareChangeLogs(pathA + "/ChangeLog", pathB + "/ChangeLog")
        if txt is not None:
            result['ChangeLog'] = txt
    
    relpath = makeRelPath(treeA, pathA)
    result['path'] = relpath
    
    for p in added:
        result['added'].append(relpath + p)
    for p in removed:
        result['removed'].append(relpath + p)
    
    if recurse:
        for p in same:
            if shouldHideFile(p):
                continue
            pa = pathA + "/" + p
            pb = pathB + "/" + p
            #print "PB:", pb
            mode = os.stat(pa)[stat.ST_MODE]
            if not stat.S_ISDIR(mode):
                continue
            result['children'][relpath + p] = compareDirectories(pa, pb, 1)
    
    return result

# end comparePathes

def printChangeLog(ChangeLog, indent, compress=0):
    for line in ChangeLog.splitlines(0):
        if compress:
            stripped = line.strip()
            if len(stripped) == 0:
                continue
        print indent, line

def printDifferences(diffs, compress=0):
    if diffs.has_key("ChangeLog"):
        print "changed:", diffs['path']
        printChangeLog(diffs['ChangeLog'], "    ", compress)
    
    if diffs.has_key("added"):
        for p in diffs['added']:
            print "added:  ", p
    if diffs.has_key("removed"):
        for p in diffs['removed']:
            print "removed:", p
    
    if diffs.has_key("children"):
        for p, subdiffs in diffs['children'].items():
            printDifferences(subdiffs, compress)

# run

print "compare", treeA, "with", treeB

result = compareDirectories(treeA, treeB, recurse=1)
printDifferences(result, compress=1)
