#!/usr/bin/env python

import xmlrpclib, time, sys, getpass, time

HOST="localhost"
LOGIN="helge"
PROJECTCODE="DBTEST"
#PROJECTCODE="USERFAV_10280"
EXT="jadis"
DIR="/jadis"
COUNT=5

p = "Enter password for user %s: " % ( LOGIN,)
PWD = getpass.getpass(p)

#URL="http://%s:%s@%s:80/RPC2" % ( LOGIN, PWD, HOST )
URL="http://%s:80/RPC2" % ( HOST, )

# ********** setup server object **********

try:
    server = xmlrpclib.Server(URL, login=LOGIN, password=PWD)
except TypeError, e:
    print "Catched:", e, "\n"
    print "Likely reason: you didn't install a basic-auth enabled XML-RPC"
    print "client library!"
    sys.exit(1)
print "Server:", server

base=int(time.time() - 1103488050)
#commentbase=base
commentbase="jadis-"

#print server.project.ls(PROJECTCODE)

# ********** check whether directory exists **********

if not server.project.exists(PROJECTCODE, (DIR,)):
    print "Directory '%s' does not exist in project: '%s'" % \
          ( DIR, PROJECTCODE )
    sys.exit(2)

if not server.project.isdir(PROJECTCODE, (DIR,)):
    print "Path '%s' is not a directory: '%s'" % ( DIR, PROJECTCODE )
    sys.exit(3)

# ********** create files in directory **********

print "Creating %i files in project %s, folder %s ..." % \
      ( COUNT, PROJECTCODE, DIR )

for i in range(1, COUNT + 1):
    fn = "test-%s-%i.%s" % ( base, i, EXT )
    attrs = { 'commentid': commentbase + str(i),
              'created':   '2004-10-10',
              'previewid': str(base) + "-" + str(i),
              'subject':   'autocreate title' + fn,
              'label':     'auto label' }
    doc = server.project.newDocument(PROJECTCODE, DIR+"/"+fn,
                                     "autocreate content of " + fn,
                                     attrs)
