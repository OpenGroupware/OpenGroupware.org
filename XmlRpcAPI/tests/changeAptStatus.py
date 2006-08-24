#!/usr/bin/python

import xmlrpclib, time, sys, pprint

# call it like:
#   changeAptStatus.py <host> <user> <password> <primary key> <new status>
# eg
#   changeAptStatus.py localhost donald duck 12345 ACCEPTED

server = xmlrpclib.Server("http://" + sys.argv[2] + ":" +
                          sys.argv[3] + "@" + sys.argv[1] + "/RPC2",
                          allow_none = 1)
print "Server:", server

ok = server.appointment.changeStatus(int(sys.argv[4]), sys.argv[5],
                                     None, None, None)
print "DID: ", ok
