#!/usr/bin/env python
# $Id$

import xmlrpclib, time, sys, os;

# prepare file writing
# check whether _fileName exist, if YES opens it in read mode
# check whether _tmpFileName exist, if YES remove it
# create new _tmpFile and open it in write mode
# return tupel of file and tmpFile

class XmlRpcdClient:

    def __init__(self):
        self.__server = None;
        self.__domain   = None;

    def server(self,
               url=os.getenv("xmlrpcd_url"),
               login=os.getenv("xmlrpcd_login"),
               pwd=os.getenv("xmlrpcd_pwd"),
               ):
        if self.__server:
            return self.__server
        
        if not url:
            print "environment variable not set: xmlrpcd_url"
            sys.exit(1)
        if not login:
            print "environment variable not set: xmlrpcd_login"
            sys.exit(1)
        if not pwd:
            print "environment variable not set: pwd"
            sys.exit(1)
        
        try:
            self.__server = xmlrpclib.Server(url, login=login, password=pwd)
        except TypeError, e:
            print "Catched:", e, "\n"
            print "Likely reason: you didn't install a basic-auth enabled "
            print "XML-RPC client library!"
            sys.exit(1)
        
        return self.__server;

    def domain(self):
        if self.__domain == None:
            self.__domain = os.getenv("domain");

            if self.__domain == None:
                self.__domain = "MTA";

        return self.__domain;

    def deleteFiles(self):
        f = self.dataFilePath();

        if f != None:
            if os.access(f, os.F_OK):
                os.remove(f);

    def dataFilePath(self):
        file = self.dataFile();

        if file != None:
            pref = os.getenv("tmp_dir");

            if pref == None:
                print "missing tmp_dir";
                return None;
            
            file = pref + "/" + file;
            return file;

        return None;
            
        

    def dataFile(self):
        return None;


    def prepareWriteFile(self, _fileName):
        if os.access(_fileName, os.F_OK):
            os.remove(_fileName);
            
        return open(_fileName, 'w');

    # writes an entry in postmap format to _file if len(_aliases) > 0
    
    def writePostmapEntry(self, _file, _key, _aliases):
        if (len(_aliases) == 0):
            return;
    
        isFirst = 1;
        _file.write(_key + " ");
        for em in _aliases:
            if isFirst == 0:
                _file.write(", ");

            isFirst = 0;
            _file.write(em);
        _file.write("\n");

        # write dict {key:(value, value)} to _fileName using _tmpFileName and


    def writePostmap(self, _fileName, _dict):
        file = self.prepareWriteFile(_fileName);
    
        for key in _dict.keys():
            self.writePostmapEntry(file, key, _dict[key]);

        file.close();
        return None;

if __name__ == "__main__":
    app = XmlRpcdClient();
    print app.server();

