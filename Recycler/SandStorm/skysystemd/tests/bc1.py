#!/usr/bin/env python

import xmlrpclib

url   = "http://localhost:20000/test1.woa/wa/RPC2"
login = "test"
pwd   = "test"

# call server

server = xmlrpclib.Server(url, login=login, password=pwd)
system = server.com.skyrix.system

print "result of 1+2   is", system.bc("1+2") 
print "result of 3,2   is", system.bc("3","2")
print "result of 3,2,* is", system.bc("3","2","*")
