#!/usr/bin/env python

import xmlrpclib
import base64, StringIO
from pprint import pprint

server = xmlrpclib.Server('http://localhost:20001/test1.woa/xmlrpc',
                          login="superman",
                          password="system");

file = open('./sendMessageTest.gif','r')
data = file.read();
data = base64.encodestring(data);
#print data;

mailComponent = server.com.skyrix.mail

print "\nsendMessage:"
pprint(mailComponent.sendMessage([{"email":"Gerrit Albrecht <ga@skyrix.com>",
                                 "header":"to"},
                                {"email":"Gerrit Albrecht <gerrit@skyrix.com>",
                                 "header":"cc"}],
                               "XMLRPC Mailtest - 1",
                               "Example content\nzweite zeile\n",
                               [
                                   {
                                       "mimeType":"image/gif",
                                       "content":data,
                                       "fileName":"test.gif"
                                   }
                               ],
                               { "test":"data" } ));

print "\nsendMessage: (nochmal)"
pprint(mailComponent.sendMessage(["Gerrit Albrecht <ga@skyrix.com>", "Gerrit Albrecht <gerrit@skyrix.com>"],
                               "XMLRPC Mailtest - 2",
                               "Auch diese Mail geht."));

