#!/usr/bin/python

import sys, os, stat

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

excludeList = (
    ".svn", "obj",
    "config.guess", "config.status", "config.log", "config.cache",
    "Resources",
    "ix86"
)
excludeSuffixes = (
    ".xcode", ".o", ".so", "_obj", ".gdladaptor", ".sax", ".sxp",
    ".zsp", ".woa", ".bundle"
)

def shouldHideFile(filename):
    if filename in excludeList:
        return 1
    for s in excludeSuffixes:
        if filename[-len(s):] == s:
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

def compareDirectories(pathA, pathB, recurse=0):
    contentsA = os.listdir(pathA)
    contentsB = os.listdir(pathB)
    same, added, removed = compareLists(contentsA, contentsB)
    result = { 'added': [], 'removed': [], 'children': {} }
    
    relpath = makeRelPath(treeA, pathA)
    
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

def printDifferences(diffs):
    if diffs.has_key("added"):
        for p in diffs['added']:
            print "added:  ", p
    if diffs.has_key("removed"):
        for p in diffs['removed']:
            print "removed:", p
    if diffs.has_key("children"):
        for p, subdiffs in diffs['children'].items():
            printDifferences(subdiffs)

# run

print "compare", treeA, "with", treeB

result = compareDirectories(treeA, treeB, 1)
printDifferences(result)

