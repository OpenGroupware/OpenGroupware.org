#!/usr/bin/env python
# runs with the Python 2.3 xmlrpclib

import xmlrpclib, getpass

HOST="localhost"
LOGIN="helge"

p = "Enter password for user %s: " % ( LOGIN,)
PWD = getpass.getpass(p)

URL2="http://%s:%s@%s:80/RPC2" % ( LOGIN, PWD, HOST )
server = xmlrpclib.Server(URL2)

accounts = server.account.fetch({ 'qualifier': "login LIKE '*'" })
for account in accounts:
    person = server.person.getById(account['id'])
    ext    = person['extendedAttrs']
    firstname, lastname, email = "", "", ""
    if person.has_key('firstname'): firstname = person['firstname']
    if person.has_key('name'):      lastname  = person['name']
    if ext.has_key('email1'):       email     = ext['email1']
    
    s = "%s,%s,%s" % ( lastname, firstname, email )
    print s.encode("utf-8")
