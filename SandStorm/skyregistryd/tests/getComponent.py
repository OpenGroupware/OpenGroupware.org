#!/usr/bin/env python

import xmlrpclib, sys

url   = "http://localhost:20002/test1.woa/wa/RPC2"
login = "test"
pwd   = "test"

args = sys.argv[1:]

# call server

server = xmlrpclib.Server(url, login=login, password=pwd)

if len(args) == 0:
    for comp in server.active.registry.getComponents():
        print comp
else:
    try:
        d = server.active.registry.getComponent(args[0])
        for k,v in d.items():
            k = k + ":"
            print "%-6s %s" % ( k, v )
    except xmlrpclib.Fault, f:
        print "XML-RPC Fault: ", f
