#!/usr/bin/env python

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

startDate = time.strptime( '2002-01-02' , '%Y-%m-%d' )
startDate = xmlrpclib.DateTime(time.mktime(startDate))
endDate   = time.strptime( '2002-01-02' , '%Y-%m-%d' )
endDate   = xmlrpclib.DateTime(time.mktime(endDate))

dict = {}
dict['name']      = "Project"
dict['startDate'] = startDate
dict['endDate']   = endDate

print "Attempt to create project:", dict

result = server.project.insert(dict)

print "Result:", result
