#!/usr/bin/env python
# ZNeK - 20031011

"""
ChangeLog parser.
"""

__version__ = "@()$Id: changelogparser.py,v 1.3 2003/10/20 15:42:14 znek Exp $"


import sys
import time
import re


##
##  HELPERS
##


def sortDescending(a, b):
    ai = int(a)
    bi = int(b)
    if ai < bi:
        return 1
    elif ai > bi:
        return -1
    return 0


def xmlQuotedString(string):
    # XXX: Couldn't we do better?
    string = string.replace("&", "&amp;")
    string = string.replace("<", "&lt;")
    string = string.replace(">", "&gt;")
    string = string.replace("\"", "&quot;")
    string = string.replace("'", "&apos;")
    return string


def htmlQuotedString(string):
    # XXX: Couldn't we do better?
    string = string.replace("<", "&lt;")
    string = string.replace(">", "&gt;")
    return string


def fullFSPathForArchiveNamed(config, archiveName):
    path = config["webRoot"] + "/" + config["webArchivePath"] + "/" + archiveName
    return path


def getDateFromEntryStart(start):
    """
    Note: When starting to write this function, I had no idea where this would end. Apparently it
    needs to be rewritten. Please note that the first 2 checks work for almost all cases in OGo,
    so they should remain at the beginning.
    """
    date = None
    i = 24
    if len(start) >= i:
        try:
            date = time.strptime(start[4:i], "%b %d %H:%M:%S %Y")
        except:
            pass

    if date == None:
        try:
            i = 10
            date = time.strptime(start[:i], "%Y-%m-%d")
        except:
            i = 12
            if len(start) >= i:
                try:
                    date = time.strptime(start[:i], "%b %d, %Y")
                except:
                    i = 13
                    if len(start) >= i:
                        try:
                            date = time.strptime(start[:i], "%b %d,  %Y")
                        except:
                            i = 15
                            if len(start) >= i:
                                try:
                                    date = time.strptime(start[5:i], "%b %d  %Y")
                                except:
                                    i = 16
                                    if len(start) >= i:
                                        try:
                                            date = time.strptime(start[:i], "%a %b %d  %Y")
                                        except:
                                            i = 23
                                            if len(start) >= i:
                                                try:
                                                    date = time.strptime(start[3:i], "%b %d %H:%M:%S %Y")
                                                except:
                                                    i = 24
                                                    if len(start) >= i:
                                                        try:
                                                            date = time.strptime(start[4:i], "%d %b %Y %H:%M:%S")
                                                        except:
                                                            i = 25
                                                            if len(start) >= i:
                                                                try:
                                                                    date = time.strptime(start[4:i], "%b  %d %H:%M:%S %Y")
                                                                except:
                                                                    try:
                                                                        date = time.strptime(start[4:i], "%B %d %H:%M:%S %Y")
                                                                    except:
                                                                        i = 28
                                                                        if len(start) >= i:
                                                                            try:
                                                                                date = time.strptime(start[4:i], "%b %d %H:%M:%S %Z %Y")
                                                                            except:
                                                                                try:
                                                                                    date = time.strptime(start[4:20] + start[24:i], "%b %d %H:%M:%S %Y")
                                                                                except:
                                                                                    i = 29
                                                                                    if len(start) >= i:
                                                                                        try:
                                                                                            date = time.strptime(start[4:20] + start[25:i], "%b %d %H:%M:%S %Y")
                                                                                        except:
                                                                                            try:
                                                                                                date = time.strptime(start[4:20] + start[24:i], "%b %d %H:%M:%S %Y")
                                                                                            except:
                                                                                                i = 30
                                                                                                if len(start) >= i:
                                                                                                    try:
                                                                                                        date = time.strptime(start[:i], "%a %b %d %H:%M:%S %Z %Y")
                                                                                                    except:
                                                                                                        pass
    return date, i

def isEntryStart(start):
    date, i = getDateFromEntryStart(start)
    return date != None

def getStructuredInfoFromEntryStart(start):
    """Returns a dictionary consisting of date and author. The date
    is actually a date tuple"""
    info = {}
    date, i = getDateFromEntryStart(start)
    if date == None:
        raise "FIXME!! Failed to parse date from line: %s" % start

    info["date"] = date
    if len(start) > i:
        info["author"] = start[i:].strip()
    else:
        info["author"] = "unknown"
    return info

def appendStructuredLogMessagesToLogs(rawLogMessage, logs):
    """
    """
    entries = [None, None]
    i = rawLogMessage.find(":")
    if i != -1:
        entries[0] = rawLogMessage[:i]
        entries[1] = rawLogMessage[i+1:].lstrip()
    else:
        entries[1] = rawLogMessage
    logs.append(entries)

def compareDateStructs(a, b):
    """
     1 -> a < b
     0 -> a == b
    -1 -> a > b
    
    Note: For our comparison we just consider year, month and day.
    """
    # tuples:
    # t[0] -> %Y
    # t[1] -> %m
    # t[2] -> %d    
    format = "%04d%02d%02d"
    aDate = format % (a[0], a[1], a[2])
    bDate = format % (b[0], b[1], b[2])
    aNumber = int(aDate)
    bNumber = int(bDate)
    if aNumber < bNumber:
        return 1
    elif aNumber == bNumber:
        return 0
    else:
        return -1

def compareStructuredEntries(a, b):
    aDate = a["date"]
    bDate = b["date"]
    return compareDateStructs(aDate, bDate)


##
##  EXTERNAL API
##


def annotateStructuredEntries(entries, annotations):
    for e in entries:
        e.update(annotations)
    return

def structuredEntriesFromChangeLogFile(filename, datematch=None):
    """Wrapper for the structuredEntriesFromChangeLog() function"""
    f = open(filename, "r");
    data = f.read()
    f.close()
#    print "DEBUG: Parsing: %s" % filename
    return structuredEntriesFromChangeLog(data, datematch)

def structuredEntriesFromChangeLog(rawChangeLog, datematch=None):
    """
    Returns an array of dictionaries.
    Note that the entries in the top-level array are pre-sorted by date (descending).

    [
        {
            "date" : (<date tuple>),
            "author" : "<authorname, email>",
            "logs" :
                [
                    [ "Files etc. or None if none provided", "Comment" ],
                    ...
                ]
        },
        ...
    ] 
    """
    entries = []
    currentLog = ""
    lines = rawChangeLog.split("\n")
    for line in lines:
        if len(line) > 0 and not (line[:1].isspace() or line[:1] == "*" or line[:1] == "-") and isEntryStart(line):
            # entry start
            if len(currentLog) > 0:
                appendStructuredLogMessagesToLogs(currentLog, logs)
            info = getStructuredInfoFromEntryStart(line)
            logs = []
            info["logs"] = logs
            currentLog = ""
            
            # only add to entries if no datematch or datematch not positive
            if datematch:
                dateexp = time.strftime("%Y%m%d", info["date"])
                if re.match(datematch, dateexp):
                    entries.append(info)
            else:
                entries.append(info)
        else:
            # strip leading whitespace and "*" from line
            strippedLine = line.lstrip()
            if not len(strippedLine) == 0:
                if strippedLine.startswith("*"):
                    # this indicates the next logs entry
                    if len(currentLog) > 0:
                        appendStructuredLogMessagesToLogs(currentLog, logs)
                        currentLog = ""
                    strippedLine = strippedLine[1:]
                    strippedLine = strippedLine.lstrip()
                if len(currentLog) > 0:
                    if not currentLog[-1].isspace():
                        currentLog += " "
                currentLog += strippedLine

    if len(currentLog) > 0:
        appendStructuredLogMessagesToLogs(currentLog, logs)

    return entries

def sortedStructuredEntriesByMergingStructuredEntries(a, b):
    """
    Note: sorted by date descending
    Note2: a has higher precedence than b
    """
    aIndex = 0
    bIndex = 0
    aCount = len(a)
    bCount = len(b)

    dst = []
    dstCount = aCount + bCount

    if aIndex < aCount:
        currentA = a[aIndex]
    else:
        currentA = None

    if bIndex < bCount:
        currentB = b[bIndex]
    else:
        currentB = None

    while dstCount > 0:
        if currentA != None and currentB != None:
            if compareStructuredEntries(currentA, currentB) <= 0:
                choseA = 1
            else:
                choseA = 0
        elif currentA != None and currentB == None:
            choseA = 1
        elif currentA == None and currentB != None:
            choseA = 0
        else:
            print "!! SHOULDN'T HAPPEN, dstCount == " + str(dstCount)

        if choseA:
            dst.append(currentA)
            aIndex += 1
            if aIndex < aCount:
                currentA = a[aIndex]
            else:
                currentA = None
        else:
            dst.append(currentB)
            bIndex += 1
            if bIndex < bCount:
                currentB = b[bIndex]
            else:
                currentB = None

        dstCount -= 1

    return dst


def mergedEntriesFromAnnotatedEntries(annotatedEntries, limit=0):
    """
    Returns this:

    [
        {
            "date" : (<date tuple>),
            "entries" :
            [
                {
                    "author" : "<author>"
                    "project" : "<project name">,
                    "logs" :
                    [
                        [
                            "<file names and stuff or None>", "Comments"
                        ], ...
                    ]
                }, ...
            ]
        }, ...
    ] 
    """
    
    if len(annotatedEntries) == 0:
        return []

    currentEntry = annotatedEntries[0]
    currentEntries = [currentEntry]
    dst = [{ "date" : currentEntry["date"], "entries" : currentEntries }]

    for e in annotatedEntries[1:]:
        result = compareStructuredEntries(currentEntry, e)
        if result == 0:
            # merge in
            currentEntries.append(e)
        else:
            # create new entry
            currentEntry = e
            currentEntries = [currentEntry]
            dst.append({ "date" : currentEntry["date"], "entries" : currentEntries })

        # bail out if limit set and limit reached
        if limit != 0 and len(dst) == limit:
            return dst

    return dst


##
##  HIGH LEVEL EXTERNAL API
##


def getMergedEntriesFromConfig(config, datematch = None, limit = 0):
    """
    Expects this:
    
    config    - config dictionary, usually the CONFIG entry in config.py
    datematch - regular expression for the date entry. If this matches, entry
                will be contained in in result, otherwise not.

    limit     - if 0, no limit. Otherwise, number of toplevel results will be
                limited to this number.

    Returns this:

    [
        {
            "date" : (<date tuple>),
            "entries" :
            [
                {
                    "author" : "<author>"
                    "project" : "<project name">,
                    "logs" :
                    [
                        [
                            "<file names and stuff or None>", "Comments"
                        ], ...
                    ]
                }, ...
            ]
        }, ...
    ] 
    """

    basedir = config["basedir"]
    logDescriptions = config["logs"]
    
    annotatedEntries = []
    
    for logDescription in logDescriptions:
        # XXX: append path bla?
        filename = basedir + "/" + logDescription["log"]
       
        entries = structuredEntriesFromChangeLogFile(filename, datematch)
        annotateStructuredEntries(entries, logDescription)
        annotatedEntries = sortedStructuredEntriesByMergingStructuredEntries(annotatedEntries, entries)
    
    mergedEntries = mergedEntriesFromAnnotatedEntries(annotatedEntries, limit)
    return mergedEntries


##
##  MAIN
##


if __name__ == '__main__':
    try:
        filename = sys.argv[1]
    #	print "filename: %s" % (filename)
        entries = structuredEntriesFromChangeLogFile(filename)
        
        for entry in entries:
            date = time.strftime("%Y-%m-%d", entry["date"])
            print "%s by %s" % (date, entry["author"])
            for log in entry["logs"]:
                if log[0] == None:
                    print "- %s" % log[1]
                else:
                    print "- %s:" % log[0]
                    print "  %s" % log[1]
            print
    
    except IndexError:
        sys.stderr.write("Usage: changelogparser.py <filename>\n")
        sys.exit(1)
    
    except IOError:
        sys.stderr.write("%s\n" % (sys.exc_value))
        sys.exit(1)
    
    except:
        sys.stderr.write("Unexpected error %s:%s\n" % (sys.exc_type, sys.exc_value))
        sys.exit(1)
