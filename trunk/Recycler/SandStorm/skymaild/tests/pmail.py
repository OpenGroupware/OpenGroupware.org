#!/usr/bin/env python

import xmlrpclib
import sys, getpass
from pprint import pprint

url = 'http://localhost:20000/test1.woa/xmlrpc';
print "connecting skymaild service at", url

# some functions ...

def promptForString(text=None):
    sys.stdout.write(text)
    sys.stdout.flush()
    str = sys.stdin.readline()
    if len(str) > 0:
        str = str[:-1]
    else:
        return None
    return str

# collect parameters

login = promptForString  ("Login: ")
pwd   = getpass.getpass("Password: ")

server = xmlrpclib.Server(url, login=login, password=pwd);
print "Server:", server

print "Compose Message ..."

to = promptForString("To: ")

ccs = []
while 1:
    cc = promptForString("CC: ")
    if not len(cc):
        break
    ccs.append(cc)

subject = promptForString("Subject: ");

print "Content:"
content = ""
while 1:
    str = sys.stdin.readline()
    if len(str) == 0:
        break;
    if str == ".\n":
        break;
    content = content + str

# compose query

info = []
info.append( { "email": to, "header": "to" } )
for cc in ccs:
    info.append( { "email": cc, "header": "cc" } )

# send query

result = server.com.skyrix.mail.sendMessage(info, subject, content, []);

# print result

print "Mail sent, result:"
pprint(result)
