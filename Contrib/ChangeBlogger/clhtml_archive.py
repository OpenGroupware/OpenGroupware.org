#!/usr/bin/env python
# ZNeK - 20031012

"""
HTML ChangeLog aggregation.
"""

__version__ = "@()$Id: clhtml_archive.py,v 1.1.1.1 2003/10/16 11:02:35 znek Exp $"

import sys
from index import INDEX


##
##  HELPERS
##


def sortDescending(a, b):
    ai = int(a)
    bi = int(b)
    if ai < bi:
        return 1
    elif ai > bi:
        return -1
    return 0


##
##  MAIN
##


if __name__ == '__main__':
    print "#!/bin/sh"
    print "# create OGo ChangeLog archive"
    print ""
    
    # optimization: create latest months first, so pages which are likely
    # of most interest are updated first

    years = INDEX.keys()
    years.sort(sortDescending)
    for year in years:
        months = INDEX[year].keys()
        months.sort(sortDescending)
        for month in months:
            print "./clhtml_month.py %s %s" % (year, month)
