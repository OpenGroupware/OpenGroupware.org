#!/usr/bin/env python

import LSOffice
import EOControl
from Foundation import *

lso = LSOffice.LSOffice(user='j', password='')

me      = lso.run1("account::get-by-login", login='j')
devteam = lso.run1("team::get", description="dev", returnType=2)
    

allteam = lso.run1("team::get", description="all intranet")
monday  = NSCalendarDate().invoke0('mondayOfWeek')
tz      = monday.timeZone()
print monday

print "query range for all -----------"
dates  = lso.run("appointment::query",
                 fromDate=monday,
                 toDate=monday.dateByAdding(days=7))
print "week:", dates


print "query range for me -----------"
dates  = lso.run("appointment::query",
                 fromDate=monday,
                 toDate=monday.dateByAdding(days=7),
                 companies=(me.valueForKey("globalID"),))
print "week:", dates


print "query range for me&dev -----------"
dates  = lso.run("appointment::query",
                 fromDate=monday,
                 toDate=monday.dateByAdding(days=7),
                 companies=(me.valueForKey("globalID"),
                            devteam.valueForKey("globalID")))
print "week:", dates


print "query range for me&dev&all -----------"
dates  = lso.run("appointment::query",
                 fromDate=monday,
                 toDate=monday.dateByAdding(days=7),
                 companies=(me.valueForKey("globalID"),
                            devteam.valueForKey("globalID"),
                            allteam.valueForKey("globalID")))
print "week %i:" % len(dates),
print dates

print "fetch last range --------------"

sortOrdering = EOControl.EOSortOrdering("startDate", 'compareAscending:')

apts  = lso.run("appointment::get-by-globalid",
                 gids=dates,
                 sortOrdering=sortOrdering,
                 timeZoneName="CET")

print "week %i:" % len(apts)
for date in apts:
    print "   %(title)-20s %(startDate)s" % date

sortOrdering = EOControl.EOSortOrdering("startDate", 'compareAscending:')

apts  = lso.run("appointment::get-by-globalid",
                 gids=dates,
                 sortOrdering=sortOrdering,
                 timeZoneName="PDT")

print "week %i:" % len(apts)
for date in apts:
    print "   %(title)-20s %(startDate)s" % date

print "query for resources ---------"

dates = lso.run("appointment::query",
                 fromDate=monday,
                 toDate=monday.dateByAdding(days=7),
                 companies=(me.valueForKey("globalID"),));
print "dates for me without Transporter: ", dates

dates  = lso.run("appointment::query",
                 fromDate=monday,
                 toDate=monday.dateByAdding(days=7),
                 companies=(me.valueForKey("globalID"),),
                 resourceNames=("Transporter",));
print "****************"
print "dates for me with Transporter: ", dates


