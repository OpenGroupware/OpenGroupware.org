#!/usr/bin/env python

import xmlrpclib
from pprint import pprint
import base64


def checkAccount():
    server = xmlrpclib.Server('http://localhost:15053/test1.woa/xmlrpc',
                              login='j', password='janjan');

    accountsComponent = server.com.skyrix.accounts
    pprint(accountsComponent.getAccountByLogin('j'));
    
    pprint(accountsComponent.authenticate("login_8", ""));
    pprint(accountsComponent.getAccountByLogin("login_8"));
    logid = (accountsComponent.getAccountByLogin("login_8"))['uid'];



    server = xmlrpclib.Server('http://localhost:15053/test1.woa/xmlrpc',
                              login='root', password='root');
    accountsComponent = server.com.skyrix.accounts
    
    pprint(accountsComponent.isAccountLocked(logid));
    pprint(accountsComponent.lockAccount(logid));
    pprint(accountsComponent.isAccountLocked(logid));
    pprint(accountsComponent.authenticate("login_8", ""));
    
    pprint(accountsComponent.unlockAccount(logid));
    
    
    pprint(accountsComponent.authenticate("login_8", ""));

def checkGroups():
    server = xmlrpclib.Server('http://localhost:15053/test1.woa/xmlrpc',
                              login='j', password='janjan');

    accountsComponent = server.com.skyrix.accounts
    pprint(accountsComponent.getGroups());

checkGroups();
#checkAccount();
