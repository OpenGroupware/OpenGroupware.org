#!/usr/bin/env python
# $Id: WriteDefault.py,v 1.2 2003/12/12 14:26:19 helge Exp $

import XmlRpcdClient;
import sys;

class WriteDefault(XmlRpcdClient.XmlRpcdClient):

    def run(self):
        if len(sys.argv) > 2:
            self.server().defaults_writeStringForKey(sys.argv[1],
                                                     sys.argv[2],
                                                     self.domain());
        else:
            print "missing arguments WriteDefault key value";

if __name__ == "__main__":
    app = WriteDefault();
    app.run();

