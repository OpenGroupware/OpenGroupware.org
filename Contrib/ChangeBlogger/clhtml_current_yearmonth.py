#!/usr/bin/env python
# ZNeK - 20040901

"""
Find the most recent year/month combo in the index. Use this to change the
index.html of your change blogger archive when it's become necessary to do so
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
    years = INDEX.keys()
    years.sort(sortDescending)
    year = years[0]
    months = INDEX[year].keys()
    months.sort(sortDescending)
    month = months[0]
    print "%s%s" % (year, month)
