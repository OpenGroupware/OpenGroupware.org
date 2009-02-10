#!/usr/bin/env python
# ZNeK - 20031016

"""
RDF ChangeLog aggregation.
"""

__version__ = "@()$Id: clrdf.py,v 1.1 2003/10/20 15:24:54 znek Exp $"

import sys
import time
import urllib
import calendar
from changelogparser import *
from config import *
from index import INDEX


##
##  TEMPLATES
##


RDF="""<?xml version="1.0" encoding="iso-8859-1"?>

<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns="http://purl.org/rss/1.0/">

<channel rdf:about="http://www.opengroupware.org/">
<title>OGo: latest ChangeLog entries</title>
<link>http://www.opengroupware.org/</link>
<description>Latest OpenGroupware.org development ChangeLogs, keeping you up to date with its current development</description>
<dc:language>en-us</dc:language>
<dc:creator>ChangeBlogger clrdf.py</dc:creator>
<dc:date>%(dcCreationDate)s</dc:date>
<admin:generatorAgent rdf:resource="http://www.opengroupware.org/PyChangeLogAggregator/" />
<items>
<rdf:Seq>
%(seqURLs)s
</rdf:Seq>
</items>
</channel>

%(rdfEntries)s
</rdf:RDF>
"""

RDF_SEQ_RESOURCE="""<rdf:li rdf:resource="%(entryURL)s" />
"""

RDF_ENTRY="""
<item rdf:about="%(entryURL)s">
<title>%(title)s</title>
<link>%(entryURL)s</link>
<description>
%(description)s
</description>
<dc:subject>%(subProject)s</dc:subject>
<dc:creator>%(dcCreator)s</dc:creator>
<dc:date>%(dcDate)s</dc:date>
</item>
"""

RDF_LOG_ENTRIES="""<ul>
%(logEntries)s
</ul>"""

RDF_SINGLE_LOG_ENTRY="""<li />%(comment)s"""

RDF_DUAL_LOG_ENTRY="""<li />%(preamble)s:<br />%(comment)s"""


##
##  HELPERS
##


def getDCDate(dateStruct):
    dcDate = time.strftime("%Y-%m-%dT%H:%M:%S", dateStruct)
    dcDateTZ = time.strftime("%z", dateStruct)
    dcDateTZ = dcDateTZ[:3] + ":" + dcDateTZ[3:]
    return dcDate + dcDateTZ


def getDCCreator(author):
    return xmlQuotedString(author)


def urlForArchiveOfDate(dateStruct):

    year = "%04d" % dateStruct[0]
    month = "%02d" % dateStruct[1]
    day = "%02d" % dateStruct[2]
    archiveName = year + month + ".html"
    fragmentIdentifier = year + month +day
    path = CONFIG["webURL"] + "/" + CONFIG["webArchivePath"] + "/" + archiveName + "#" + fragmentIdentifier
    return path


##
##  MAIN
##


if __name__ == '__main__':
    try:
        ENTRY_LIMIT = 15

        limit = ENTRY_LIMIT # entry limit 15
        datematch = None

        mergedEntries = getMergedEntriesFromConfig(CONFIG, datematch, limit)

        seqURLs = ""
        rdfEntries = ""

        entryCount = 1
        for mergedEntry in mergedEntries:
            if entryCount <= ENTRY_LIMIT:

                dateStruct = mergedEntry["date"]
    
                entryDict = {}
                entryDict["dcDate"] = getDCDate(dateStruct)
                entryDict["entryURL"] = xmlQuotedString(urlForArchiveOfDate(dateStruct))

                for entry in mergedEntry["entries"]:
                    if entryCount <= ENTRY_LIMIT:
                        author = entry["author"]
                        # replace author if we have a configuration for that purpose
                        if EMAIL.has_key(author):
                            author = EMAIL[author]
        
                        title = entry["project"] + ": " + author
                        entryDict["title"] = xmlQuotedString(title)
                        entryDict["dcCreator"] = getDCCreator(author)
                        entryDict["subProject"] = xmlQuotedString(entry["project"])
                        entryDict["subProjectPath"] = xmlQuotedString(entry["path"])

                        seqURLs += RDF_SEQ_RESOURCE % entryDict

                        logEntries = ""
                        for log in entry["logs"]:
                                entryDict["comment"] = xmlQuotedString(log[1])
                                if log[0] == None:
                                    logEntry = RDF_SINGLE_LOG_ENTRY % entryDict
                                else:
                                    entryDict["preamble"] = xmlQuotedString(log[0])
                                    logEntry = RDF_DUAL_LOG_ENTRY % entryDict
            
                                logEntries += logEntry

                        entryDict["logEntries"] = logEntries
                        entryDict["description"] = xmlQuotedString(RDF_LOG_ENTRIES % entryDict)

                        rdfEntries += RDF_ENTRY % entryDict
            
                        entryCount += 1


        # construct resulting RDF
        rdfDict = {}
        rdfDict.update(CONFIG)
        rdfDict["project"] = xmlQuotedString(CONFIG["project"])
        rdfDict["dcCreationDate"] = getDCDate(time.localtime(time.time()))
        rdfDict["seqURLs"] = seqURLs
        rdfDict["rdfEntries"] = rdfEntries

        rdf = RDF % rdfDict
        print rdf
    
    except IndexError:
        sys.stderr.write("Usage: clrdf.py")
        sys.exit(1)
    
    except IOError:
        sys.stderr.write("%s\n" % (sys.exc_value))
        sys.exit(1)
    
#    except:
#        sys.stderr.write("Unexpected error %s:%s\n" % (sys.exc_type, sys.exc_value))
#        sys.exit(1)
