#!/usr/bin/env python

import xmlrpclib

url   = "http://localhost:20000/test1.woa/wa/RPC2"
login = "test"
pwd   = "test"

# call server

server = xmlrpclib.Server(url, login=login, password=pwd)
system = server.com.skyrix.system

res = system.ls("/tmp/")
print "%i files:" % len(res)
for r in res:
  print "  file: %s" % r

