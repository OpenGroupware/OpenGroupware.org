#!/usr/bin/env python
# ZNeK - 20031012

"""
Creates the index suitable for archive creation.
"""

__version__ = "@()$Id: clindexer.py,v 1.1.1.1 2003/10/16 11:02:34 znek Exp $"

import sys
import time
from changelogparser import *
from config import CONFIG


FILE = """##
##  INDEX
##

INDEX = %s
"""

DATE_LUT = {}


##
##  HELPER
##

def rememberDate(date):
    yearKey = "%04d" % date[0]
    monthKey = "%02d" % date[1]
    dayKey = "%02d" % date[2]

    if DATE_LUT.has_key(yearKey):
        monthLUT = DATE_LUT[yearKey]
    else:
        monthLUT = {}
        DATE_LUT[yearKey] = monthLUT

    if monthLUT.has_key(monthKey):
        dayLUT = monthLUT[monthKey]
    else:
        dayLUT = []
        monthLUT[monthKey] = dayLUT

    if dayKey not in dayLUT:
        dayLUT.append(dayKey)


##
##  MAIN
##


if __name__ == '__main__':
    try:
        datematch = None
        limit = 0

        basedir = CONFIG["basedir"]
        logDescriptions = CONFIG["logs"]

        annotatedEntries = []

        for logDescription in logDescriptions:
            # XXX: append path bla?
            filename = basedir + "/" + logDescription["log"]
    	   
            entries = structuredEntriesFromChangeLogFile(filename, datematch)
            annotateStructuredEntries(entries, logDescription)
            annotatedEntries = sortedStructuredEntriesByMergingStructuredEntries(annotatedEntries, entries)
        
        mergedEntries = mergedEntriesFromAnnotatedEntries(annotatedEntries, limit)

        for mergedEntry in mergedEntries:
#            print time.strftime("%Y-%m-%d", mergedEntry["date"])
            rememberDate(mergedEntry["date"])

        print FILE % DATE_LUT

    except IndexError:
        sys.stderr.write("Usage: clindexer.py\n")
        sys.exit(1)
    
    except IOError:
        sys.stderr.write("%s\n" % (sys.exc_value))
        sys.exit(1)
    
    except:
        sys.stderr.write("Unexpected error %s:%s\n" % (sys.exc_type, sys.exc_value))
        sys.exit(1)
