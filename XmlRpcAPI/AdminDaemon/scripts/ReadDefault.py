#!/usr/bin/env python
# $Id: ReadDefault.py,v 1.2 2003/12/12 14:26:19 helge Exp $

import XmlRpcdClient;
import sys, os;

class ReadDefault(XmlRpcdClient.XmlRpcdClient):

    def run(self):
        if len(sys.argv) > 1:
            print str(self.server().defaults.stringForKey(sys.argv[1],
                                                          self.domain()));

if __name__ == "__main__":
    app = ReadDefault();
    app.run();
