#!/usr/bin/env python

import xmlrpclib
from pprint import pprint

server = xmlrpclib.Server('http://localhost:20001/test1.woa/xmlrpc',
                          login="superman",
                          password="system");

print "\ngetMessage:"
pprint(server.com.skyrix.mail.getMessage("/INBOX/sent-mail/1"));

