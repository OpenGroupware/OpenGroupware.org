#!/usr/bin/python

import xmlrpclib, time, sys, getpass

if len(sys.argv) < 5:
    print "usage: %s <host> <login> <addlogin> <apt-id>" % ( sys.argv[0], )
    sys.exit(1)

HOST=sys.argv[1]
LOGIN=sys.argv[2]
OTHERLOGIN=sys.argv[3]
APTID=sys.argv[4]

p = "Enter password for user %s: " % ( LOGIN,)
PWD = getpass.getpass(p)

#URL="http://%s:%s@%s:80/RPC2" % ( LOGIN, PWD, HOST )
URL="http://%s:80/RPC2" % ( HOST, )

# ********** setup server object

try:
    server = xmlrpclib.Server(URL, login=LOGIN, password=PWD)
except TypeError, e:
    print "Catched:", e, "\n"
    print "Likely reason: you didn't install a basic-auth enabled XML-RPC"
    print "client library!"
    sys.exit(1)
print "Server:", server

# ********** run

print "======================================================================"
print "fetching appointment ..."
try:
    apt = server.appointment.getById(APTID)
except Exception, e:
    print "Catched:", e, "\n"
    apt = None
if apt is None:
    print "found no appointment with ID:", APTID
    sys.exit(2)
print "  got: %s" % ( apt, )
print "t", type(apt)

print "======================================================================"
print "fetching person ..."
q = "login='%s'" % ( OTHERLOGIN, )
p = server.person.fetch( { 'qualifier': q } )
if len(p) == 0:
    print "found no account with login: '%s'" % ( OTHERLOGIN, )
    sys.exit(3)
print "  got: %(login)s (%(id)s)" % ( p, p, )

print "======================================================================"
print "setting participant ..."
server.appointment.setParticipants( {'id': APTID }, [p,])

print "======================================================================"
print "refetching appointment ..."
print server.appointment.getById(APTID)
