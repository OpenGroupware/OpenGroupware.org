#!/usr/bin/env python

import xmlrpclib
from pprint import pprint

server = xmlrpclib.Server('http://debian:20001/test1.woa/xmlrpc',
                          login="gerrit",
                          password="gerrit");

print "\ngetFilterNames:"
pprint(server.com.skyrix.mail.getFilterNames());
