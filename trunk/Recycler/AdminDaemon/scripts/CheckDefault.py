#!/usr/bin/env python
# $Id$

import XmlRpcdClient;
import sys;

class CheckDefault (XmlRpcdClient.XmlRpcdClient) :

    def run(self):
        if len(sys.argv) > 1:
            print str(self.server().defaults.stringForKey(sys.argv[1],
                                                          self.domain()));

if __name__ == "__main__":
    app = CheckDefault();
    app.run();
