#!/usr/bin/python
# $Id: write_postfix.py,v 1.1 2003/12/12 14:36:45 helge Exp $

import xmlrpclib, time, sys, os;
from WriteAccounts import *;
from WriteTeams    import *;
from WriteDomains  import *;

wa = WriteAccounts();
wt = WriteTeams();
wd = WriteDomains();

wa.deleteFiles();
wt.deleteFiles();
wd.deleteFiles();

wt.write();
wa.write();
wd.write();
