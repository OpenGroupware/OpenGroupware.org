#!/usr/bin/env python

import xmlrpclib

url   = "http://localhost:20002/test1.woa/wa/RPC2"
login = "test"
pwd   = "test"

# call server

server = xmlrpclib.Server(url, login=login, password=pwd)
system = server.system

print "methods:"
for m in system.listMethods():
    print " ", m
    sigs = system.methodSignature(m)
    for sig in sigs:
        print "   ", sig
