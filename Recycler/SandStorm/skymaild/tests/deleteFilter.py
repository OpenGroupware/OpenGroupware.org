#!/usr/bin/env python

import xmlrpclib
from pprint import pprint

server = xmlrpclib.Server('http://debian:20001/test1.woa/xmlrpc',
                          login="gerrit",
                          password="gerrit");

mailComponent = server.com.skyrix.mail

print "\ndeleteFilter 1:"
pprint(mailComponent.deleteFilter(1));

print "\ndeleteFilter 2:"
pprint(mailComponent.deleteFilter("test"));

print "\ndeleteFilter 3:"
pprint(mailComponent.deleteFilter({
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
