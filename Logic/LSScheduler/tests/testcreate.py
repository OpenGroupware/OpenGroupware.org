#!/usr/bin/env python

import LSOffice
import EOControl
from Foundation import *

null = EOControl.EONull()

lso = LSOffice.LSOffice(user='helge', password='helgehelge')

def makeNew(title, participants, startDate, endDate, resources=None,
            comment=None, conflict=0):
    ps = []
    
    for p in participants:
        pp = lso.run1("account::get-by-login", login=str(p))
        ps.append(pp)
    ps = tuple(ps)
    
    for p in ps:
        print "participant:", p['login']
    
    ignoreWarning = not conflict
    
    a = lso.run("appointment::new",
        title =            title,
        participants =     ps,
        startDate =        startDate,
        endDate =          endDate,
        isWarningIgnored = ignoreWarning,
        log =              "created by script")
    lso.commit()
    
    return a

now = NSCalendarDate()

makeNew("Date %s:%s" % (now.hourOfDay(),now.minuteOfHour()),
        ( "helge", "helge2", ),
        now,
        now.dateByAdding(hours=1, minutes=30))
