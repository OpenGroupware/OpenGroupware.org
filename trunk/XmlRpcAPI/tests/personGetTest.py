#!/usr/bin/env python
import xmlrpclib

HOST="localhost"
LOGIN="root"
PWD=""

URL = "http://%s:%s@%s/RPC2" % LOGIN, PWD, HOST

server = xmlrpclib.ServerProxy(URL)

# Note: this doesn't seem to be implemented in xmlrpcd
result=server.person.get( { "name": "Duck", } )
print "got:", result
