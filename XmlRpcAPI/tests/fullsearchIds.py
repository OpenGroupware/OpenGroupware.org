#!/usr/bin/python

import xmlrpclib, time, sys

URL='http://localhost:9000/RPC2'
LOGIN="helge"
PWD=""

try:
    server = xmlrpclib.Server(URL, login=LOGIN, password=PWD)
except TypeError, e:
    print "Catched:", e, "\n"
    print "Likely reason: you didn't install a basic-auth enabled XML-RPC"
    print "client library!"
    sys.exit(1)
print "Server:", server

print "Result:", server.person.fullsearchIds("helge")
print "Result:", server.person.fullsearchIds(('helge','hess',));

