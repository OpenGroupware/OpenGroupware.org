#!/usr/bin/env python
# $Id: check_default.py,v 1.1 2003/12/12 14:36:45 helge Exp $

import common;
import sys;

if len(sys.argv) > 1:
    server = common.server();
    print str(server.defaults.stringForKey(sys.argv[1], "MTA"));
