#!/usr/bin/python
# $Id$

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
