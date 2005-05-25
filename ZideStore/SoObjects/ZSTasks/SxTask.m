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

#include "SxTask.h"
#include "SxTaskRenderer.h"
#include "SxTaskStatus.h"
#include "SxDavTaskCreate.h"
#include "SxDavTaskChange.h"
#include <ZSFrontend/NSObject+ExValues.h>
#include <ZSBackend/SxTaskManager.h>
#include <ZSBackend/SxContactManager.h>
#include "common.h"
#include <GDLAccess/GDLAccess.h>
#include <SaxObjC/SaxObjC.h>
#include <NGiCal/NGiCal.h>

@implementation SxTask

- (id)initWithJob:(id)_job inFolder:(SxTaskFolder *)_folder {
  return [self initWithEO:_job inFolder:_folder];
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

/* debug */

#if DEBUG_KVC
- (id)valueForKey:(NSString *)_key {
  id v;

  if ((v = [super valueForKey:_key]) == nil)
    [self logWithFormat:@"got no value for %@", _key];
  return v;
}
#endif

/* common */

/* WebDAV */

- (int)zlGenerationCount {
  return [[[self object] valueForKey:@"objectVersion"] intValue];
}

- (NSString *)davDisplayName {
  return [[self object] valueForKey:@"name"];
}

- (NSDate *)davLastModified {
  /* TODO: use JobHistory to get that ? */
  return [NSDate date];
}

- (NSString *)outlookMessageClass {
  return @"IPM.Task";
}


/* mail->task mappings */

- (void)fetchCreatorForTask:(id)_task inContext:(id)_ctx {
  SxContactManager *cm;
  NSNumber      *creatorId;
  EOKeyGlobalID *gid;
  
  if ((creatorId = [_task valueForKey:@"creatorId"]) == nil)
    return;

  cm = [SxContactManager managerWithContext:
			   [self commandContextInContext:_ctx]];
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
		       keys:&creatorId keyCount:1 zone:NULL];
  
  gid = [cm accountForGlobalID:gid];
  if (gid != nil)
    [_task takeValue:gid forKey:@"creator"];
}

- (NSString *)fromEMail {
  return [[[self object] valueForKey:@"creator"] valueForKey:@"email1"];
}
- (NSString *)fromName {
  NSString *name, *tmp;
  id obj;
  
  obj = [[self object] valueForKey:@"creator"];
  name = [obj valueForKey:@"name"];
  tmp  = [obj valueForKey:@"firstname"];
  if (tmp) {
    name = name
      ? [NSString stringWithFormat:@"%@ %@", tmp, name]
      : tmp;
  }
  else {
    if (name == nil) 
      name = [[[self object] valueForKey:@"creatorId"] stringValue];
  }
  return name;
}
- (NSString *)ownerName {
  return [self fromName];
  /*    @"Bjoern Stierand"; */
}

- (int)sensitivity { // same as access_class, only as int, see NOTES
  // TODO: properly implement
  return 0; // 0 is public
}

- (int)priority {
  // see SxDavTaskAction -getPriority for details
  int skyPriority;
  
  skyPriority = [[[self object] valueForKey:@"priority"] intValue];
  if (skyPriority == 0)
    // no priority
    return 0; // normal
  
  if (skyPriority < 3)
    return 1; // high
  if (skyPriority > 3)
    return 2; // low
  return 0; // normal
}
- (id)importance { // maybe same as priority ?
  // see SxDavTaskAction -getPriority for details
  id  userAgent;
  int pri;  
  pri = [self priority];

  userAgent =
    [[[[[WOApplication application] context]
                       request] clientCapabilities] userAgentType];

  if (userAgent) {
    if ([(NSString *)userAgent hasPrefix:@"Evolution"]) {
      if (pri == 1)
        return @"high";
      else if (pri == 2)
        return @"low";
      return @"normal";
    }
  }
  
  if (pri == 1) // high
    pri = 2;
  else if (pri == 2) // low
    pri = 0;
  else // normal
    pri = 1;
  return [NSNumber numberWithInt:pri];
}

- (int)actualWorkInMinutes {
  return [[[self object] valueForKey:@"actualWork"] intValue];
}
- (int)totalWorkInMinutes {
  return [[[self object] valueForKey:@"totalWork"] intValue];
}

- (int)isTeamTask {
  return [[[self object] valueForKey:@"isTeamJob"] intValue];
}

- (id)taskCompletion {
  SxTaskStatus *status;
  status = [SxTaskStatus statusWithSxObject:[self object]];
  return [[NSNumber numberWithFloat:[status completion]] exDavFloatValue];
}

- (id)taskStatus {
  SxTaskStatus *status;
  status = [SxTaskStatus statusWithSxObject:[self object]];
  return [[NSNumber numberWithInt:[status status]] exDavIntValue];
}

- (NSString *)subject {
  return [[self object] valueForKey:@"name"];
}

- (NSString *)textdescription {
  return [[self object] valueForKey:@"comment"];
}

- (NSString *)keywords {
  /* Note this need to be tagged as a string array for Connector 2.0.2 */
  NSString *kw;
  
  kw = [[self object] valueForKey:@"keywords"];
  return [kw exDavStringArrayValue];
}

- (id)taskCommonStart {
  return [[[self object] valueForKey:@"startDate"] exDavDateValue];
}

- (id)taskCommonEnd {
  return [[[self object] valueForKey:@"endDate"] exDavDateValue];
}

- (id)taskCompletionDate {

  if ([[[self object] valueForKey:@"jobStatus"] isEqualToString:@"25_done"]) {
    NSDate *d;

    // It seems we need to give some date, to make Evo happy. Evo seems to
    // decide the task-completion in the joblists solely on the date.
    if ((d = [[self object] valueForKey:@"completionDate"]) == nil)
      d = [NSDate date];

    return [d exDavDateValue];
  }
  return nil;
}

- (id)date {
  // ??
  return [self taskCommonStart];
}

- (id)sequence {
  return [[self object] valueForKey:@"sequence"];
}

/* editing jobs */

- (NSException *)updateJobWithProperties:(NSDictionary *)_props 
  inContext:(id)_ctx
{
  SxDavTaskChange *updater;

  updater = [[[SxDavTaskChange alloc] 
               initWithName:[self nameInContainer]
	       properties:_props
	       forTask:self] autorelease];
  return [updater runInContext:_ctx];
}

/* fetching */

- (SxTaskManager *)taskManagerInContext:(id)_ctx {
  SxTaskManager *m;
  if (_ctx == nil) _ctx = [[WOApplication application] context];
  if ((m = [[self container] taskManagerInContext:_ctx]) == nil) 
    [self logWithFormat:@"WARNING: got no task manager !"];
  return m;
}

/* operations */

- (id)davCreateObject:(NSString *)_name properties:(NSDictionary *)_props 
  inContext:(id)_ctx
{
  SxDavTaskCreate *creator;

  creator = [[[SxDavTaskCreate alloc] 
               initWithName:_name properties:_props forTask:self] autorelease];
  return [creator runInContext:_ctx];
}

- (NSException *)davSetProperties:(NSDictionary *)_setProps
  removePropertiesNamed:(NSArray *)_delProps
  inContext:(id)_ctx
{
  NSMutableDictionary *md;
  NSEnumerator *e;
  NSString     *k;

  if ([self isNew]) {
    return [self davCreateObject:[self nameInContainer] properties:_setProps
		 inContext:_ctx];
  }
    
  md = [[_setProps mutableCopy] autorelease];
    
  /* turn delete-props into empty strings */
  e = [_delProps objectEnumerator];
  while ((k = [e nextObject]))
    [md setObject:@"" forKey:k];
    
  /* remove read-only things */
  [md removeObjectForKey:@"date"];
  [md removeObjectForKey:@"davUid"];
  [md removeObjectForKey:@"locationURL"];
  [md removeObjectForKey:@"outlookMessageClass"];
  
  return [self updateJobWithProperties:md inContext:_ctx];
}

/* iCalendar representation */

- (NSString *)iCalString {
  SxTaskRenderer *renderer;
  NSString *ical;
  
  renderer = [[SxTaskRenderer alloc] init];
  ical = [renderer vCalendarStringForTask:self];
  [renderer release]; renderer = nil;
  
  return ical;
}

/* iCalendar parsing / putting */

static id<NSObject,SaxXMLReader> parser = nil;
static SaxObjectDecoder *sax = nil;

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

- (id)putICalendarToDo:(iCalToDo *)_todo inContext:(id)_ctx {
  [self logWithFormat:@"TODO: change task: %@", _todo];
  
  return [NSException exceptionWithHTTPStatus:501 /* Not Implemented */
                      reason:@"VTODO PUT not yet implemented"];
  
}

- (id)parseICalendarData:(NSData *)_data {
  iCalCalendar *cal;
  NSArray      *todos;

  /* parse calendar data */
  
  if (![self _ensureICalParser]) {
    return [NSException exceptionWithHTTPStatus:500 /* Server Error */
                        reason:@"failed to create iCalendar parser"];
  }
  [parser parseFromSource:_data];
  if ((cal = [sax rootObject]) == nil) { // TODO: different error code?
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"Could not parse iCalendar content of PUT"];
  }
  
  /* check calendar data for a single vtodo */
  
  todos = [cal todos];
  if ([todos count] == 0) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"iCalendar content of PUT contained no VTODO"];
  }
  if ([todos count] > 1) {
    // TODO: for CalDAV we could support multiple vtodo's in one (repetitions)
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:
			  @"iCalendar content of PUT contained more than one "
			  @"VTODO"];
  }
  return [todos objectAtIndex:0];
}

- (id)putICalendarAction:(id)_ctx {
  /* request body contains a text/calendar */
  NSData   *content;
  iCalToDo *todo;
  
  /* get content */
  
  content = [[(WOContext *)_ctx request] content];
  if ([content length] == 0) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"got empty PUT body"];
  }
  
  /* parse */

  todo = [self parseICalendarData:content];
  if ([todo isKindOfClass:[NSException class]])
    return todo;
  
  /* perform changes */
  return [self putICalendarToDo:todo inContext:_ctx];
}

/* actions */

- (id)GETAction:(WOContext *)_ctx {
  //[self logWithFormat:@"render EO: %@", [self object]];
  WOResponse *r;
  NSString   *ical, *etag;
  
  /* return proper code for missing EOs */
  
  if ([self objectInContext:_ctx] == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
                        reason:@"did not find EO"];
  }
  
  /* generate iCalendar */
  
  if ((ical = [self iCalString]) == nil) {
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"could not render task as iCalendar"];
  }
  
  /* setup response */
  
  r  = [(WOContext *)_ctx response];
  [r setContentEncoding:NSUTF8StringEncoding];
  [r setHeader:@"text/calendar; charset=utf-8" forKey:@"content-type"];
  [r appendContentString:ical];
  
  if ((etag = [self davEntityTag]) != nil)
    [r setHeader:etag forKey:@"etag"];
  
  return r;
}

- (id)PUTAction:(WOContext *)_ctx {
  NSException *error;
  NSString *ctype;
  
  if ((error = [self matchesRequestConditionInContext:_ctx]) != nil)
    return error;

  ctype = [[(WOContext *)_ctx request] headerForKey:@"content-type"];
  if ([ctype hasPrefix:@"text/calendar"])
    return [self putICalendarAction:_ctx];
  
  if ([ctype length] == 0) {
    // TODO: which clients do that? (eg when editing in Cadaver)
    // TODO: move this code to NSData category (or better WORequest?)
    // DUP in SxAppointment.m
    static NSData *iCalSignature = nil;
    NSData *data;

    if (iCalSignature == nil) {
      iCalSignature = [[NSData alloc] initWithBytes:@"BEGIN:VCALENDAR" 
                                      length:15];
    }
    
    [self logWithFormat:@"Note: client submitted no content-type!"];
    data = [[(WOContext *)_ctx request] content];
    if ([data hasPrefix:iCalSignature]) {
      [self logWithFormat:
              @"request seems to contain iCalendar data, try that."];
    }
    return [self putICalendarAction:_ctx];
  }
  
  [self logWithFormat:@"Note: does not accept PUTs of type: '%@'", ctype];
  return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                      reason:@"invalid format for PUT (not a text/calendar)"];
}

/* fetch EO object */

- (id)objectInContext:(id)_ctx {
  if (self->eo) 
    return self->eo;
  self ->eo = [[[self taskManagerInContext:_ctx] 
                      eoForPrimaryKey:[self primaryKey]] retain];
  return self->eo;
}

/* delete action */

- (id)primaryDeleteObjectInContext:(id)_ctx {
  // TODO: who calls this? The SOPE WebDAV layer?
  NSException *error;
  
  error = [[self taskManagerInContext:_ctx] 
                 deleteRecordWithPrimaryKey:[self primaryKey]];
  return error;
}

/* DAV default attributes (allprop queries by ZideLook ;-) */

- (NSArray *)defaultWebDAVPropertyNamesInContext:(id)_ctx {
  static NSMutableArray *defNames = nil;
  if (defNames == nil) {
    defNames = 
      [[[self propertySetNamed:@"DefaultTaskProperties"] allObjects] copy];
  }
  return defNames;
}

/* properties set in Apache */

- (NSString *)travelDistance {
  return [[self object] valueForKey:@"kilometers"];
}

- (NSString *)associatedContacts {
  return [[self object] valueForKey:@"associatedContacts"];
}
- (NSString *)associatedCompanies {
  return [[self object] valueForKey:@"associatedCompanies"];
}
- (NSString *)accountingInfo {
  return [[self object] valueForKey:@"accountingInfo"];
}

/* permissions */

- (BOOL)isDeletionAllowed {
  // TODO: check actual permissions
  return YES;
}

/* change operations */

- (id)createWithChanges:(NSMutableDictionary *)_record log:(NSString *)_log
  inContext:(id)_ctx
{
  LSCommandContext *cmdctx;
  NSException      *error = nil;
  id               object = nil;
  
  if ([_record count] == 0) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
			reason:@"missing properties for apt to create !"];
  }
  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    return [NSException exceptionWithHTTPStatus:500
			reason:@"got no SKYRiX context !"];
  }

  /* add log */
  
  if ([_log length] > 0)
    [_record setObject:_log forKey:@"logText"];
  
  /* execute */
  
  error = nil;
  NS_DURING {
    object = [cmdctx runCommand:[[self class] newCommandName]
                     arguments:_record];
    
    if (![cmdctx commit]) {
      error = [[NSException exceptionWithHTTPStatus:409 /* Conflict */
			    reason:@"could not commit transaction !"] retain];
    }
  }
  NS_HANDLER {
    error = [localException retain];
  }
  NS_ENDHANDLER;
  error = [error autorelease];

  /* handle errors and return */
  
  if (error) {
    [cmdctx rollback];
    return error;
  }
  return object;
}

@end /* SxTask */
