#!/usr/bin/env python
# $Id$

import XmlRpcdClient;
import sys;
from time import gmtime, strftime

class WriteError(XmlRpcdClient.XmlRpcdClient):

    def run(self):
        if len(sys.argv) > 1:
            strformat = "%a %b %d %H:%M:%S %Z %Y";
            server = self.server();
            key    = "error messages";
            str    = server.defaults_stringForKey(key, self.domain());
            
            if len(str) > 2000:
                str = str[0:2000];

            print strftime(strformat, gmtime()) + ": " + sys.argv[1];
            str = strftime(strformat, gmtime()) + ": " + sys.argv[1] + "<br><hr>\n" + str;
                           
            server.defaults_writeStringForKey(key, str, self.domain());
            server.defaults_writeStringForKey('export is in progress',
                                              'NO', self.domain());

if __name__ == "__main__":
    app = WriteError();
    app.run();
