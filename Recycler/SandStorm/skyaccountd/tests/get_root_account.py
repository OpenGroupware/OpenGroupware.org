#!/usr/bin/env python

import xmlrpclib
import sys, getpass
from pprint import pprint

url = "http://localhost:20005/test1.woa/wa/RPC2"

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

try:
    login = "root" #promptForString("Login: ")
    pwd   = "root" # getpass.getpass("Password: ")
except KeyboardInterrupt:
    print "ctrl-c"
    sys.exit(0)

# call server

server = xmlrpclib.Server(url, login=login, password=pwd)
accountsComponent = server.com.skyrix.accounts

result = accountsComponent.getAccountByLogin('root');

pprint(result)
