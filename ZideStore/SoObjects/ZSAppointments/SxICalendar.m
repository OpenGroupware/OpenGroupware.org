/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#include "SxICalendar.h"
#include "SxAppointmentFolder.h"
#include "common.h"
#include <ZSBackend/SxAptManager.h>
#include <SaxObjC/SaxObjectDecoder.h>
#include <SaxObjC/SaxXMLReader.h>
#include <SaxObjC/SaxXMLReaderFactory.h>
#include <NGiCal/NGiCal.h>
#include <EOControl/EOKeyGlobalID.h>

// TODO: fetch objects using parent-folder! This way it will work with any
//       kind of folder (eg Overview does not work in the moment ...)

@interface SxICalendar(ICalPUT)

- (void)collectDataFromICalObject:(id)_iCal
  inContext:(id)_ctx
  toData:(NSMutableDictionary *)_data;

@end /* SxICalendar(ICalPUT) */

@implementation SxICalendar

static BOOL debugZSICal = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugZSICal = [ud boolForKey:@"ZLDebugICal"];
}

- (void)dealloc {
  [self->group release];
  [super dealloc];
}

/* accessors */

- (void)setGroup:(NSString *)_group {
  ASSIGNCOPY(self->group, _group);
}
- (NSString *)group {
  return self->group;
}

- (id)parentFolder {
  return self->container;
}

/* backend */

- (SxAptManager *)aptManagerInContext:(id)_ctx {
  return [SxAptManager managerWithContext:[self commandContextInContext:_ctx]];
}

- (BOOL)isPublish {
  /* 
     a publish prefix signals that objects will only be added or modified,
     never deleted.
  */
  
  return [[[self nameInContainer] lowercaseString]
                 hasPrefix:@"publish"];
}
- (SxAptSetIdentifier *)currentAptSet {
  return [self isPublish] 
    ? nil // only publish available here
    : [SxAptSetIdentifier aptSetForGroup:[self group]];
}

/* fetching */

- (NSEnumerator *)fetchDatesInContext:(id)_ctx {
  id           folder;
  SxAptManager *manager;
  NSArray      *dates;
  SxAptSetIdentifier *sid;
  
  folder  = [self parentFolder];
  manager = [self aptManagerInContext:_ctx];
  
  sid   = [self currentAptSet];
  dates = [manager gidsOfAppointmentSet:sid];
  
  return [manager pkeysAndModDatesAndICalsForGlobalIDs:dates];
}

/* methods */

- (id)GETAction:(id)_ctx {
  NSEnumerator *dateEnum;
  WOResponse   *r;
  id           date;

  dateEnum = [self fetchDatesInContext:_ctx];
  r        = [(WOContext *)_ctx response];

  if (dateEnum == nil) {
    return [NSException exceptionWithHTTPStatus:500 /* server error */
                        reason:@"could not fetch iCals"];
  }
  
  [r setHeader:@"text/calendar" forKey:@"content-type"];
  [r appendContentString:@"BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nPRODID:"];
  [r appendContentString:OGo_ZS_PRODID];
  [r appendContentString:@"\r\nVERSION:2.0\r\n"];
  
  while ((date = [dateEnum nextObject]) != nil) {
    NSString *ical;
    
    ical = [date objectForKey:@"iCalData"];
    [r appendContentString:ical];
  }
  
  [r appendContentString:@"END:VCALENDAR"];

  return r;
}

/* PUT */

static id<NSObject,SaxXMLReader> parser = nil;
static SaxObjectDecoder          *sax   = nil;

- (id)parseICalDataInContext:(id)_ctx {
  id request;
  id content;
  id object;
  LSCommandContext *cmdctx;
  NSString   *tzId;
  NSTimeZone *tz;

  if (parser == nil) {
    id factory = [SaxXMLReaderFactory standardXMLReaderFactory];
    parser = [[factory createXMLReaderForMimeType:@"text/calendar"] retain];
    sax    = [[SaxObjectDecoder alloc] initWithMappingNamed:@"NGiCal"];
    [parser setContentHandler:sax];
    [parser setErrorHandler:sax];
  }
  if (parser == nil) {
    NSLog(@"%s: WARNING! failed to init parser for type text/calendar",
          __PRETTY_FUNCTION__);
  }
  else if (sax == nil) {
    NSLog(@"%s: WARNING! failed to init object decoder for mapping NGiCal",
          __PRETTY_FUNCTION__);
  }

  cmdctx = [self commandContextInContext:_ctx];
  tzId   = [[cmdctx userDefaults] stringForKey:@"timezone"];
  tz     = ([tzId length])
    ? [NSTimeZone timeZoneWithAbbreviation:tzId] : nil;

  if (debugZSICal) {
    [self logWithFormat:@"parsing PUT-request with parser: %@ handler: %@ "
          @"user timeZone: %@",
          parser, sax, tz ? [tz abbreviation] : @"not specified"];
  }
  [iCalObject setICalDefaultTimeZone:tz];
  
  request = [(WOContext *)_ctx request];
  content = [request content];
  [parser parseFromSource:content];
  object = [sax rootObject];
  if (object == nil) {
    NSLog(@"%s: failed parsing PUT-request content", __PRETTY_FUNCTION__);
    return nil;
  }
  return object;
}

- (void)collectDataFromICalCalendar:(iCalCalendar *)_iCal
  inContext:(id)_ctx
  toData:(NSMutableDictionary *)_data
{
  NSEnumerator *e;
  id           one;
  
  e = [_iCal objectEnumerator];
  while ((one = [e nextObject])) 
    [self collectDataFromICalObject:one inContext:_ctx toData:_data];
}

- (void)collectDataFromICalEvent:(iCalEvent *)_event
  inContext:(id)_ctx
  toData:(NSMutableDictionary *)_data  
{
  NSMutableArray *events;
  
  if ((events = [_data objectForKey:@"events"]) == nil) {
    events = [NSMutableArray arrayWithCapacity:8];
    [_data setObject:events forKey:@"events"];
  }
  [events addObject:_event];
}

- (void)collectDataFromICalToDo:(iCalToDo *)_todo
  inContext:(id)_ctx
  toData:(NSMutableDictionary *)_data  
{
  NSMutableArray *todos;
  
  if ((todos = [_data objectForKey:@"todos"]) == nil) {
    todos = [NSMutableArray arrayWithCapacity:8];
    [_data setObject:todos forKey:@"todos"];
  }
  [todos addObject:_todo];
}

- (void)collectDataFromICalDict:(NSDictionary *)_dict
  inContext:(id)_ctx
  toData:(NSMutableDictionary *)_data  
{
  NSEnumerator *e;
  id           one;
  
  e = [[_dict objectForKey:@"subcomponents"] objectEnumerator];
  while ((one = [e nextObject]))
    [self collectDataFromICalObject:one inContext:_ctx toData:_data];
}


- (void)collectDataFromICalObject:(id)_iCal
  inContext:(id)_ctx
  toData:(NSMutableDictionary *)_data
{
  if ([_iCal isKindOfClass:[iCalCalendar class]]) {
    [self collectDataFromICalCalendar:_iCal inContext:_ctx toData:_data];
  }
  else if ([_iCal isKindOfClass:[iCalEvent class]]) {
    [self collectDataFromICalEvent:_iCal inContext:_ctx toData:_data];
  }
  else if ([_iCal isKindOfClass:[iCalToDo class]]) {
    [self collectDataFromICalToDo:_iCal inContext:_ctx toData:_data];
  }
  else if ([_iCal isKindOfClass:[NSDictionary class]]) {
    [self collectDataFromICalDict:_iCal inContext:_ctx toData:_data];
  }
  else {
    [self logWithFormat:
	    @"%s: unknown/unhandled iCal object class: %@",
            __PRETTY_FUNCTION__, NSStringFromClass([_iCal class])];
  }
}

- (id)PUTAction:(id)_ctx {
  NSMutableDictionary *dict;
  WOResponse *r;
  id object;
  id error = nil;

  if ((object = [self parseICalDataInContext:_ctx]) == nil) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"failed parsing PUT-request content"];
  }
  
  dict = [NSMutableDictionary dictionaryWithCapacity:4];
  [self collectDataFromICalObject:object inContext:_ctx toData:dict];
  error =  [[self aptManagerInContext:_ctx]
                  putVEvents:[dict objectForKey:@"events"]
                  inAptSet:[self currentAptSet]];
  if (error) {
    [self logWithFormat:@"ERROR: PUT failed: %@", error];
    return error;
  }
  
  r = [(WOContext *)_ctx response];
  [r setStatus:200 /* OK */];
  return r;
}

/* bulk queries */

- (NSArray *)extractBulkGlobalIDs:(EOFetchSpecification *)_fs {
  /* first, morph query URLs into EOGlobalIDs ... */
  NSMutableArray *pkeys;
  NSArray  *davKeys;
  unsigned i, count;
  NSString *entityName;
  
  davKeys = [_fs davBulkTargetKeys];
  if ((count = [davKeys count]) == 0)
    return [NSArray array];
  
  entityName = @"Date";
  pkeys = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString *davKey = [davKeys objectAtIndex:i];
    EOKeyGlobalID *gid;
    NSNumber *pkey;
    int      pkeyInt;
    
    davKey = [[davKeys objectAtIndex:i] stringByDeletingPathExtension];
    if ([davKey rangeOfString:@"/"].length > 0) {
      [self logWithFormat:@"ERROR: cannot process complex bulk key: '%@'",
            davKey];
      continue;
    }
    
    if ((pkeyInt = [davKey intValue]) == 0) {
      [self logWithFormat:@"ERROR: could not process non-int key: '%@'",
            davKey];
      continue;
    }
    else if (pkeyInt < 8000)
      [self logWithFormat:@"WARNING: got weird bulk-key (<8000): '%@'",
            davKey];
    
    pkey = [NSNumber numberWithInt:pkeyInt];
    gid  = [EOKeyGlobalID globalIDWithEntityName:entityName 
			  keys:&pkey keyCount:1 zone:NULL];
    [pkeys addObject:gid];
  }
  return pkeys;
}

- (id)performWebDAVBulkQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  NSArray      *gids;
  WOResponse   *r;
  NSEnumerator *e;
  id           iCal;

  gids = [self extractBulkGlobalIDs:_fs];
  e    = [[self aptManagerInContext:_ctx]
                pkeysAndModDatesAndICalsForGlobalIDs:gids];

  if (e == nil) {
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"could not fetch iCals"];
  }
  r = [(WOContext *)_ctx response];
      
  [r setHeader:@"text/calendar" forKey:@"content-type"];
  [r appendContentString:@"BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nPRODID:"];
  [r appendContentString:OGo_ZS_PRODID];
  [r appendContentString:@"\r\nVERSION:2.0\r\n"];
  
  while ((iCal = [e nextObject]) != nil)
    [r appendContentString:[iCal objectForKey:@"iCalData"]];
  
  [r appendContentString:@"END:VCALENDAR"];

  return r;
}

@end /* SxICalendar */
