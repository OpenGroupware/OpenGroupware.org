#!/usr/bin/env python

import LSOffice
import EOControl
from Foundation import *

lso = LSOffice.LSOffice(user='helge', password='helgehelge')

me      = lso.run1("account::get-by-login", login='helge')
devteam = lso.run1("team::get", description="dev")
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

attrs = ("title","startDate","endDate","globalID")
print "resolve attributes", attrs, ".."

apts = lso.run("appointment::get-by-globalid",
               gids=dates,
               timeZoneName="MET",
               attributes=attrs)
for apt in apts:
    print "%(startDate)-20s - %(endDate)-20s: '%(title)s'" % apt

# retrieve participant gids

pgids = lso.run("appointment::get-participants",
                appointments=dates,
                fetchGlobalIDs=1)

# sort participant gids by entity

persons = []
teams   = []
for agid, pgida in pgids.items():
    for pgid in pgida:
        if (pgid not in persons) & (pgid not in teams):
            if pgid.entityName() == "Person":
                persons.append(pgid)
            else:
                teams.append(pgid)

# fetch participant attributes

teams = lso.run("team::get-by-globalid",
                gids=teams,
                groupBy="globalID",
                attributes=("description","companyId","globalID"))
persons = lso.run("person::get-by-globalid",
                  gids=persons,
                  groupBy="globalID",
                  attributes=("name","firstname","companyId","globalID"))

# assign attributes to appointments

for apt in apts:
    print "%(startDate)-20s - %(endDate)-20s: '%(title)s'" % apt
    pgida = pgids[apt['globalID']]
    for pgid in pgida:
        try:
            team = teams[pgid]
            if team is not None:
                print "  team:  ", team['description']
        except: pass
        try:
            person = persons[pgid]
            if person is not None:
                print "  person: %(firstname)s %(name)s" % person
        except: pass
