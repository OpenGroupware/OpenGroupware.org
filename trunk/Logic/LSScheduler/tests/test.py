#!/usr/bin/env python

import LSOffice
import EOControl
from Foundation import *

lso = LSOffice.LSOffice(user='helge', password='helgehelge')

me     = lso.run1("account::get-by-login", login='helge')
monday = NSCalendarDate().invoke0('mondayOfWeek')
tz     = monday.timeZone()
print monday

#dates = lso.run("appointment::get-appointments")
dates  = lso.run("appointment::weekdates",
                 monday=monday,
                 fetchParticipants=YES,
                 withoutPrivate=NO,
                 timeZone=tz,
                 company=me)
print dates
if dates is None:
    dates = ()

ndates = []
for date in dates:
    if len(str(date['type'])) == 0:
        if date['title'] == "blahblah":
            ndates.append(date)

date = ndates[0]

#print date

ps = lso.run("appointment::get-participants", date=date, fetchGlobalIDs="YES")

for participantId in ps:
    entity = participantId.entityName()
    
    if "Team" == entity:
        print "Team to resolve", participantId
        members = lso.run("team::members",
                          object=participantId,
                          fetchGlobalIDs=YES)
        for p in members:
            print "  participant", p
    else:
        print "participant:", participantId

print "resolved participants:"
ps = lso.run("team::expand", object=ps, fetchGlobalIDs=YES)
for pid in ps:
    print "  ", pid

