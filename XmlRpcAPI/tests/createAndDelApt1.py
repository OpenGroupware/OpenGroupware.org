#!/usr/bin/python

import xmlrpclib, time, sys

URL='http://localhost:20000/RPC2'
LOGIN="helge"
PWD=""

try:
    server = xmlrpclib.Server(URL, login=LOGIN, password=PWD)
except TypeError, e:
    print "Catched:", e, "\n"
    print "Likely reason: you didn't install a basic-auth enabled XML-RPC"
    print "client library!"
    sys.exit(1)
print "Server:", server

startDate = time.strptime("2003-10-01","%Y-%m-%d")
startDate = xmlrpclib.DateTime(time.mktime(startDate))

endDate = time.strptime("2003-10-02","%Y-%m-%d")
endDate = xmlrpclib.DateTime(time.mktime(endDate))

dict = {}
dict['startDate'] = startDate
dict['endDate'] = endDate
dict['title'] = 'Exhibition'

print "Apt to be inserted:", dict

appointment = server.appointment.insert(dict)

print "Apt inserted:", appointment
print "  ID:", appointment['id']

#aptID={}
#aptID['id'] = appointment['id']
result = server.appointment.delete(appointment)

print "Apt deleted:", result
