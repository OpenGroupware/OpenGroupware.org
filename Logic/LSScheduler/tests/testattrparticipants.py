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
#monday  = monday.invoke0('yesterday').invoke0('mondayOfWeek')
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

attrs = (
    "title",
    "startDate",
    "endDate",
    "globalID",
    "permissions",
    "participants.companyId",
    "participants.login",
    "participants.firstname",
    "participants.name",
    "participants.description",
    "participants.isTeam",
    "participants.isAccount"
)
print "resolve attributes", attrs, ".."

sortby = EOControl.EOSortOrdering("startDate", 'compareAscending:')
sortby = ( sortby, )
apts = lso.run("appointment::get-by-globalid",
               gids=dates,
               timeZoneName="CET",
               attributes=attrs,
               sortOrderings=sortby)
apts = lso.run("appointment::get-by-globalid",
               gids=dates,
               timeZoneName="CET",
               attributes=attrs,
               sortOrderings=sortby)
for apt in apts:
    print
    print "%(startDate)-20s - %(endDate)-20s: %(permissions)-5s '%(title)s'" % apt
    for p in apt['participants']:
        if p['isTeam'] is None:
            fmt = "  person: %(firstname)s %(name)s"
        else:
            fmt = "  team:   %(isTeam)s %(description)s"
        print fmt % p
