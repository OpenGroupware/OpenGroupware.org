#!/usr/bin/env python

import LSOffice
import EOControl
from Foundation import *

lso = LSOffice.LSOffice(user='helge', password='')

#me    = lso.run1("account::get-by-login", login='helge')
#team  = lso.runMany("team::get", description="dev")[0]

print "--------------------"
print "Run query for 'helg' .."

query = "helg"
persons = lso.run("person::extended-search",
                  operator="OR",
                  name=query,
                  firstname=query,
                  description=query,
                  login=query,
                  fetchGlobalIDs=1,
                  maxSearchCount=20)
print "%i persons matched" % len(persons)
for p in tuple(persons):
    print "  person:", p

print "--------------------"
print "Fetch some attributes .."
attrs = lso.run("person::get-by-globalid",
                gids=persons,
                attributes=("login", "name", "firstname"))
for p in tuple(attrs):
    print "  person:", p

print "--------------------"
print "Resolve to EOs .."
eos = lso.run("person::get-by-globalid", gids=persons)
for p in tuple(eos):
    print "  person: '%(login)s' '%(name)s'" % p

print "--------------------"
print "Run query for 'helg' .."

query = "helg"
persons = lso.run("person::extended-search",
                  operator="OR",
                  name=query,
                  firstname=query,
                  description=query,
                  login=query,
                  maxSearchCount=20)
print "%i persons matched" % len(persons)

lso.rollback()
