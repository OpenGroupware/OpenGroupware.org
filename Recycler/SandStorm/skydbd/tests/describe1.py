#!/usr/bin/env python

import xmlrpclib

url   = "http://localhost:20000/test1.woa/wa/RPC2"
login = "test"
pwd   = "test"

# call server

server = xmlrpclib.Server(url, login=login, password=pwd)
db = server.com.skyrix.db.Oracle7.skyrix38.system

# tables

result = db.getTables()
for i in result:
    print "Table:", i
print "%i tables." % ( len(result), )

print

# columns

print "table 'company':"

pkeys  = db.getPrimaryKeyAttributesOfTable("company")
pkeynames = []
for p in pkeys:
    pkeynames.append(p[0])

result = db.getAttributesOfTable("company")
fmt = "  %-20s %-20s %-12s %s"
print fmt % ( "name", "column", "type", "" )
for i in result:
    txt = ""
    if i[0] in pkeynames: txt = "PRIMARY KEY"
    print fmt % ( i[0], i[1], i[2], txt )
