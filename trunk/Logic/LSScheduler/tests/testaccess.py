#!/usr/bin/env python

import LSOffice
import EOControl
from Foundation import *

null = EOControl.EONull()

lso = LSOffice.LSOffice(user='helge', password='helgehelge')

me      = lso.run1("account::get-by-login", login='helge')
devteam = lso.runMany("team::get", description="dev")[0]
allteam = lso.run1("team::get", description="all intranet")
monday  = NSCalendarDate().invoke0('mondayOfWeek')
tz      = monday.timeZone()
print monday

print "query range for me&dev&all -----------"
dates  = lso.run("appointment::query",
                 fromDate=monday,
                 toDate=monday.dateByAdding(days=7),
                 companies=(me.valueForKey("globalID"),
                            devteam.valueForKey("globalID"),
                            allteam.valueForKey("globalID")))
print "week %i:" % len(dates),
print dates

apts = lso.run("appointment::get-by-globalid",
               gids=dates,
               attributes=("title", "startDate", "globalID" ))

access = lso.run("appointment::access", gids=dates)
access = lso.run("appointment::access", gids=dates)

for apt in apts:
    print "  apt '%s': %s" % ( apt['title'], access[apt['globalID']] )
