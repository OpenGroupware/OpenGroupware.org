/*
  Copyright (C) 2002-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org.

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

#include "SxAppointmentMessageParser.h"
#include "common.h"
#include <NGMail/NGMimeMessageParser.h>
#include <SaxObjC/SaxObjectDecoder.h>
#include <SaxObjC/SaxXMLReader.h>
#include <SaxObjC/SaxXMLReaderFactory.h>
#include <NGiCal/iCalCalendar.h>
#include <NGiCal/iCalEvent.h>
#include <NGiCal/iCalPerson.h>
#include <NGiCal/iCalTrigger.h>
#include <NGiCal/iCalAlarm.h>
#include <NGiCal/iCalAttachment.h>

@implementation SxAppointmentMessageParser

static BOOL debugParser = NO;

static id<NSObject,SaxXMLReader> parser = nil;
static SaxObjectDecoder *sax = nil;

+ (id)parser {
  return [[[self alloc] init] autorelease];
}

/* parsing */

- (id)rsvpValue:(NSString *)_rsvp {
  if ([[_rsvp lowercaseString] isEqualToString:@"true"])
    return [NSNumber numberWithBool:YES];
  return [NSNumber numberWithBool:NO];
}

- (id)partStatusValue:(NSString *)_partStat {
  if ([_partStat hasPrefix:@"NEEDS"])
    return @"NEEDS-ACTION";
  return _partStat;
}

- (id)roleValue:(NSString *)_role {
  if ([_role hasPrefix:@"REQ-PART"])
    return @"REQ-PARTICIPANT";
  if ([_role hasPrefix:@"OPT-PART"])
    return @"OPT-PARTICIPANT";
  if ([_role hasPrefix:@"NON-PART"])
    return @"NON-PARTICIPANT";
  return _role;
}

/* join the parse results */
- (id)processPerson:(iCalPerson *)_person {
  NSMutableDictionary *record;
  id tmp;

  record = [NSMutableDictionary dictionaryWithCapacity:8];
  if ((tmp = [_person email]))    [record setObject:tmp forKey:@"email"];
  if ((tmp = [_person cn]))       [record setObject:tmp forKey:@"cn"];
  if ((tmp = [_person xuid]))     [record setObject:tmp forKey:@"xuid"];
  
  if ((tmp = [_person rsvp]))
    [record setObject:[self rsvpValue:tmp] forKey:@"rsvp"];
  
  if ((tmp = [_person partStat]))
    [record setObject:[self partStatusValue:tmp] forKey:@"partStat"];
  
  if ((tmp = [_person role]))
    [record setObject:[self roleValue:tmp] forKey:@"role"];
  
  return record;
}

- (id)processTrigger:(iCalTrigger *)_trigger {
  NSMutableDictionary *record;
  id tmp;

  record = [NSMutableDictionary dictionaryWithCapacity:2];
  if ((tmp = [_trigger valueType])) [record setObject:tmp forKey:@"valueType"];
  if ((tmp = [_trigger value]))     [record setObject:tmp forKey:@"value"];

  return record;
}

- (id)processAttachment:(iCalAttachment *)_attach {
  NSMutableDictionary *record;
  id tmp;

  record = [NSMutableDictionary dictionaryWithCapacity:2];
  if ((tmp = [_attach valueType])) [record setObject:tmp forKey:@"valueType"];
  if ((tmp = [_attach value]))     [record setObject:tmp forKey:@"value"];

  return record;
}

- (id)processAlarm:(iCalAlarm *)_alarm {
  NSMutableDictionary *record;
  id tmp;

  record = [NSMutableDictionary dictionaryWithCapacity:4];
  if ((tmp = [_alarm comment])) [record setObject:tmp forKey:@"comment"];
  if ((tmp = [_alarm action]))  [record setObject:tmp forKey:@"action"];
  if ((tmp = [_alarm trigger])) [record setObject:[self processTrigger:tmp]
                                        forKey:@"trigger"];
  if ((tmp = [_alarm attach]))  [record setObject:[self processAttachment:tmp]
                                        forKey:@"attachment"];

  return record;
}

// TODO: implement and use this
- (NSString *)toCSVValue:(id)_val {
  NSString        *source;

  if (_val == nil) return nil;
  if (![(source = [_val stringValue]) length]) return @"";

  return nil;
}

- (id)alarmsToCSV:(NSArray *)_alarms {
  /*
   * format:
   * action,comment,trigger-type,trigger-value,attach-type,attach-value
   *
   */
  NSMutableString *ms;
  unsigned        i, max;

  max = [_alarms count];
  if (!max) return @"";

  ms = [NSMutableString stringWithCapacity:32];

  for (i = 0; i < max; i++) {
    NSDictionary *alarm, *trigger, *attach;
    id tmp;
    
    alarm   = [_alarms objectAtIndex:i];
    trigger = [alarm objectForKey:@"trigger"];
    attach  = [alarm objectForKey:@"attachment"];

    tmp = [alarm objectForKey:@"action"];
    if ([tmp length]) [ms appendFormat:@"'%@'", tmp];
    else [ms appendString:@""];

    tmp = [alarm objectForKey:@"comment"];
    if ([tmp length]) [ms appendFormat:@",'%@'", tmp];
    else [ms appendString:@","];

    
    tmp = [trigger objectForKey:@"valueType"];
    if ([tmp length]) [ms appendFormat:@",'%@'", tmp];
    else [ms appendString:@","];
    
    tmp = [trigger objectForKey:@"value"];
    if ([tmp length]) [ms appendFormat:@",'%@'", tmp];
    else [ms appendString:@","];
    
    tmp = [attach objectForKey:@"valueType"];
    if ([tmp length]) [ms appendFormat:@",'%@'", tmp];
    else [ms appendString:@","];
    
    tmp = [attach objectForKey:@"value"];
    if ([tmp length]) [ms appendFormat:@",'%@'", tmp];
    else [ms appendString:@","];
    
    [ms appendString:@"\n"];
  }
  
  return ms;
}

- (id)processEvent:(iCalEvent *)_event withHeader:(NSDictionary *)_header {
  /*
    Header: content-class, importance[normal], priority[normal], from
    
    uid, summary, timestamp, created, lastModified, startDate
    accessClass, priority, alarms, organizer, attendees
    comment, sequence, location
    
    endDate, duration
  */
  NSMutableDictionary *record;
  id tmp;
  
  record = [NSMutableDictionary dictionaryWithCapacity:32];
  if ((tmp = [_event startDate])) [record setObject:tmp forKey:@"startDate"];
  if ((tmp = [_event endDate]))   [record setObject:tmp forKey:@"endDate"];
  if ((tmp = [_event uid]))       [record setObject:tmp forKey:@"uid"];
  if ((tmp = [_event summary]))   [record setObject:tmp forKey:@"title"];
  if ((tmp = [_event comment]))   [record setObject:tmp forKey:@"comment"];
  if ((tmp = [_event location]))  [record setObject:tmp forKey:@"location"];

  // do not add lastModified (done by command)
  
  if ((tmp = [_event created])) 
    [record setObject:tmp forKey:@"creationDate"];
  if ([(tmp = [_event accessClass]) isNotNull]) {
    /* map to sensitivity */
    tmp = [tmp uppercaseString];
    if ([tmp isEqualToString:@"PUBLIC"])
      tmp = [NSNumber numberWithInt:0];
    else if ([tmp isEqualToString:@"PRIVATE"])
      tmp = [NSNumber numberWithInt:2];
    else if ([tmp isEqualToString:@"CONFIDENTIAL"])
      tmp = [NSNumber numberWithInt:3];
    else if ([tmp isEqualToString:@"PERSONAL"]) /* non standard, OL value */
      tmp = [NSNumber numberWithInt:1];
    else {
      [self logWithFormat:@"ERROR: unknown iCalendar class: '%@'", tmp];
      tmp = nil;
    }
    
    if (tmp != nil) [record setObject:tmp forKey:@"sensitivity"];
  }
  if ((tmp = [_event priority])) 
    [record setObject:tmp forKey:@"priority"];
    
  // TODO: flatten organizer
  if ((tmp = [_event organizer])) 
    [record setObject:tmp forKey:@"creator"];
  
  // TODO: flatten attendees
  if ((tmp = [_event attendees])) {
    unsigned max = [tmp count];
    if (max) {
      NSMutableArray *persons = [NSMutableArray arrayWithCapacity:max];
      unsigned       i;
      id             one;
      for (i = 0; i < max; i++) {
        one = [self processPerson:[tmp objectAtIndex:i]];
        if (one)
          [persons addObject:one];
        else 
          [self logWithFormat:@"failed processing person: %@",
                [tmp objectAtIndex:i]];
      }
      [record setObject:persons forKey:@"participants"];
    }
    else
      [record setObject:[NSArray array] forKey:@"participants"];
  }
  
  // TODO: flatten alarms
  if ((tmp = [_event alarms])) {
    unsigned max = [tmp count];
    if (max) {
      NSMutableArray *alarms = [NSMutableArray arrayWithCapacity:max];
      unsigned       i;
      id             one;
      for (i = 0; i < max; i++) {
        one = [self processAlarm:[tmp objectAtIndex:i]];
        if (one)
          [alarms addObject:one];
        else 
          [self logWithFormat:@"failed processing alarm: %@",
                [tmp objectAtIndex:i]];
      }
      [record setObject:[self alarmsToCSV:alarms] forKey:@"evoReminder"];
    }
    else
      [record setObject:@"" forKey:@"evoReminder"];
  }

  // TODO: timestamp
  //if ((timestamp = [_event timestamp])) 
  //  [record setObject:tmp forKey:@"timestamp"];
  
  if ((tmp = [_event sequence])) {
    [record setObject:[NSNumber numberWithInt:[tmp intValue]] 
	    forKey:@"sequence"];
  }
  if ((tmp = [_event duration])) {
    // TODO: check whether duration is really int ...
    [record setObject:[NSNumber numberWithInt:[tmp intValue]] 
	    forKey:@"duration"];
  }
  
  /* fill in info from header */
  
  if ((tmp = [record objectForKey:@"importance"]) == nil) {
    if ((tmp = [_header objectForKey:@"importance"]))
      // TODO: "normal" => number
      [record setObject:tmp forKey:@"importance"];
    if ((tmp = [_header objectForKey:@"priority"]))
      // TODO: "normal" => number
      [record setObject:tmp forKey:@"priority"];
  }
  
  return record;
}

- (id)processCalendar:(iCalCalendar *)_cal andHeader:(NSDictionary *)_header {
  NSMutableArray *result;
  NSArray *a;
  int i, count;
  
  a      = [_cal events];
  count  = [a count];
  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    id object;

    object = [self processEvent:[a objectAtIndex:i] withHeader:_header];
    if (object == nil) {
      [self logWithFormat:@"could not process event: %@", [a objectAtIndex:i]];
      continue;
    }
    [result addObject:object];
  }
  return result;
}

/* iCal parsing */

- (BOOL)_ensureICalParser {
  if (parser == nil ) {
    SaxXMLReaderFactory *factory = 
      [SaxXMLReaderFactory standardXMLReaderFactory];
    parser = [[factory createXMLReaderForMimeType:@"text/calendar"] retain];
  }
  if (parser == nil) {
    [self logWithFormat:@"found no iCal parser !"];
    return NO;
  }
  if (sax == nil && parser != nil) {
    sax = [[SaxObjectDecoder alloc] initWithMappingNamed:@"NGiCal"];
    [parser setContentHandler:sax];
    [parser setErrorHandler:sax];
  }
  if (sax == nil) {
    [self logWithFormat:@"found no iCal object decoder !"];
    return NO;
  }
  return YES;
}

- (iCalCalendar *)_entourageHackParseICalData:(NSData *)_data {
  /*
    TODO: Entourage sometimes submits broken iCal entities where the
          vtimezone tag is not properly closed.
    Sample:
      METHOD:REQUEST
      BEGIN:VTIMEZONE
      UID:B9C2613D.A077F%x@x.x
      TZID:/softwarestudio.org/Olson_20011030_5/America/New_York
      BEGIN:VEVENT

    This method is far from optimized - heck, it's a hack anyway!
  */
  NSMutableData *patchedData;
  iCalCalendar  *cal;
  unsigned char buf[256];
  unsigned char *bytes, *vtStart, *p;
  unsigned len;
  
  if (_data == nil) return nil;
  if ((len = [_data length]) < 132) return nil;
  
  /* check for Entourage signature by scanning the first 255 bytes ... */
  [_data getBytes:buf length:(len < 255) ? len : 255];
  buf[(len < 255) ? len : 255] = '\0';
  if (strstr((char *)buf, "Microsoft") == NULL) return nil;
  if (strstr((char *)buf, "Entourage") == NULL) return nil;

  [self logWithFormat:
	  @"Note: got unparsable Entourage iCal data (len=%i), hack ...",
	  [_data length]];
  
  /* copy data to buffer for vtimezone searching ... */
  
  if ((bytes = malloc(len + 10)) == NULL) {
    fprintf(stderr, "ERROR(%s): could not allocate buffer (size=%i)!\n",
	    __PRETTY_FUNCTION__, len + 10);
    return nil;
  }
  [_data getBytes:bytes length:len];
  bytes[len] = '\0';
  
  /* now check for BEGIN:VTIMEZONE ... */
  
  if ((vtStart = (void *)strstr((char *)bytes, "BEGIN:VTIMEZONE")) == NULL) {
    /* does not contain a timezone */
    if (bytes) free(bytes);
    return nil;
  }
  
  /* skip begin, then check for END:VTIMEZONE */
  
  p = vtStart + 15; /* len of "BEGIN:VTIMEZONE" */
  if (strstr((char *)p, "END:VTIMEZONE")) {
    /* found END:VTIMEZONE, proper format ... */
    if (bytes) free(bytes);
    return nil;
  }
  
  [self logWithFormat:
	  @"Note:   yup, missing END:VTIMEZONE tag in iCal data, patch ..."];
  
  /* 
     patch: we insert a "END:VTIMEZONE\r\n"(len: 15) before the next 
     BEGIN: tag ... 
  */
  if ((p = (void *)strstr((char *)p, "BEGIN:")) == NULL) {
    [self logWithFormat:@"Note:   submitted data looks completely broken."];
    if (bytes) free(bytes);
    return nil;
  }
  
  patchedData = [NSMutableData dataWithCapacity:(len + 20)];
  [patchedData appendBytes:bytes length:(p - bytes)];
  [patchedData appendBytes:"END:VTIMEZONE\r\n" length:15];
  [patchedData appendBytes:p length:strlen((char *)p)];
  if (bytes) free(bytes);

  /* now try to parse a second time */
  
  [parser parseFromSource:patchedData];
  cal = [sax rootObject];
  
  return cal;
}
- (iCalCalendar *)parseICalData:(NSData *)_data {
  iCalCalendar *cal;
  
  if (![self _ensureICalParser])
    return nil;
  
  [parser parseFromSource:_data];
  cal = [sax rootObject];
  
  if (cal == nil && ([_data length] > 32))
    cal = [self _entourageHackParseICalData:_data];
    
  if (cal == nil) {
    [self logWithFormat:@"could not parse iCal content (%i bytes) with %@ !", 
            [_data length], parser];
    return nil;
  }
  
  /*
    Event Keys
      uid:      20030113T142130Z-17618-204-1-10@dogbert
      dtstamp:  20030113T142130Z
      dtstart:  20030116T060000
      dtend:    20030116T063000
      transp:   OPAQUE
      sequence: 2
      summary:  ssss
      location: dort
      class:    PUBLIC
      last-modified: 20030113T142133Z
      x-microsoft-cdo-busystatus:  BUSY
      x-microsoft-cdo-insttype:    0
      x-microsoft-cdo-alldayevent: FALSE
      x-microsoft-cdo-importance:  1
  */
  
  return cal;
}

/* MIME parsing */

- (BOOL)parser:(NGMimePartParser *)_parser
  parseRawBodyData:(NSData *)_data
  ofPart:(id<NGMimePart>)_part
{
  /* we keep the raw body */
  if (debugParser)
    [self logWithFormat:@"parser, keep data (len=%i)", [_data length]];
  [_part setBody:_data];
  return YES;
}

- (id)parseICalendarData:(NSData *)_data {
  NSAutoreleasePool *pool;
  id result;

  if (_data == nil) {
    [self debugWithFormat:@"got no iCalendar data ..."];
    return nil;
  }
  [self debugWithFormat:@"should parse %i bytes ..", [_data length]];
  
  pool = [[NSAutoreleasePool alloc] init];
  {
    iCalCalendar *cal;
    
    cal    = [self parseICalData:_data];
    result = [self processCalendar:cal andHeader:nil];
  
    result = [result retain];
  }
  [pool release];
  return [result autorelease];
}

- (id)parseMessageData:(NSData *)_data {
  /* parse a MIME message containing iCalendar data */
  NGMimeMessageParser *mimeParser;
  NSAutoreleasePool   *pool;
  NSMutableDictionary *header = nil;
  iCalCalendar        *cal    = nil;
  NSData *iCalData;
  id part;
  id result;

  pool = [[NSAutoreleasePool alloc] init];
  
  if (debugParser)
    [self logWithFormat:@"should parse %i bytes ..", [_data length]];

  /* Evolution PUT's a MIME message containing an iCal file */
  mimeParser = [[NGMimeMessageParser alloc] init];
  [mimeParser setDelegate:self];
  part = [[[mimeParser parsePartFromData:_data] retain] autorelease];
  [mimeParser release]; mimeParser = nil;
  
  if (part == nil) {
    [self logWithFormat:@"ERROR: could not parse MIME structure."];
    [pool release];
    return nil;
  }
  
  /*
    Evolution gives some fields as headers:
      content-class: urn:content-classes:appointment
      content-type:  <NGMimeType: text/calendar; charset=utf-8>
      date:          "13 Jan 2003 16:19:18 +0100"
      from:          "\"Helge Hess\" <hh@skyrix.com>"
      importance:    normal
      priority:      normal
      subject:       test
    Also contained in iCal:
      subject (vevent summary)
  */
  
  header = [NSMutableDictionary dictionaryWithCapacity:16];
  {
    NSEnumerator *e;
    NSString *key;
    
    e = [part headerFieldNames];
    while ((key = [e nextObject])) {
      NSString *value;
      
      // TODO: check all values !
      value = [[part valuesOfHeaderFieldWithName:key] nextObject];
      if (value) [header setObject:value forKey:key];
    }
  }
  
  iCalData = [part body];
  if ([iCalData length] == 0) {
    /* Note: only seems to work with the simple-http-parser ! */
    [self logWithFormat:@"ERROR: submitted part contains no data!"];
    result = nil;
  }
  else {
    /* parse the body */
    cal    = [self parseICalData:iCalData];
    result = [self processCalendar:cal andHeader:header];
  }
  
  result = [result retain];
  [pool release];
  return [result autorelease];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugParser;
}

@end /* SxAppointmentMessageParser */
