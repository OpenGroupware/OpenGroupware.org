#!/usr/bin/env python
# $Id$

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

