#!/bin/env python
# $Id: test_fm.py,v 1.1 2003/08/19 12:01:36 helge Exp $

from SkyProjectFileManager import *

fm = SkyProjectFileManager('donald', 'duck', 'ogohost', 20000);


def testAll():
    print fm.directoryContentsAtPath('/');


    print fm.attributesAtPath('/internals');
    print "*****************";
    print fm.directoryContentsAtPath('/internals');
    print fm.createDirectoryAtPath('/internals/doof10doofdoofdoododox');
    print fm.directoryContentsAtPath('/internals');
    print fm.removeFileAtPath('/internals/doof10doofdoofdoododox');
    print fm.directoryContentsAtPath('/internals');
    print fm.createDirectoryAtPath('/internals/doof10doofdoofdoododox');
    print "fileExistsAtPath"
    print fm.fileExistsAtPath('/internals/doof10doofdoofdoododox');
    print fm.fileExistsAtPath('test_jr_1.txt');
    print fm.fileExistsAtPath('dododo21092093-03do.txt');
    print "fileExistsAtPathIsDirectory"
    print fm.fileExistsAtPathIsDirectory('/internals/doof10doofdoofdoododox');
    print fm.fileExistsAtPathIsDirectory('test_jr_1.txt');
    print fm.fileExistsAtPathIsDirectory('dododo21092093-03do.txt');
    print fm.directoryContentsAtPath('/internals');
    print "copy";
    print fm.copyPathToPath('/internals/doof10doofdoofdoododox',
                            '/internals/doof10doofdoofdoododoxxxxxxxxx');
    print fm.directoryContentsAtPath('/internals');
    print fm.removeFileAtPath('/internals/doof10doofdoofdoododoxxxxxxxxx');
    print fm.directoryContentsAtPath('/internals');
    print "move";
    print fm.movePathToPath('/internals/doof10doofdoofdoododox',
                            '/internals/doof10doofdoofdoododoxxxxxxxxx');
    print fm.directoryContentsAtPath('/internals');
    print fm.removeFileAtPath('/internals/doof10doofdoofdoododoxxxxxxxxx');
    print fm.directoryContentsAtPath('/internals');
    print fm.contentsAtPath('test_jr_1.txt');
    print fm.writeContentsAtPath("das istsssss ein test", 'test_jr_1.txt');
    print fm.contentsAtPath('test_jr_1.txt');

def testProps():
    print fm.attributesAtPath('/test_jr_10.txt');
    attrs = ['color',];
    fm.deleteAttributesAtPath('/test_jr_10.txt', attrs);
    attrs = {};
    attrs['color1'] = '"yel< ddd & dddd >\'lo"';
    fm.writeAttributesAtPath('/test_jr_10.txt', attrs);
    print fm.attributesAtPath('/test_jr_10.txt');

testAll();
testProps();    
