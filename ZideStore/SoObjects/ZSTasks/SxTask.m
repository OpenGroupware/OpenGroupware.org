/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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
#include <ZSBackend/NSString+rtf.h>
#include <ZSBackend/SxTaskManager.h>
#include <ZSBackend/SxContactManager.h>
#include "common.h"

#include <NGMail/NGMimeMessageParser.h> // for comments from Evolution
#include <GDLAccess/GDLAccess.h>

@implementation SxTask

static BOOL debugParser = YES;

+ (NSString *)primaryKeyName {
  /* need to overwrite that method for SxObject */
  return @"jobId";
}
+ (NSString *)entityName {
  return @"Job";
}
+ (NSString *)getCommandName {
  return @"job::get";
}
+ (NSString *)newCommandName {
  return @"job::new";
}
+ (NSString *)setCommandName {
  return @"job::set";
}

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

- (NSString *)hmSpecialKey {
  return nil;
}

- (NSString *)davDisplayName {
  return [[self object] valueForKey:@"name"];
}

- (NSDate *)davLastModified {
  /* TODO: use JobHistory to get that ? */
  return [NSDate date];
}

- (void)setOutlookMessageClass:(NSString *)_mc {
  if (![_mc isEqualToString:@"IPM.Task"])
    [self logWithFormat:@"tried to assign invalid message class: %@", _mc];
}
- (NSString *)outlookMessageClass {
  return @"IPM.Task";
}

- (int)cdoAction {
  /* MAPI 10800003 */
  return 1280;
  /* whatever this is and means ... (taken from Apache), also 272 */
}
- (NSString *)mapiID_8112_int {
  return @"2";
}
- (NSString *)mapiID_8113_int {
  return @"1";
}
- (NSString *)mapiID_8123_int {
  return @"-1000";
}
- (NSString *)mapiID_8124_bool {
  return @"0";
}
- (NSString *)mapiID_8129_int {
  return @"0";
}
- (NSString *)mapiID_812A_int {
  return @"0";
}
- (NSString *)mapiID_812C_bool {
  return @"1";
}
- (NSString *)cdoIsRecurring {
  return @"0";
}
- (NSString *)cdoItemIsComplete {
  id jobStatus;

  jobStatus = [[self object] valueForKey:@"jobStatus"];
  if (([jobStatus isEqualToString:@"25_done"]) ||
      ([jobStatus isEqualToString:@"30_archived"]))
    return @"1";
  return @"0";
}

// TODO: cdoEntryID
// TODO: cdoInstanceKey
// TODO: cdoObjectType, cdoSearchKey
// mapiID_8108000B
// mapiID_81050040 (taskCommonEnd)

/* mail->task mappings */

- (void)setThreadTopic:(NSString *)_tp {
  [self takeValue:_tp forKey:@"subject"];
}
- (NSString *)threadTopic {
  /* subject is created as 'threadTopic' */
  return [self valueForKey:@"subject"];
}

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

- (NSString *)sentRepresentingEmailAddress {
  return @"";
}
- (NSString *)senderEmailAddress {
  return [self sentRepresentingEmailAddress];
}

- (id)cdoTrustSender {
  return @"1";
}

- (id)cdoMessageFlags {
  return @"3"; // READ, UNMODIFIED
}
- (id)cdoMessageStatus {
  return @"0";
}

- (id)normalizedSubject {
  return [self valueForKey:@"subject"];
}

- (id)mapiID_00008586 {
  return @""; // ??
}

- (int)sensitivity { // same as access_class, only as int, see NOTES
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
- (int)cdoPriority {
  // see SxDavTaskAction -getPriority for details
  int pri;
  
  pri = [self priority];
  if (pri == 2)
    pri = -1;
  return pri;
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
    
  /* what is mapi0x0000811c ? */
  return [self updateJobWithProperties:md inContext:_ctx];
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

- (id)putEvoComment:(id)_ctx {
  /* 
     After Evo did a PROPPATCH, it does a PUT with content-type
     message/rfc822. The message has the comment as the body and 
     these relevant headers:
       content-class: urn:content-classes:task
       Subject:       test 3
       Thread-Topic:  test 3
       Priority:      normal
       Importance:    normal
       From:          "Helge Hess" <hh@skyrix.com>
  */
  NGMimeMessageParser *mimeParser;
  WOResponse *r = [_ctx response];
  id part;
  NSString *comment;
  
  part = [[_ctx request] content];
  if (debugParser)
    [self logWithFormat:@"should parse %i bytes ..", [part length]];
  
  if ([part length] == 0) {
    [self logWithFormat:@"missing content for PUT ..."];
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:
                          @"no content in task-comment PUT !"];
  }
  
  /* Evolution PUT's a MIME message containing an iCal file */
  mimeParser = [[NGMimeMessageParser alloc] init];
  [mimeParser setDelegate:self];
  part = [mimeParser parsePartFromData:part];
  [mimeParser release];
  
  if (part == nil) {
    [self logWithFormat:@"could not parse MIME structure for task comment."];
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:
                          @"could not parse MIME structure for task comment"];
  }
  
  // we are interested in the body of the mimepart (which is the comment
  // of our task object)
  comment = [[NSString alloc] initWithData:[part body] 
                              encoding:[NSString defaultCStringEncoding]];

  if ([self isNew]) {
    if ([comment length] > 0)
      [self logWithFormat:
              @"WARNING: losing comment, can't handle comments "
              @"on create yet: %@", comment];

    // if we return 204 (no-content) here, the new task won't show up in Evo
    [r setStatus:200];
    [comment release];
    return r;
  }
  
  if (![[[self object] valueForKey:@"comment"] isEqualToString:comment]) {
    NSDictionary *changes;
    LSCommandContext *cmdctx;
    
    [[self object] takeValue:comment forKey:@"comment"];

    changes = [NSDictionary dictionaryWithObjectsAndKeys:
                            [self object],@"object",
                            nil];

    if ((cmdctx = [self commandContextInContext:_ctx]) != nil) {
      EOModel     *model;
      NSNumber    *width;
      
      model = [[[cmdctx valueForKey:LSDatabaseKey] adaptor] model];
      width = [[[model entityNamed:@"Job"] attributeNamed:@"comment"]
                       valueForKey:@"width"];

      if ([width intValue] >= (int)[comment length]) {
        [cmdctx runCommand:@"job::set" arguments:changes];
        [cmdctx commit];
      }
      else
        [self logWithFormat:
              @"WARNING: losing comment, too long for DB field"
              @" (comment: %i - db: %@)", [comment length], width];
    }
  }

  [comment release]; comment = nil;
  [r setStatus:200];
  return r;
}

- (id)GETAction:(WOContext *)_ctx {
  //[self logWithFormat:@"render EO: %@", [self object]];
  SxTaskRenderer *r;
  NSString *ical;
  
  r = [[SxTaskRenderer alloc] init];
  ical = [r vCalendarStringForTask:self];
  [r release]; r = nil;
  
  return ical;
}

- (WOResponse *)PUTAction:(WOContext *)_ctx {
  WOResponse *r = [_ctx response];
  
  if ([[[_ctx request] headerForKey:@"user-agent"] hasPrefix:@"Evolution/"])
    return [self putEvoComment:_ctx];
  
  [self logWithFormat:@"change task ..."];
  [self debugWithFormat:@"fake new task ..."];
  [r setStatus:204 /* no content */];
  return r;
}

- (id)objectInContext:(id)_ctx {
  if (self->eo) 
    return self->eo;
  self ->eo = [[[self taskManagerInContext:_ctx] 
                      eoForPrimaryKey:[self primaryKey]] retain];
  return self->eo;
}

- (id)primaryDeleteObjectInContext:(id)_ctx {
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

- (int)alternateRecipientAllowed {
  return 1;
}
- (int)originatorDeliveryReportRequested {
  return 0;
}
- (int)readReceiptRequested {
  return 0;
}

- (int)mapi0x1006_int {
  return 0;
}
- (int)mapi0x1007_int {
  return 0;
}
- (int)mapi0x1010_int {
  return 0;
}
- (int)mapi0x1011_int {
  return 0;
}
- (int)mapi0x3FDE_int {
  return 28591;
}

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
- (NSString *)cdoBody {
  NSString *body;
  static NSString *PrefixStr = @"ZideLook rich-text compressed comment: ";

  body = [[self object] valueForKey:@"comment"];

  if ([body isNotNull]) {
    if ([body length] > [PrefixStr length]) {
      if ([body hasPrefix:PrefixStr]) {
        return nil;
      }
    }
  }
  else {
    body = nil;
  }
  return body;
}

- (int)rtfInSync {
  return 1;
}

- (int)rtfSyncBodyCRC {
  return 0;
}

- (int)rtfSyncBodyCount {
  return 0;
}
- (int)rtfSyncPrefixCount {
  return 0;
}
- (int)rtfSyncTrailingCount {
  return 0;
}

- (int)cdoDepth {
  return 0;
}

- (int)cdoStatus {
  return 0;
}

- (NSString *)rtfCompressed {
  NSString        *body;
  static NSString *PrefixStr = @"ZideLook rich-text compressed comment: ";

  body = [[self object] valueForKey:@"comment"];

  if (![body isNotNull])
    body = @"";
  
  if ([body hasPrefix:PrefixStr])
    body = [body substringFromIndex:[PrefixStr length]];
  else
    body = [[body stringByEncodingRTF] stringByEncodingBase64];
  return body;
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
    object = [cmdctx runCommand:[[self class] newCommandName] arguments:_record];
    
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
