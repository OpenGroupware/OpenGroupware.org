#!/usr/bin/env python
# $Id$

import common;
import sys;

if len(sys.argv) > 1:
    server = common.server();
    print str(server.defaults.stringForKey(sys.argv[1], "MTA"));
