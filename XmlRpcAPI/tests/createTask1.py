#!/usr/bin/python

import xmlrpclib, sys, pprint

server = xmlrpclib.Server("http://" + sys.argv[2] + ":" + sys.argv[3] + "@" + sys.argv[1] + "/RPC2")

executor = server.account.getByLogin(sys.argv[4])
print "-----EXECUTOR-----"
pprint.pprint(executor)

job = { }
job["creator"] = executor
job["executor"] = executor
job["name"] = 'A test job'
job["startDate"] = xmlrpclib.DateTime("20050311T15:31:20")
job["endDate"] = xmlrpclib.DateTime("20050314T15:31:20")
job["kilometers"] = 10

person = server.person.get(executor["id"])
print "-----PERSON-----"
pprint.pprint(person)

print "----CREATE JOB----"
result = server.person.insertJob(person[0], job)
pprint.pprint(result)

