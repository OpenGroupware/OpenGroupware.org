#!/usr/bin/env python

import LSOffice
import EOControl
from Foundation import *

lso = LSOffice.LSOffice(user='helge', password='helgehelge')

me    = lso.run1("account::get-by-login", login='helge')
team  = lso.runMany("team::get", description="all intranet")[0]

print team
teamgid = team.valueForKey('globalID')
print teamgid

members = lso.run("team::members",
                  group=teamgid,
                  fetchGlobalIDs=YES,
                  returnSet=YES)

print "%i gids" % len(members)
#print members

accounts = lso.run("person::get-by-globalid",
                   gids=members,
                   attributes=("login", "companyId"))
for account in accounts:
    login = account['login']
    if login[:1] == "h":
        print login, "-", account['companyId']

#---- multi-search

members = lso.run("team::members",
                  group=teamgid,
                  fetchGlobalIDs=YES,
                  returnSet=YES)

#teams = lso.run("account::teams", accounts=members, fetchGlobalIDs=YES)
#print "Teams:", teams

#----- get-by-globalID

print "Team1 is", teamgid

teams = lso.run("team::get-by-globalid",
                gids=(teamgid,),
                attributes=("description","isTeam","globalID"))
print "Teams:", teams

