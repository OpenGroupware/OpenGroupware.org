#!/usr/bin/env python

import LSOffice
import EOControl
from Foundation import *

lso = LSOffice.LSOffice(user='helge', password='helgehelge')

me    = lso.run1("account::get-by-login", login='helge')
team  = lso.runMany("team::get", description="dev")[0]
team2 = lso.runMany("team::get", description="Buchhaltung")[0]
teams = lso.runMany("team::get")

print team
teamgid = team.valueForKey('globalID')
team2gid = team2.valueForKey('globalID')
print teamgid, team2gid

#----- get-by-globalID

print "Team1 is", teamgid, "Team2 is", team2gid

attrs = (
    "description",
    "isTeam",
    "globalID",
    "members.login",
    "members.globalID"
)

teams = lso.run("team::get-by-globalid",
                gids=(teamgid,team2gid),
                attributes=attrs)
print "Teams:", teams
