#!/usr/bin/env python

import xmlrpclib
from pprint import pprint

server = xmlrpclib.Server('http://debian:20001/test1.woa/xmlrpc',
                          login="gerrit",
                          password="gerrit");

print "\ninsertFilter:"
pprint(server.com.skyrix.mail.insertFilter({
                                  "entries" : [
                                    {
                                      "filterKind" : "begins with",
                                      "headerField" : "subject",
                                      "string" : "XMLRPC"
                                    }
                                  ],
                                  "filterPos" : 0,
                                  "folder" : "/INBOX/test",
                                  "match" : "or",
                                  "name" : "test"
                                }));
