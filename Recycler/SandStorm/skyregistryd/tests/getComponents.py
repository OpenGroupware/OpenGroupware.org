#!/usr/bin/env python

import xmlrpclib

url   = "http://localhost:20002/test1.woa/wa/RPC2"
login = "test"
pwd   = "test"

# call server

server = xmlrpclib.Server(url, login=login, password=pwd)

for comp in server.active.registry.getComponents():
    print comp
