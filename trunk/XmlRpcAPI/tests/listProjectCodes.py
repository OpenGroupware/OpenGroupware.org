#!/usr/bin/env python

import xmlrpclib, time, sys, getpass

HOST="localhost"
LOGIN="helge"

p = "Enter password for user %s: " % ( LOGIN,)
PWD = getpass.getpass(p)

#URL="http://%s:%s@%s:80/RPC2" % ( LOGIN, PWD, HOST )
URL="http://%s:80/RPC2" % ( HOST, )

try:
    server = xmlrpclib.Server(URL, login=LOGIN, password=PWD)
except TypeError, e:
    print "Catched:", e, "\n"
    print "Likely reason: you didn't install a basic-auth enabled XML-RPC"
    print "client library!"
    sys.exit(1)
print "Server:", server

projects = server.project.fetch()
for project in projects:
    print project['number']

