#!/usr/bin/env python

import xmlrpclib, time, sys

LOGIN="helge"
PWD=""
URL="http://%s:%s@localhost/RPC2" % ( LOGIN, PWD )
PCODE="hhtest1"
TARGETPATH="/bindoc.tst"

try:
    server = xmlrpclib.Server(URL, login=LOGIN, password=PWD)
except TypeError, e:
    server = xmlrpclib.Server(URL)
#    print "Catched:", e, "\n"
#    print "Likely reason: you didn't install a basic-auth enabled XML-RPC"
#    print "client library!"
#    sys.exit(1)
print "Server:", server

content = "blah blub"

print "Attempt to save document in project", PCODE

try:
    result = server.project.saveDocument(PCODE, TARGETPATH, content)
except xmlrpclib.Fault, ex:
    print "FAULT: %i: %s" % ( ex.faultCode, ex.faultString )
