#!/usr/bin/env python

import xmlrpclib

url   = "http://localhost:20000/test1.woa/wa/RPC2"
login = "test"
pwd   = "test"

# call server

server = xmlrpclib.Server(url, login=login, password=pwd)
#db = server.com.skyrix.in.marvin.skydbd.Oracle7.skyrix38.system
db = server

result = db.evaluate("select login from company where is_account=1")
for i in result:
    print i['login']

print "%i records." % ( len(result), )
