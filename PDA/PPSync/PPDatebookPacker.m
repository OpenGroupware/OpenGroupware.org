/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/
// $Id$

#include "PPDatebookPacker.h"
#include "PPRecordDatabase.h"
#include "PPSyncContext.h"
#include "common.h"

enum alarmTypes {advMinutes, advHours, advDays};

enum repeatTypes {
   repeatNone,
   repeatDaily,
   repeatWeekly,
   repeatMonthlyByDay,
   repeatMonthlyByDate,
   repeatYearly
};

enum  DayOfMonthType{
  dom1stSun, dom1stMon, dom1stTue, dom1stWen, dom1stThu, dom1stFri, dom1stSat,
  dom2ndSun, dom2ndMon, dom2ndTue, dom2ndWen, dom2ndThu, dom2ndFri, dom2ndSat,
  dom3rdSun, dom3rdMon, dom3rdTue, dom3rdWen, dom3rdThu, dom3rdFri, dom3rdSat,
  dom4thSun, dom4thMon, dom4thTue, dom4thWen, dom4thThu, dom4thFri, dom4thSat,
  domLastSun, domLastMon, domLastTue, domLastWen, domLastThu, domLastFri,
  domLastSat
};

struct Appointment {
  int event;               /* Is this a timeless event? */
  struct tm begin, end;    /* When does this appointment start and end? */
	
  int alarm;               /* Should an alarm go off? */
  int advance;             /* How far in advance should it be? */
  int advanceUnits;        /* What am I measuring the advance in? */
	
  enum repeatTypes repeatType;  /* How should I repeat this appointment, if at all? */
  int repeatForever;       /* Do the repetitions end at some date? */
  struct tm repeatEnd;     /* What date do they end on? */
  int repeatFrequency;     /* Should I skip an interval for each repetition? */
  enum DayOfMonthType repeatDay;/* for repeatMonthlyByDay */
  int repeatDays[7];       /* for repeatWeekly */
  int repeatWeekstart;     /* What day did the user decide starts the week? */
	
  int exceptions;          /* How many repetitions are their to be ignored? */
  struct tm * exception;   /* What are they? */
	
  char * description;      /* What is the description of this appointment? */
  char * note;             /* Is there a note to go along with it? */
};

static int unpack_Appointment(struct Appointment * a,
                              unsigned char * buffer, int len);
static int pack_Appointment(struct Appointment *a,
                            unsigned char *buf,
                            int len);

@implementation PPDatebookPacker

- (id)initWithObject:(id)_object {
  self->eo = RETAIN(_object);
  return self;
}

- (void)dealloc {
  RELEASE(self->eo);
  [super dealloc];
}

/* accessors */

- (id)object {
  return self->eo;
}

/* operations */

static int pack_Appointment(struct Appointment *a,
                            unsigned char *buf,
                            int len)
{
  int iflags;
  char *pos;
  int destlen = 8;
    
  if (a->alarm)
    destlen+=2;
  if (a->repeatType)
    destlen+=8;
  if (a->exceptions)
    destlen+=2+2*a->exceptions;
  if (a->note)
    destlen+=strlen(a->note)+1;
  if (a->description)
    destlen+=strlen(a->description)+1;
    
  if (!buf)
    return destlen;
  if (len<destlen)
    return 0;

  set_byte(buf, a->begin.tm_hour);
  set_byte(buf+1, a->begin.tm_min);
  set_byte(buf+2, a->end.tm_hour);
  set_byte(buf+3, a->end.tm_min);
  set_short(buf+4, ((a->begin.tm_year - 4) << 9) |
            ((a->begin.tm_mon  + 1) << 5) |
            a->begin.tm_mday);
    
  if (a->event)
    set_long(buf, 0xffffffff);

#define alarmFlag 64
#define repeatFlag 32
#define noteFlag 16
#define exceptFlag 8
#define descFlag 4

  iflags = 0;
    
  pos = (char *)buf + 8;

  if (a->alarm) {
    iflags |= alarmFlag;
        
    set_byte(pos, a->advance);
    set_byte(pos+1, a->advanceUnits);
    pos+=2;
  }
    
  if (a->repeatType) {
    int on,i;

    iflags |= repeatFlag;
        
    if (a->repeatType == repeatMonthlyByDay)
      on = a->repeatDay;
    else if (a->repeatType == repeatWeekly) {
      on = 0;
      for (i=0;i<7;i++) {
        if (a->repeatDays[i])
          on |= 1<<i;
      }
    }
    else
      on = 0;

    set_byte(pos, a->repeatType);
    set_byte(pos+1, 0);
    pos+=2;
    	
    if (a->repeatForever)
      set_short(pos, 0xffff);
    else {
      set_short(pos, ((a->repeatEnd.tm_year - 4) << 9) |
                ((a->repeatEnd.tm_mon  + 1) << 5) |
                a->repeatEnd.tm_mday);
    }
        
    pos+=2;
        
    set_byte(pos, a->repeatFrequency); pos++;
    set_byte(pos, on); pos++;
    set_byte(pos, a->repeatWeekstart); pos++;
    set_byte(pos, 0); pos++;
  }
    
  if (a->exceptions) {
    int i;
        
    iflags |= exceptFlag;
        
    set_short(pos, a->exceptions); pos+=2;
        
    for (i=0;i<a->exceptions;i++,pos+=2)
      set_short(pos, ((a->exception[i].tm_year - 4) << 9) |
                ((a->exception[i].tm_mon  + 1) << 5) |
                a->exception[i].tm_mday);
  }

  if (a->description != NULL) {
    iflags |= descFlag;
        
    strcpy(pos, a->description);
    pos += strlen(pos) + 1;
  }
    
  if (a->note != NULL) {
    iflags |= noteFlag;
        
    strcpy(pos, a->note);
    pos += strlen(pos) + 1;
  }

  set_byte(buf+6, iflags);
  set_byte(buf+7, 0); /* gapfil */

  return ((long)pos - (long)buf);
}

- (NSData *)packWithDatabase:(PPRecordDatabase *)_db {
  struct Appointment apt;
  unsigned char  buffer[0xffff];
  unsigned       len;
  NSCalendarDate *d;
  NSString       *s;
  
  apt.event = [[self->eo storedValueForKey:@"isEvent"]  boolValue] ? 1 : 0;
  apt.alarm = [[self->eo storedValueForKey:@"hasAlarm"] boolValue] ? 1 : 0;

  apt.advanceUnits = [[self->eo storedValueForKey:@"alarmAdvanceUnit"] intValue];
  switch (apt.advanceUnits) {
    case 0: // minutes
      apt.advance =
        [[self->eo storedValueForKey:@"alarmAdvance"] doubleValue] / 60.0;
      break;
    case 1: // hours
      apt.advance =
        [[self->eo storedValueForKey:@"alarmAdvance"] doubleValue] / 3600.0;
      break;
    case 2: // days
      apt.advance =
        [[self->eo storedValueForKey:@"alarmAdvance"] doubleValue]/(3600.0*24.0);
      break;
  }
  
  apt.repeatType = [[self->eo storedValueForKey:@"cycleType"] intValue];
  apt.repeatForever =
    [[self->eo storedValueForKey:@"cycleEndIsDistantFuture"] boolValue] ? 1 : 0;
  apt.repeatFrequency =
    [[self->eo storedValueForKey:@"cycleFrequency"] intValue];
  apt.repeatDay = [[self->eo storedValueForKey:@"dayCycle"] intValue];
  /* missing repeat-days */ // --> here they are
  { // repeat days
    NSArray *cycleDays = [self->eo storedValueForKey:@"cycleDays"];
    if ([cycleDays count] == 7) {
      apt.repeatDays[0] = [[cycleDays objectAtIndex:0] boolValue] ? 1 : 0;
      apt.repeatDays[1] = [[cycleDays objectAtIndex:1] boolValue] ? 1 : 0;
      apt.repeatDays[2] = [[cycleDays objectAtIndex:2] boolValue] ? 1 : 0;
      apt.repeatDays[3] = [[cycleDays objectAtIndex:3] boolValue] ? 1 : 0;
      apt.repeatDays[4] = [[cycleDays objectAtIndex:4] boolValue] ? 1 : 0;
      apt.repeatDays[5] = [[cycleDays objectAtIndex:5] boolValue] ? 1 : 0;
      apt.repeatDays[6] = [[cycleDays objectAtIndex:6] boolValue] ? 1 : 0;
    }
    else {
      int i;
      for (i = 0; i < 7; i++)
        apt.repeatDays[i] = 0;
    }
  }
  apt.repeatWeekstart =
    [[self->eo storedValueForKey:@"cycleWeekStart"] intValue];
  apt.exceptions = [[self->eo storedValueForKey:@"cycleExceptions"] intValue];

  { // exceptions
    int     i;
    struct  tm *excepts;
    NSArray *dates = nil;
    id      d;

    dates   = [self->eo storedValueForKey:@"cycleExceptionsArray"];

    if (dates) {
      apt.exceptions = [dates count];
      
      excepts = malloc(sizeof(struct tm)*apt.exceptions);
      for (i = 0; i < apt.exceptions; i ++) {
        d = [dates objectAtIndex:i];
        excepts[i].tm_year = [d yearOfCommonEra] - 1900;
        excepts[i].tm_mon  = [d monthOfYear] - 1;
        excepts[i].tm_mday = [d dayOfMonth];
        excepts[i].tm_hour = 0;
        excepts[i].tm_min  = 0;
        excepts[i].tm_sec  = 0;
        mktime(&excepts[i]);
      }
      
      apt.exception = excepts;
    }
    else {
      apt.exceptions = 0;
    }
  } /* exceptions */
  
  apt.description = (char *)[[self->eo storedValueForKey:@"title"] cString];
  if (apt.description == NULL) apt.description = "";
  
  /* write note, do not write empty notes .. */
  s = [self->eo storedValueForKey:@"note"];
  if (s == (id)[EONull null]) s = nil;
  if ([s length] == 0) s = nil;
  apt.note = (char *)[s cString];
  
  /* handle dates */
  
  if ((d = [self->eo storedValueForKey:@"cycleEndDate"])) {
    [d setTimeZone:[[_db syncContext] pilotTimeZone]];
    
    apt.repeatEnd.tm_mday = [d dayOfMonth];
    apt.repeatEnd.tm_mon  = [d monthOfYear] - 1;
    apt.repeatEnd.tm_year = [d yearOfCommonEra] - 1900;
    apt.repeatEnd.tm_hour = [d hourOfDay];
    apt.repeatEnd.tm_min  = [d minuteOfHour];
    apt.repeatEnd.tm_sec  = [d secondOfMinute];
  }
  
  if ((d = [self->eo storedValueForKey:@"startDate"])) {
    [d setTimeZone:[[_db syncContext] pilotTimeZone]];
    
    apt.begin.tm_mday = [d dayOfMonth];
    apt.begin.tm_mon  = [d monthOfYear] - 1;
    apt.begin.tm_year = [d yearOfCommonEra] - 1900;
    apt.begin.tm_hour = [d hourOfDay];
    apt.begin.tm_min  = [d minuteOfHour];
    apt.begin.tm_sec  = [d secondOfMinute];
  }
  if ((d = [self->eo storedValueForKey:@"endDate"])) {
    [d setTimeZone:[[_db syncContext] pilotTimeZone]];
    
    apt.end.tm_mday = [d dayOfMonth];
    apt.end.tm_mon  = [d monthOfYear] - 1;
    apt.end.tm_year = [d yearOfCommonEra] - 1900;
    apt.end.tm_hour = [d hourOfDay];
    apt.end.tm_min  = [d minuteOfHour];
    apt.end.tm_sec  = [d secondOfMinute];
  }
  
  len = pack_Appointment(&apt, buffer, sizeof(buffer));
  return [NSData dataWithBytes:buffer length:len];
}

static NSString *mkString(const char *_cstr) {
  if (_cstr == NULL)
    return nil;
  if (strlen(_cstr) == 0)
    return nil;

  return [[NSString alloc] initWithCString:_cstr];
}

/* ********** unpacking ********** */

static int unpack_Appointment(struct Appointment * a, unsigned char * buffer, int len) {
  int iflags;
  unsigned char * p2;
  unsigned long d;
  int j;
  int destlen;
  
  /* Note: There are possible timezone conversion problems related to the
     use of the begin, end, repeatEnd, and exception[] members of a
     struct Appointment. As they are kept in local (wall) time in
     struct tm's, the timezone of the Pilot is irrelevant, _assuming_
     that any UNIX program keeping time in time_t's converts them to
     the correct local time. If the Pilot is in a different timezone
     than the UNIX box, it may not be simple to deduce that correct
     (desired) timezone.
           
     The easiest solution is to keep apointments in struct tm's, and
     out of time_t's. Of course, this might not actually be a help if
     you are constantly darting across timezones and trying to keep
     appointments.
     -- KJA
  */
  
  destlen = 8;
  if (len<destlen)
    return 0;
  
  a->begin.tm_hour = get_byte(buffer);
  a->begin.tm_min = get_byte(buffer+1);
  a->begin.tm_sec = 0;
  d = (unsigned short int)get_short(buffer+4);
  a->begin.tm_year = (d >> 9) + 4;
  a->begin.tm_mon = ((d >> 5) & 15) - 1;
  a->begin.tm_mday = d & 31;
  a->begin.tm_isdst = -1;
  a->end = a->begin;

  a->end.tm_hour = get_byte(buffer+2);
  a->end.tm_min = get_byte(buffer+3);
	
  if(get_short(buffer) == 0xffff) {
    a->event = 1;
    a->begin.tm_hour = 0;
    a->begin.tm_min = 0;
    a->end.tm_hour = 0;
    a->end.tm_min = 0;
  } else {
    a->event = 0;
  }
  
  mktime(&a->begin);
  mktime(&a->end);
	  
  iflags = get_byte(buffer+6);

  /* buffer+7 is gapfil */
	
  p2 = (unsigned char*)buffer+8;
	
#define alarmFlag 64
#define repeatFlag 32
#define noteFlag 16
#define exceptFlag 8
#define descFlag 4
	
  if (iflags & alarmFlag) 
    {
      a->alarm = 1;
      a->advance = get_byte(p2);
      p2+=1;
      a->advanceUnits = get_byte(p2);
      p2+=1;
		
    }
  else {
    a->alarm = 0;
    a->advance = 0;
    a->advanceUnits = 0;
  }
		
  if (iflags & repeatFlag)
    {
      int i,	on;
      a->repeatType = (enum repeatTypes)get_byte(p2); p2+=2;
      d = (unsigned short int)get_short(p2); p2+=2;
      if(d==0xffff)
        a->repeatForever=1; /* repeatEnd is invalid */
      else {
        a->repeatEnd.tm_year = (d >> 9) + 4;
        a->repeatEnd.tm_mon = ((d >> 5) & 15) - 1;
        a->repeatEnd.tm_mday = d & 31;
        a->repeatEnd.tm_min = 0;
        a->repeatEnd.tm_hour = 0;
        a->repeatEnd.tm_sec = 0;
        a->repeatEnd.tm_isdst = -1;
        mktime(&a->repeatEnd);
        a->repeatForever = 0;
      }
      a->repeatFrequency = get_byte(p2); p2++;
      on = get_byte(p2); p2++;
      a->repeatDay = (enum DayOfMonthType)0;
      for(i=0;i<7;i++)
        a->repeatDays[i] = 0;
			
      if (a->repeatType == repeatMonthlyByDay)
        a->repeatDay = (enum DayOfMonthType)on;
      else if (a->repeatType == repeatWeekly)
        for(i=0;i<7;i++)
          a->repeatDays[i] = !!(on & (1<<i));
      a->repeatWeekstart = get_byte(p2); p2++;
      p2++;
    }
  else {
    int i;
    a->repeatType = (enum repeatTypes)0;
    a->repeatForever = 1; /* repeatEnd is invalid */
    a->repeatFrequency = 0;
    a->repeatDay = (enum DayOfMonthType)0;
    for(i=0;i<7;i++)
      a->repeatDays[i] = 0;
    a->repeatWeekstart = 0;
  }

  if (iflags & exceptFlag)
    {
      a->exceptions = get_short(p2);p2+=2;
      a->exception = malloc(sizeof(struct tm)*a->exceptions);
		
      for(j=0;j<a->exceptions;j++,p2+=2) {
        d = (unsigned short int)get_short(p2);
        a->exception[j].tm_year = (d >> 9) + 4;
        a->exception[j].tm_mon = ((d >> 5) & 15) - 1;
        a->exception[j].tm_mday = d & 31;
        a->exception[j].tm_hour = 0;
        a->exception[j].tm_min = 0;
        a->exception[j].tm_sec = 0;
        a->exception[j].tm_isdst = -1;
        mktime(&a->exception[j]);
      }
		
    }
  else  {
    a->exceptions = 0;
    a->exception = 0;
  }

  if (iflags & descFlag)
    {
      a->description = strdup(p2);
      p2 += strlen(p2) + 1;
    } else
      a->description = 0;

  if (iflags & noteFlag)
    {
      a->note = strdup(p2);
      p2 += strlen(p2) + 1;
    }
  else {
    a->note = 0;
  }
  return (p2-buffer);
}

- (int)unpackWithDatabase:(PPRecordDatabase *)_db data:(NSData *)_data {
  struct Appointment ap;
  NSTimeZone    *tz;
  unsigned char *start, *buffer;
  int           len;
  void          (*takeValue)(id,SEL,id,NSString*);
  SEL           takeValueSel;
  id            tmp;
  
  tz = [[_db syncContext] pilotTimeZone];
  
  buffer = (void *)[_data bytes];
  start  = buffer;
  len    = [_data length];
  
  takeValueSel = @selector(takeStoredValue:forKey:);
  takeValue = (void *)[self->eo methodForSelector:takeValueSel];
  
  unpack_Appointment(&ap, (void *)buffer, len);

  if (ap.event) {
    NSCalendarDate *date;
    takeValue(self->eo, takeValueSel, [NSNumber numberWithBool:YES], @"isEvent");
    
    date =
      [[NSCalendarDate alloc] initWithYear:(ap.begin.tm_year + 1900)
                              month:ap.begin.tm_mon + 1
                              day:ap.begin.tm_mday
                              hour:12
                              minute:0
                              second:0
                              timeZone:tz];
    takeValue(self->eo, takeValueSel, date, @"startDate");
    RELEASE(date);
    
    date =
      [[NSCalendarDate alloc] initWithYear:(ap.end.tm_year + 1900)
                              month:ap.end.tm_mon + 1
                              day:ap.end.tm_mday
                              hour:12
                              minute:0
                              second:0
                              timeZone:tz];
    takeValue(self->eo, takeValueSel, date, @"endDate");
    RELEASE(date); date = nil;
  }
  else {
    NSCalendarDate *date;
    
    takeValue(self->eo, takeValueSel, [NSNumber numberWithBool:NO], @"isEvent");
    
    date =
      [[NSCalendarDate alloc] initWithYear:(ap.begin.tm_year + 1900)
                              month:ap.begin.tm_mon + 1
                              day:ap.begin.tm_mday
                              hour:ap.begin.tm_hour
                              minute:ap.begin.tm_min
                              second:ap.begin.tm_sec
                              timeZone:tz];
    takeValue(self->eo, takeValueSel, date, @"startDate");
    RELEASE(date);
    
    date =
      [[NSCalendarDate alloc] initWithYear:(ap.end.tm_year + 1900)
                              month:ap.end.tm_mon + 1
                              day:ap.end.tm_mday
                              hour:ap.end.tm_hour
                              minute:ap.end.tm_min
                              second:ap.end.tm_sec
                              timeZone:tz];
    takeValue(self->eo, takeValueSel, date, @"endDate");
    RELEASE(date); date = nil;
  }

  if (ap.alarm) {
    NSTimeInterval adv;
    int advUnits;

    advUnits = ap.advanceUnits;
    adv      = ap.advance;

    switch (advUnits) {
      case 0: // minutes
        adv *= 60.0;
        break;
      case 1: // hours
        adv *= 3600.0;
        break;
      case 2: // days
        adv *= 3600.0 * 24.0;
        break;
    }
    
    takeValue(self->eo, takeValueSel, [NSNumber numberWithBool:YES],@"hasAlarm");
    takeValue(self->eo, takeValueSel,
              [NSNumber numberWithDouble:adv], @"alarmAdvance");
    takeValue(self->eo, takeValueSel,
              [NSNumber numberWithInt:advUnits],
              @"alarmAdvanceUnit");
  }
  else
    takeValue(self->eo, takeValueSel, [NSNumber numberWithBool:NO], @"hasAlarm");

  if ((ap.repeatType != 0) && !ap.repeatForever) {
    tmp =
      [[NSCalendarDate alloc] initWithYear:(ap.repeatEnd.tm_year + 1900)
                              month:ap.repeatEnd.tm_mon + 1
                              day:ap.repeatEnd.tm_mday
                              /* to prevent timezone conversation problems */
                              hour:/*ap.repeatEnd.tm_hour*/12
                              minute:/*ap.repeatEnd.tm_min*/0
                              second:/*ap.repeatEnd.tm_sec*/0
                              timeZone:tz];
    takeValue(self->eo, takeValueSel, tmp, @"cycleEndDate");
    RELEASE(tmp); tmp = nil;
  }
  else if ((ap.repeatType != 0) && ap.repeatForever) {
    takeValue(self->eo, takeValueSel, nil, @"cycleEndDate");
  }
  else
    tmp = nil;

  takeValue(self->eo, takeValueSel,
            [NSNumber numberWithInt:ap.repeatType], @"cycleType");
  
  switch (ap.repeatType) {
    case 0: /* none repetitive */
      break;
      
    case 1: /* daily */
    case 2: /* weekly */
    case 3: /* monthly by day */
    case 4: /* monthly by date */
    case 5: /* yearly */
      takeValue(self->eo, takeValueSel,
                [NSNumber numberWithInt:ap.repeatFrequency], @"cycleFrequency");
      takeValue(self->eo, takeValueSel,
                [NSNumber numberWithInt:ap.repeatDay], @"dayCycle");
      takeValue(self->eo, takeValueSel,
                [NSNumber numberWithInt:ap.repeatWeekstart], @"cycleWeekStart");
      takeValue(self->eo, takeValueSel,
                [NSNumber numberWithInt:ap.exceptions], @"cycleExceptions");
      { // cycleExceptions
        NSMutableArray *excepts = [NSMutableArray array];
        int            i;

        for (i = 0; i < ap.exceptions; i++) {
          tmp = [NSCalendarDate dateWithYear:(ap.exception[i].tm_year + 1900)
                                month:ap.exception[i].tm_mon + 1
                                day:ap.exception[i].tm_mday
                                hour:ap.exception[i].tm_hour
                                minute:ap.exception[i].tm_min
                                second:ap.exception[i].tm_sec
                                timeZone:tz];
          [excepts addObject:tmp];
          RELEASE(tmp); tmp = nil;
        }
        takeValue(self->eo, takeValueSel, excepts, @"cycleExceptionsArray");
      }
      break;
  }

  { // cycle days
    NSArray *cycleDays =
      [NSArray arrayWithObjects:
               [NSNumber numberWithBool:ap.repeatDays[0] ? YES : NO],
               [NSNumber numberWithBool:ap.repeatDays[1] ? YES : NO],
               [NSNumber numberWithBool:ap.repeatDays[2] ? YES : NO],
               [NSNumber numberWithBool:ap.repeatDays[3] ? YES : NO],
               [NSNumber numberWithBool:ap.repeatDays[4] ? YES : NO],
               [NSNumber numberWithBool:ap.repeatDays[5] ? YES : NO],
               [NSNumber numberWithBool:ap.repeatDays[6] ? YES : NO],
               nil];
    takeValue(self->eo, takeValueSel, cycleDays, @"cycleDays");
  }
  
  tmp = mkString(ap.description);
  takeValue(self->eo, takeValueSel, tmp, @"title");
  RELEASE(tmp);

  tmp = mkString(ap.note);
  takeValue(self->eo, takeValueSel, tmp, @"note");
  RELEASE(tmp);
  
  return 0;
}


@end /* PPDatebookPacker */
