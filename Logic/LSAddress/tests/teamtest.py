#!/usr/bin/env python

import LSOffice
import EOControl
from Foundation import *

lso = LSOffice.LSOffice(user='helge', password='helgehelge')

me    = lso.run1("account::get", login='helge')
team  = lso.runMany("team::get", description="dev")[0]
teams = lso.runMany("team::get")

print team
members = lso.run("team::members", object=team, returnSet=YES)
print "%i members" % len(members)

members = lso.run("team::expand", object=(team,), returnSet=YES)
print "%i members" % len(members)
members = lso.run("team::expand", object=(team,), returnSet=YES)
print "%i members" % len(members)
members = lso.run("team::expand", object=(team,), returnSet=YES)
print "%i members" % len(members)
members = lso.run("team::expand", object=(team,me,), returnSet=YES)
print "%i members" % len(members)
members = lso.run("team::expand", object=(team,me,), returnSet=YES)
print "%i members" % len(members)

members = lso.run("team::members", object=team, returnSet=YES)
print "%i members" % len(members)

print "%i teams" % len(teams)
members = lso.run("team::expand", object=teams, returnSet=YES)
print "%i members" % len(members)
members = lso.run("team::expand", object=teams, returnSet=YES)
print "%i members" % len(members)
members = lso.run("team::expand", object=teams, returnSet=YES)
print "%i members" % len(members)
