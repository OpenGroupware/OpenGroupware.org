#!/usr/bin/env python

import xmlrpclib

url   = "http://localhost:10800/Registry/xmlrpc"
login = "bjoern"
pwd   = "bjoern"

# call server

registry = xmlrpclib.Server(url, login=login, password=pwd).active.registry
registry.setComponent('com.skyrix.track','Track/xmlrpc','marvin.in.skyrix.com','10822')
