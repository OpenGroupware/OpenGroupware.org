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

members = lso.run("team::members",
                  group=teamgid,
                  fetchGlobalIDs=YES,
                  returnSet=YES)

print "%i gids" % len(members)
print members

members = lso.run("team::members",
                  groups=( teamgid, team2gid, ),
                  fetchGlobalIDs=YES,
                  returnSet=YES)

print "%i gids" % len(members)
print members

teams = lso.run("account::teams",
                object=me.valueForKey('globalID'),
                fetchGlobalIDs=YES)
print "Teams:", teams

#---- multi-search

members = lso.run("team::members",
                  group=teamgid,
                  fetchGlobalIDs=YES,
                  returnSet=YES)

teams = lso.run("account::teams", accounts=members, fetchGlobalIDs=YES)
print "Teams:", teams

#----- get-by-globalID

print "Team1 is", teamgid, "Team2 is", team2gid

teams = lso.run("team::get-by-globalid",
                gids=(teamgid,team2gid),
                attributes=("description","isTeam","globalID"))
print "Teams:", teams

#----- extended team search

teams = lso.run("team::get-all", fetchGlobalIDs=1)
print "teams:", teams

#----- staff::get-by-globalID

print "Team1 is", teamgid, "Team2 is", team2gid

teams = lso.run("staff::get-by-globalid",
                gids=(teamgid,team2gid,me.valueForKey('globalID')),
                attributes=("description","isTeam","globalID","name"))
print "Teams:", teams
