#!/usr/bin/env python

import xmlrpclib
from pprint import pprint

server = xmlrpclib.Server('http://localhost:15053/test1.woa/xmlrpc',
                          login='root', password='root')
accountsComponent = server.com.skyrix.accounts

# print "\nremove old 'xmlRpcTest' login";
pprint(accountsComponent.delete("xmlRpcTest"));

print "\ncreate new account:";
pprint(accountsComponent.add(login='xmlRpcTest', password='xmlrpc',
                           name='XML', firstname='RPC', nickname='xmlrpc'));

print "\nnew account is:";
pprint (accountsComponent.getByLogin('xmlRpcTest'));
