#!/usr/bin/env python

import xmlrpclib, time, sys, os;
import imaplib;
import XmlRpcdClient;

class WriteQuota(XmlRpcdClient.XmlRpcdClient):

    def write(self):
        host     = os.getenv("imap_host");
        port     = os.getenv("imap_port");
        root     = os.getenv("imap_root");
        pwd      = os.getenv("imap_pwd");
        port     = os.getenv("imap_port");
        userpref = os.getenv("imap_user_prefix");

        if len(host) == 0 | len(port) == 0 | len(root) == 0| len(pwd) == 0 | len(port) == 0 | len(userpref) == 0:
             print "missing write_quota environment variables";
             sys.exist(1);

        res        = self.server().account.fetchAllImapInfo();
        imapServer = imaplib.IMAP4();

        imapServer.open(host, int(port));
        imapServer.login(root, pwd);

        for e in res:
            login = e['login'];
            quota = e['quota'];

            if len(login) == 0:
                print "missing login for " + str(e);
                continue;

            if quota == None:
                quota = "";

            if len(quota) == 0:
                quota = "none";
                 
            res = imapServer.setquota(userpref + login, "(storage " + quota + ")");

            if res[0] != 'OK':
                print >> sys.stderr, "setquota for '" + login + "' failed with <" + str(res) + ">";

if __name__ == "__main__":
    app = WriteQuota();
    app.write();
