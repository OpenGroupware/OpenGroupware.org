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

URL2="http://%s:%s@%s:80/RPC2" % ( LOGIN, PWD, HOST )
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

# ********** printing

def printApt(apt):
    print "Appointment: %(title)s (%(id)s)" % apt
    print "  owner: %(login)s" % apt['owner']
    for part in apt['participants']:
        print "  participant: %(login)s" % part

# ********** fetching

def fetchApt(ID):
    try:
        apt = server.appointment.getById(ID)
    except Exception, e:
        print "Catched:", e, "\n"
        apt = None
    if apt is None:
        print "found no appointment with ID:", ID
        sys.exit(2)
    return apt

# ********** run

print "======================================================================"
print "fetching appointment ..."
apt = fetchApt(APTID)
printApt(apt)

print "======================================================================"
print "fetching person ..."
q = "login='%s'" % ( OTHERLOGIN, )
p = server.person.fetch( { 'qualifier': q } )
if len(p) == 0:
    print "found no account with login: '%s'" % ( OTHERLOGIN, )
    sys.exit(3)
p = p[0]
print "  got: %(login)s (%(id)s)" % p

print "======================================================================"
print "setting participant ..."
server.appointment.setParticipants( {'id': APTID }, [p['id'], ])

print "======================================================================"
print "refetching appointment ..."
apt = fetchApt(APTID)
printApt(apt)
