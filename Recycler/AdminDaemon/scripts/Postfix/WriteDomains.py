#!/usr/bin/python

import xmlrpclib, time, sys, os;
import XmlRpcdClient;
import string;

class WriteDomains(XmlRpcdClient.XmlRpcdClient):

    def write(self):
        domains = self.server().defaults.objectForKey("administrated domains",
                                                      "MTA");
        domains = string.split(domains, '; ');
        file    = self.prepareWriteFile(self.dataFilePath());

        for d in domains:
            file.write(d + "\n");

        file.close();
    
    def dataFile(self):
        return os.getenv('localdomain_file');

# class: WriteDomains
