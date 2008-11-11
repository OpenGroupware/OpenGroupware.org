#!/usr/bin/env python
# ZNeK - 20031012

"""
HTML ChangeLog aggregation.
"""

__version__ = "@()$Id: clhtml_month.py,v 1.3 2003/10/20 15:42:14 znek Exp $"

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


HTML="""<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>%(project)s progress</title>
<link rel="stylesheet" href="ogocl.css" type="text/css" />
<link rel="alternate" type="application/rss+xml" title="RSS" href="ogocl.rss" />
</head>

<body>

<div id="banner">
<table cellpadding="0" cellspacing="0" border="0" width="100%%">
<tr height="50">
	<td style="background: #FFF; border-bottom: 1px solid #000" align="left">
		<a href="http://www.opengroupware.org/"><img src="http://www.opengroupware.org/images/headline_logo2.gif" alt="%(project)s" border="0" /></a>
	</td>
	<td rowspan="2" width="270">&nbsp;<br /></td>
</tr>
<tr>
	<td align="left"><span class="description">Project ChangeLogs in BLog style. Progress at your fingertips.&trade; ;-)</span></td>
</tr>
</table>
</div>

<table cellpadding="0" cellspacing="0" border="0" width="100%%">
<tr valign="top">
<td>
<div id="content">
%(content)s
</div>
</td>
<td width="220">
<div id="sidebox">
<div class="sideboxtitle">%(monthName)s&nbsp;%(year)s</div>
<div align="center" class="calendar">
<div align="center">
<table border="0" cellspacing="4" cellpadding="0">
<tr>
<th abbr="Sunday" align="center"><span class="calendar">Sun</span></th>
<th abbr="Monday" align="center"><span class="calendar">Mon</span></th>
<th abbr="Tuesday" align="center"><span class="calendar">Tue</span></th>
<th abbr="Wednesday" align="center"><span class="calendar">Wed</span></th>
<th abbr="Thursday" align="center"><span class="calendar">Thu</span></th>
<th abbr="Friday" align="center"><span class="calendar">Fri</span></th>
<th abbr="Saturday" align="center"><span class="calendar">Sat</span></th>
</tr>
%(calendar)s
</table>
</div>
</div>

<div class="sideboxtitle">Archives</div>
<div class="sidebody">
%(archives)s
</div>

<br clear="all" />
</td></tr></table>

<div class="footer">
CSS used from <a href="http://coreblog.org/">COREBlog</a> with kind permission of Atsushi Shibata <a href="mailto:shibata@webcore.co.jp">&lt;shibata@webcore.co.jp&gt;</a>.
</div>

</body>
</html>"""

DATE_ENTRY="""<div id="content">
<!-- date -->
<div class="date"><span class="day">%(day)s </span>%(monthName)s<br />%(year)s</div>
<!-- entry -->
<div class="entry">
<a name="%(year)s%(month)s%(day)s"></a>
%(logEntry)s
</div>
</div>
"""

LOG_ENTRY_HEADER="""
<h1 class="title"><a style="text-decoration: none" href="%(viewcvs)s%(subProjectPath)s/ChangeLog">%(subProject)s</a></h1>
<div class="subtitle">%(subProjectPath)s</div>
<!-- <div class="category">[%(subProject)s]</div> -->
<p>
<ul>
%(logEntries)s
</ul>
</p>
<br clear="all" />
<div class="posted">Committed by <a href="mailto:%(mailto)s"><b>%(quotedAuthor)s</b></a></div>
"""

SINGLE_LOG_ENTRY="""
<li /><div class="entryComment">%(comment)s</div>
"""

DUAL_LOG_ENTRY="""
<li /><span class="entryPreamble">%(preamble)s</span>:<br />
<div class="entryComment">%(comment)s</div>
"""

EMPTY_CALENDAR_ENTRY="""<td align="center"><span class="calendar">&nbsp;</span></td>"""

REF_CALENDAR_ENTRY="""<td align="center"><span class="calendar"><a href="#%(year)04d%(month)02d%(day)02d">%(day)d</a></span></td>"""

NOREF_CALENDAR_ENTRY="""<td align="center"><span class="calendar">%(day)d</span></td>"""

ARCHIVE_ENTRY="""<a href="%(pageName)s.html">%(monthName)s&nbsp;%(year)s</a><br />"""


##
##  MAIN
##


if __name__ == '__main__':
    try:
        limit = 0 # no entry limit

        if len(sys.argv) != 3:
            raise IndexError("Foo")
        
        year = sys.argv[1]
        month = sys.argv[2]
        datematch = year + month + ".."

        CONFIG["monthName"] = time.strftime("%B", (int(year), int(month), 1, 0, 0, 0, 0, 0, 0))
        CONFIG["month"] = month
        CONFIG["year"] = year
        CONFIG["archiveName"] = year + month + ".html"

        content = ""

        mergedEntries = getMergedEntriesFromConfig(CONFIG, datematch, limit)

        for mergedEntry in mergedEntries:
            dateStruct = mergedEntry["date"]

            entryDict = {}
            entryDict["day"] = time.strftime("%d", dateStruct)
            entryDict["month"] = time.strftime("%m", dateStruct)
            entryDict["monthName"] = time.strftime("%B", dateStruct)
            entryDict["year"] = time.strftime("%Y", dateStruct)

            logEntry = ""
            for entry in mergedEntry["entries"]:
                author = entry["author"]
                # replace author if we have a configuration for that purpose
                if EMAIL.has_key(author):
                    author = EMAIL[author]
                mailto = "%s?Subject=%s" % (author, urllib.quote("Re: " + CONFIG["project"] + "'s " + entry["path"] + " ChangeLog entry (" + time.strftime("%Y-%m-%d", dateStruct) + ")"))

                logEntryDict = {}
                logEntryDict["subProject"] = htmlQuotedString(entry["project"])
                logEntryDict["author"] = author
                logEntryDict["quotedAuthor"] = htmlQuotedString(author)
                logEntryDict["subProjectPath"] = entry["path"]
                logEntryDict["viewcvs"] = CONFIG["viewcvs"]
                logEntryDict["mailto"] = mailto

                logEntries = ""
                for log in entry["logs"]:
                    logEntryDict["comment"] = htmlQuotedString(log[1])
                    if log[0] == None:
                        if logEntryDict.has_key("preamble"):
                            del logEntryDict["preamble"]
                        logEntries += SINGLE_LOG_ENTRY % logEntryDict
                    else:
                        logEntryDict["preamble"] = htmlQuotedString(log[0])
                        logEntries += DUAL_LOG_ENTRY % logEntryDict

                logEntryDict["logEntries"] = logEntries
                logEntry += LOG_ENTRY_HEADER % logEntryDict

            entryDict["logEntry"] = logEntry
            dateEntry = DATE_ENTRY % entryDict
            
            content += dateEntry

        htmlDict = {}
        htmlDict.update(CONFIG)
        htmlDict["project"] = htmlQuotedString(CONFIG["project"])
        htmlDict["content"] = content


        # construct this month's calendar
        cal = ""
        calDict = {}
        calDict["year"] = int(CONFIG["year"])
        calDict["month"] = int(CONFIG["month"])

        indexDays = INDEX[CONFIG["year"]][CONFIG["month"]]

        calendar.setfirstweekday(6) # Sunday
        daymatrix = calendar.monthcalendar(calDict["year"], calDict["month"])
        for row in daymatrix:
            cal += "<tr>"
            for day in row:
                if day == 0:
                    cal += EMPTY_CALENDAR_ENTRY % calDict
                else:
                    calDict["day"] = day
                    if "%02d" % day in indexDays:
                        cal += REF_CALENDAR_ENTRY % calDict
                    else:
                        cal += NOREF_CALENDAR_ENTRY % calDict
            cal += "</tr>"

        htmlDict["calendar"] = cal

        # construct the archives overview
        archives = ""
        archiveDict = {}
#        archiveDict["webArchivePath"] = CONFIG["webArchivePath"]

        years = INDEX.keys()
        years.sort(sortDescending)
        

        for year in years:
            months = INDEX[year].keys()
            months.sort(sortDescending)
            for month in months:
                datestamp = year + month
                archiveDict["year"] = year
                archiveDict["monthName"] = time.strftime("%B", (int(year), int(month), 1, 0, 0, 0, 0, 0, 0))
                archiveDict["pageName"] = datestamp
                archives += ARCHIVE_ENTRY % archiveDict
 
        htmlDict["archives"] = archives


        html = HTML % htmlDict
        f = open(fullFSPathForArchiveNamed(CONFIG, CONFIG["archiveName"]), "w")
        f.write(html)
        f.close()
    
    except IndexError:
        sys.stderr.write("Usage: clhtml.py year month\nyear: 4 digit number\nmonth: 2 digit number\n")
        sys.exit(1)
    
    except IOError:
        sys.stderr.write("%s\n" % (sys.exc_value))
        sys.exit(1)
    
#    except:
#        sys.stderr.write("Unexpected error %s:%s\n" % (sys.exc_type, sys.exc_value))
#        sys.exit(1)
