#!/usr/bin/env python
# $Id: test_ls.py,v 1.1 2003/08/19 12:01:36 helge Exp $

from SkyProjectFileManager import *
from pprint import pprint

fm = SkyProjectFileManager('donald', 'duck', 'ogohost', 20000);

dirfmt  = "%(NSFileName)-30s (dir)"
filefmt = "%(NSFileName)-30s %(NSFileSize)5i"

if 0:
    for dir in fm.directoryContentsAtPath('/'):
        pfile = "/" + dir
        print dir,
        if fm.fileExistsAtPathIsDirectory(pfile):
            print "(dir)"
        else:
            attrs = fm.attributesAtPath(pfile)
            print "size: %(NSFileSize)i" % attrs

ds = fm.dataSourceAtPath("/")
for attrs in ds.fetchObjects():
    pfile = attrs['NSFilePath'];
    isdir = attrs['NSFileType'] == "NSFileTypeDirectory";
    
    if isdir:
        print dirfmt % attrs
    else:
        print filefmt % attrs
