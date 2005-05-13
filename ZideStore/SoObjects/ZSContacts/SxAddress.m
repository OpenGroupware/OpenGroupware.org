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

#include "SxAddress.h"
#include <ZSFrontend/OLDavPropMapper.h>
#include "SxAddressFolder.h"
#include "common.h"
#include <ZSBackend/SxUpdateContact.h>
#include <ZSBackend/SxContactManager.h>
#include <ZSFrontend/NSObject+ExValues.h>

// TODO: add methods to query attributes !

@interface NSObject(Parser)

+ (id)parserWithContext:(id)_ctx;
- (id)initWithContext:(id)_ctx;

- (NSDictionary *)addressFor:(NSString *)_kind
  record:(NSDictionary *)_record;

- (NSMutableDictionary *)parseEntry:(id)_entry;

@end /* NSObject(Parser) */

@implementation SxAddress

static BOOL debugEO = NO;

- (void)clearVars {
  [self->company release];    self->company    = nil;
  [self->addr release];       self->addr       = nil;
  [self->phones release];     self->phones     = nil;
}
- (void)dealloc {
  [self clearVars];
  [super dealloc];
}

- (void)markAsPrivate {
  self->isPrivate = YES;
}
- (void)markAsAccount {
  self->isAccount = YES;
}

/* Exchange */

- (NSString *)outlookMessageClass {
  return @"IPM.Contact";
}

- (BOOL)isDeletionAllowed {
  // TODO: check access rights
  return YES;
}

/* WebDAV */

- (NSString *)baseURL {
  return [[(SxFolder *)[self container] baseURL]
                 stringByAppendingString:[[self primaryKey] stringValue]];
}

- (id)davAttributeMapInContext:(id)_ctx {
  static OLDavPropMapper *davMap = nil;
  if (davMap == nil) {
    id dm;
    dm = [[self class] defaultWebDAVAttributeMap];
    davMap = [[OLDavPropMapper alloc] initWithDictionary:dm];
  }
  return davMap;
}

- (BOOL)davIsCollection {
  return NO;
}

/* updating/inserting */

- (NSString *)entityName {
  return [[self soClass] lookupKey:@"entityName" inContext:nil];
}
- (NSString *)updateCommandName {
  return [[self soClass] lookupKey:@"updateCommand" inContext:nil];
}
- (NSString *)newCommandName { // should be a class method?
  return [[self soClass] lookupKey:@"newCommand" inContext:nil];
}

+ (NSString *)getCommandName {
  return [[self soClass] lookupKey:@"getCommand" inContext:nil];
}

+ (NSString *)deleteCommandName { // TODO: is this correct? => yes, I think so
  return [[self soClass] lookupKey:@"deleteCommand" inContext:nil];
}
+ (NSString *)primaryKeyName {
  return @"companyId";
}

- (NSString *)updateSqlForPhoneKey:(NSString *)_key value:(id)_value 
  withCompanyId:(int)_companyId
{
  NSMutableString *tms;
  
  tms = [NSMutableString stringWithCapacity:128];
  [tms appendString:@"UPDATE telephone"];
  
  [tms appendString:@" SET"];
  [tms appendString:@" number='"];
  [tms appendString:[_value stringValue]];
  [tms appendString:@"', db_status='updated'"];
  
  [tms appendString:@" WHERE company_id="];
  [tms appendFormat:@"%i", _companyId];
  [tms appendString:@" AND type='"];
  [tms appendString:[_key stringValue]];
  [tms appendString:@"';"];
  return tms;
}

- (BOOL)fillCompanyRecord:(NSMutableDictionary *)values
  from:(NSDictionary *)_setProps
  keySet:(NSMutableArray *)keys
{
  id value;
  
  if ((value = [_setProps objectForKey:@"givenName"])) {
    [values setObject:value forKey:@"firstname"];
    [keys removeObject:@"givenName"];
  }
  if ((value = [_setProps objectForKey:@"sn"])) {
    [values setObject:value forKey:@"name"];
    [keys removeObject:@"sn"];
  }
  if ((value = [_setProps objectForKey:@"middleName"])) {
    [values setObject:value forKey:@"middlename"];
    [keys removeObject:@"middleName"];
  }
  if ((value = [_setProps objectForKey:@"nickname"])) {
    [values setObject:value forKey:@"description"];
    [keys removeObject:@"nickname"];
  }
  if ((value = [_setProps objectForKey:@"businesshomepage"])) {
    [values setObject:value forKey:@"url"];
    [keys removeObject:@"businesshomepage"];
  }
  if ((value = [_setProps objectForKey:@"spousecn"])) {
    [values setObject:value forKey:@"partnerName"];
    [keys removeObject:@"spousecn"];
  }
  if ((value = [_setProps objectForKey:@"secretarycn"])) {
    [values setObject:value forKey:@"assistantName"];
    [keys removeObject:@"secretarycn"];
  }
  if ((value = [_setProps objectForKey:@"manager"])) {
    [values setObject:value forKey:@"bossName"];
    [keys removeObject:@"manager"];
  }
  if ((value = [_setProps objectForKey:@"profession"])) {
    [values setObject:value forKey:@"occupation"];
    [keys removeObject:@"profession"];
  }
  if ((value = [_setProps objectForKey:@"department"])) {
    [values setObject:value forKey:@"department"];
    [keys removeObject:@"department"];
  }
  if ((value = [_setProps objectForKey:@"roomnumber"])) {
    [values setObject:value forKey:@"office"];
    [keys removeObject:@"roomnumber"];
  }
  if ((value = [_setProps objectForKey:@"fburl"])) {
    [values setObject:value forKey:@"freebusyUrl"];
    [keys removeObject:@"fburl"];
  }

  // adjust dates - add 12 hours to birthday and anniversary so
  // we don't get in trouble with the timezone setting
  // (the time doesn't matter here anyhow)
  if ((value = [_setProps objectForKey:@"bday"])) {
    NSCalendarDate *cdate;
    
    cdate = [NSCalendarDate dateWithExDavString:[value stringValue]];
    cdate = [cdate dateByAddingYears:0 months:0 days:0 hours:12 minutes:0
                   seconds:0];
    [values setObject:cdate forKey:@"birthday"];
    [keys removeObject:@"bday"];
  }

  if ((value = [_setProps objectForKey:@"weddinganniversary"])) {
    NSCalendarDate *cdate;
    
    cdate = [NSCalendarDate dateWithExDavString:[value stringValue]];
    cdate = [cdate dateByAddingYears:0 months:0 days:0 hours:12 minutes:0
                   seconds:0];
    [values setObject:cdate forKey:@"anniversary"];    
    [keys removeObject:@"weddinganniversary"];
  }
  return YES;
}

- (BOOL)fillPhoneRecord:(NSMutableDictionary *)phones_
  from:(NSDictionary *)_setProps
  keySet:(NSMutableArray *)keys
{
  /* phone (separate table: telephone[telephone_id,company_id,number,type]) */
  id value;
  
  if ((value = [_setProps objectForKey:@"telephoneNumber"])) {
    [phones_ setObject:value forKey:@"01_tel"];
    [keys removeObject:@"telephoneNumber"];
  }
  if ((value = [_setProps objectForKey:@"mobile"])) {
    [phones_ setObject:value forKey:@"03_tel_funk"];
    [keys removeObject:@"mobile"];
  }
  if ((value = [_setProps objectForKey:@"homePhone"])) {
    [phones_ setObject:value forKey:@"05_tel_private"];
    [keys removeObject:@"homePhone"];
  }
  if ((value = [_setProps objectForKey:@"facsimiletelephonenumber"])) {
    [phones_ setObject:value forKey:@"10_fax"];
    [keys removeObject:@"facsimiletelephonenumber"];
  }
  if ((value = [_setProps objectForKey:@"homefax"])) {
    [phones_ setObject:value forKey:@"15_fax_private"];
    [keys removeObject:@"homefax"];
  }
  return YES;
}

- (BOOL)fillEmailRecord:(NSMutableDictionary *)values
  from:(NSDictionary *)_setProps
  keySet:(NSMutableArray *)keys
{
  id value;
  
  if ((value = [_setProps objectForKey:@"email1"]) != nil) {
    NSString *dn;
    
    if ((dn = [_setProps objectForKey:@"email1displayname"])) {
      if (![dn isEqual:value])
	value = [NSString stringWithFormat:@"\"%@\" <%@>", dn, value];
      
      [keys removeObject:@"email1displayname"];
    }
    [keys removeObject:@"email1"];
    
    [values setObject:[value stringValue] forKey:@"email1"];
  }
  if ((value = [_setProps objectForKey:@"email2"]) != nil) {
    NSString *dn;
    
    if ((dn = [_setProps objectForKey:@"email2displayname"])) {
      if (![dn isEqual:value])
	value = [NSString stringWithFormat:@"\"%@\" <%@>", dn, value];
      
      [keys removeObject:@"email2displayname"];
    }
    [keys removeObject:@"email2"];
    
    [values setObject:[value stringValue] forKey:@"email2"];
  }
  return YES;
}

- (id)davCreateObject:(NSString *)_name properties:(NSDictionary *)_props 
  inContext:(id)_ctx
{
  /*
    Copy of Donald:
      bday = "1969-12-30T23:00:00Z";
      cn = "Donald Duck";
      email1 = "donald@entenhausen.de";
      email1addrtype = SMTP;
      email1displayname = "donald@entenhausen.de";
      emailaddresslist = "<V:v xmlns:V=\"xml:\">0</V:v>";
      emaillisttype = 1;
      fileas = "Donald Duck";
      givenName = Donald;
      mapi0x00008025 = 0;
      mapi0x00008506 = 0;
      cdoAction = 512;
      outlookMessageClass = "IPM.Contact";
      sideeffects = 16;
      sn = Duck;
      subject = "Donald Duck";
  */
  LSCommandContext    *cmdctx;
  NSMutableDictionary *values;
  NSMutableDictionary *phoneDict;
  NSMutableArray      *keys;
  NSException *e = nil;
  id  value;
  id  neweo;
  int companyId;
  
  if (self->isAccount) {
    [self logWithFormat:@"tried to create account, forbidden."];
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:
			  @"it's forbidden to create accounts using DAV!"];
  }
  
  [self debugWithFormat:@"create %@ with: %@",
	  [self nameInContainer],
	  _props];

  keys = [[[_props allKeys] mutableCopy] autorelease];
  
  if ((value = [_props objectForKey:@"outlookMessageClass"])) {
    if (![value isEqualToString:@"IPM.Contact"]) {
      return [NSException exceptionWithHTTPStatus:500
			  reason:@"this resource can only create contacts !"];
    }
    
    [keys removeObject:@"outlookMessageClass"];
    
    /* remove some MAPI stuff */
    [keys removeObject:@"mapiID_00008025"]; // 0
    [keys removeObject:@"mapiID_00008506"]; // 0
    [keys removeObject:@"cdoAction"];       // 512
    [keys removeObject:@"sideeffects"];
    [keys removeObject:@"subject"];
  }
  
  if ((cmdctx = [[self container] commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"got no command context ?"];
    return [NSException exceptionWithHTTPStatus:500
			reason:@"got no command context !"];
  }
  
  /* remove redundant or unused attributes */
  
  [keys removeObject:@"cn"];
  [keys removeObject:@"fileas"];
  [keys removeObject:@"email1addrtype"];
  [keys removeObject:@"email2addrtype"];
  [keys removeObject:@"emailaddresslist"];
  [keys removeObject:@"emaillisttype"];
  
  /* select out maintable attributes */
  
  [self logWithFormat:@"  keys: %@", [keys componentsJoinedByString:@","]];
  
  values = [NSMutableDictionary dictionaryWithCapacity:16];
  phoneDict = [NSMutableDictionary dictionaryWithCapacity:8];
  
  if (self->isPrivate)
    [values setObject:[NSNumber numberWithBool:YES] forKey:@"isPrivate"];
  if (self->isAccount)
    [values setObject:[NSNumber numberWithBool:YES] forKey:@"isAccount"];
  
  [values setObject:
	    [[cmdctx valueForKey:LSAccountKey] valueForKey:@"companyId"]
	  forKey:@"ownerId"];
  [values setObject:[NSNumber numberWithInt:1] forKey:@"objectVersion"];
  [values setObject:@"person was created in Evolution" forKey:@"logText"];
  
  [self fillCompanyRecord:values from:_props keySet:keys];
  [self fillPhoneRecord:phoneDict   from:_props keySet:keys];
  [self fillEmailRecord:values   from:_props keySet:keys];
  
  if ((value = [_props objectForKey:@"title"])) {
    [values setObject:[value stringValue] forKey:@"job_title"];
    [keys removeObject:@"title"];
  }
  
  [self logWithFormat:@"  remaining keys: %@", 
	  [keys componentsJoinedByString:@","]];
  
  /* perform creation */
  
  NS_DURING {
    EOAdaptorChannel *ch;
    NSEnumerator *e;
    NSString     *key;

    neweo = [cmdctx runCommand:[self newCommandName] arguments:values];
    
    if (debugEO)
      [self logWithFormat:@"got EO: %@", neweo];
    
    companyId = [[neweo valueForKey:@"companyId"] intValue];
    if (debugEO) [self logWithFormat:@"  company-id: %i", companyId];
    
    /* TODO: check permissions */
    ch = [[cmdctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
    e = [phoneDict keyEnumerator];
    while ((key = [e nextObject]) != nil) {
      NSString *value;
      NSString *sql;
      
      value = [phoneDict objectForKey:key];
      sql = [self updateSqlForPhoneKey:key value:value 
		  withCompanyId:companyId];
      
      if ([sql length] == 0) {
	[self logWithFormat:@"got no SQL for phone key: '%@'", key];
	continue;
      }
      
      if (![ch evaluateExpression:sql]) {
	// TODO: rollback & give back exception
	[self logWithFormat:@"failed to update phone key %@: %@", key, sql];
	continue;
      }
      
      [self logWithFormat:@"successful update of phone-key: %@", key];
    }
  }
  NS_HANDLER
    e = [localException retain];
  NS_ENDHANDLER;
  
  if (e != nil) {
    [self logWithFormat:@"create failed: %@", e];
    [cmdctx rollback];
  }
  else if (![cmdctx commit]) {
    [self logWithFormat:@"commit failed !"];
    [cmdctx rollback];
    e = [NSException exceptionWithHTTPStatus:500 /* Server Error */
		     reason:@"transaction commit failed."];
  }
  else {
    /* everything seems fine .. */
    e = nil;
    [(WOContext *)_ctx setObject:[NSNumber numberWithInt:companyId]
		       forKey:@"SxNewObjectID"];
  }
  
  return e;
}

- (EOGlobalID *)globalID {
  /* Note: SxObject has a different -globalID method */
  EOGlobalID  *gid;
  int companyId;
  id  value;
  
  if (self->flags.isNew) 
    return nil;
  
  companyId = [[self nameInContainer] intValue];
  value = [NSNumber numberWithInt:companyId];
  gid   = [EOKeyGlobalID globalIDWithEntityName:[self entityName]
			 keys:&value keyCount:1
			 zone:NULL];
  return gid;
}

- (NSArray *)davQueryOnSelf:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  // TODO: each subclass needs a different "renderer" for the full ZideLook
  //       property queryset
  [self logWithFormat:@"Should deliver Contact properties: %@",
          [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  return [super davQueryOnSelf:_fs inContext:_ctx];
}

/* update ...*/

- (Class)classFromSlotNamed:(NSString *)_slot {
  static NSMutableSet *ms = nil;
  NSString *n;
  Class clazz;
    
  if ((n = [[self soClass] lookupKey:_slot inContext:nil]) == nil)
    return Nil;
  
  if ((clazz = NSClassFromString(n)) != Nil)
    return clazz;

  if ([ms containsObject:n])
    return Nil;
  
  if (ms == nil) ms = [[NSMutableSet alloc] initWithCapacity:16];
  [ms addObject:n];
  [self logWithFormat:@"WARNING: did not find class specified in slot %@: %@",
          _slot, n];
  return Nil;
}

- (Class)updateClass {
  return [self classFromSlotNamed:@"updateClass"];
}

- (Class)zideLookParserClass {
  return [self classFromSlotNamed:@"zlParserClass"];
}
- (Class)zideLookRendererClass {
  return [self classFromSlotNamed:@"zlRendererClass"];
}
- (Class)evolutionParserClass {
  return [self classFromSlotNamed:@"evcParserClass"];
}

- (Class)selfRendererClass {
  return [self zideLookRendererClass];
}

- (SxContactManager *)contactManagerInContext:(id)_ctx {
  LSCommandContext *cmdctx;
  SxContactManager *sm;

  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: got no OGo context for context: %@", _ctx];
    return nil;
  }
  if ((sm = [SxContactManager managerWithContext:cmdctx]) == nil) {
    [self logWithFormat:@"ERROR: got no contact manager for OGo context: %@", 
            cmdctx];
    return nil;
  }
  return sm;
}

- (NSException *)davSetProperties:(NSDictionary *)_setProps
  removePropertiesNamed:(NSArray *)_delProps 
  inContext:(id)_ctx
{
  NSString    *ua;
  NSException *exc;
  id          ep;
  Class       rc;
  
  ua = [[_ctx request] headerForKey:@"user-agent"];
  
  rc = ([ua hasPrefix:@"Evolution/"])
    ? [self evolutionParserClass]
    : [self zideLookParserClass];
  
  exc = nil;
  ep  = nil;

  NS_DURING {
    LSCommandContext *ctx;
    NSNumber         *pkey;
    NSDictionary     *attrs;
    id               obj, ren;

    ctx   = [self commandContextInContext:_ctx];
    pkey  = [self primaryKey];
    ren   = [rc parserWithContext:_ctx];
    
    attrs = [ren parseEntry:_setProps];
    ep    = [[[self updateClass] alloc] initWithContext:ctx primaryKey:pkey
                                        attributes:attrs];

    [ep setType:[[self container] type]];
    if (!(obj = [ep update]))
      [self logWithFormat:@"update failed with _setProps %@", _setProps];
    else {
      if ([ep wasNew]) {
        id oid;

        if ((oid = [obj valueForKey:@"companyId"]) == nil)
          [self logWithFormat:@"Missing companyId for %@", obj];
        else
          [(WOContext *)_ctx setObject:oid forKey:@"SxNewObjectID"];
      }
    }
  }
  NS_HANDLER {
    printf("got exception %s\n", [[localException description] cString]);
    exc = localException;
  }
  NS_ENDHANDLER;
  [ep release]; ep = nil;
  return exc;

}

/* actions */

- (BOOL)shouldReturn201AfterPUTInContext:(WOContext *)_ctx {
  // TODO: DUP in SxAppointment (move to SxObject?)
  WEClientCapabilities *cc;
  NSString *ua;
  
  cc = [[(WOContext *)_ctx request] clientCapabilities];
  ua = [cc userAgentType];
  if ([ua isEqualToString:@"Evolution"])
    /* Evo needs 201, otherwise an error will be shown */
    return YES;
  if ([ua isEqualToString:@"ZideLook"])
    return YES;
  
  /* if I remember right, Cadaver complains on 201 */
  return NO;
}

- (NSException *)handleVCardSetException:(NSException *)_exception {
  return _exception;
}

- (id)PUTAction:(WOContext *)_ctx {
  LSCommandContext *cmdctx;
  WOResponse  *r;
  NSException *error;
  NSString    *mtype, *etag, *tmp, *url;
  NSString    *content = nil;
  id result;
  
  /* check HTTP preconditions */
  
  if ((error = [self matchesRequestConditionInContext:_ctx]))
    return error;
  
  /* check MIME-type */
  
  mtype = [[_ctx request] headerForKey:@"content-type"];
  if (![mtype hasPrefix:@"text/x-vcard"]) {
    if ([mtype length] > 0) {
      [self logWithFormat:@"ERROR: tried to PUT unsupported MIME type: %@",
            mtype];
      
      // TODO: use different status?!
      return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                          reason:@"unsupported content type in PUT"];
    }
    
    content = [[_ctx request] contentAsString];
    if (![content hasPrefix:@"BEGIN:"]) {
      return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                          reason:@"missing content type in PUT"];
    }
    else {
      [self logWithFormat:
              @"WARN: missing content-type in PUT, but looks like vCard ..."];
    }
  }
  if (content == nil) content = [[_ctx request] contentAsString];
  
  /* add vCard */
  
  cmdctx = [self commandContextInContext:_ctx];
  NS_DURING {
    error  = nil;
    result = [cmdctx runCommand:@"company::set-vcard",
             @"vCard",         content,
             @"entityName",    [self entityName],
	     @"createPrivate", [NSNumber numberWithBool:self->isPrivate],
             @"gid",           [self isNew] ? nil : [self globalID],
             nil];
  }
  NS_HANDLER {
    error = [self handleVCardSetException:localException];
    result = nil;
  }
  NS_ENDHANDLER;
  
  if (error != nil) {
    [self logWithFormat:@"ERROR: failed to write vCard: %@", error];
    return [NSException exceptionWithHTTPStatus:500 /* Server Error */
                        reason:[error reason]];
  }
  
  if (debugEO) [self logWithFormat:@"got EO: %@", result];
  
  if (![[result valueForKey:@"companyId"] isNotNull]) {
    [cmdctx rollback];
    return [NSException exceptionWithHTTPStatus:500 /* Server Error */
                        reason:@"ERROR: failed to create record!"];
  }
  
  /* commit */
  
  if (![cmdctx commit]) {
    [self logWithFormat:@"commit failed !"];
    [cmdctx rollback];
    return [NSException exceptionWithHTTPStatus:500 /* Server Error */
			reason:@"transaction commit failed."];
  }
  
  /* remember result */
  
  ASSIGN(self->eo, result);
  
  /* setup response */

  r = [(WOContext *)_ctx response];
  [r setStatus:
       [self shouldReturn201AfterPUTInContext:_ctx]
       ? 201 /* Created */ : 200 /* OK */];
  
  /* set etag header */
  if ((etag = [self davEntityTag]) != nil)
    [r setHeader:etag forKey:@"etag"];
  
  /* set location header (TODO: DUP in SxAppointment) */
  if ([(tmp = [self->eo valueForKey:@"companyId"]) isNotNull]) {
    url = [[self container] baseURLInContext:_ctx];
    if (![url hasSuffix:@"/"]) url = [url stringByAppendingString:@"/"];
    
    tmp = [tmp stringValue];
    tmp = [tmp stringByAppendingString:@".vcf"];
    
    [r setHeader:[url stringByAppendingString:tmp] forKey:@"location"];
  }
  else {
    [self logWithFormat:
	    @"WARNING: cannot set location header, missing new object id!"];
  }
  
  return r;
}

- (id)GETAction:(WOContext *)_ctx {
  SxContactManager *manager;
  NSEnumerator *e;
  WOResponse   *response;
  NSString     *vCard;
  NSData       *contentData;
  NSDictionary *result;
  
  manager = [SxContactManager managerWithContext:
				[self commandContextInContext:_ctx]];
  
  e = [manager idsAndVersionsAndVCardsForGlobalIDs:
		 [NSArray arrayWithObject:[self globalID]]];
  
  if ((result = [e nextObject]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"did not find vcard for given object id"];
  }
  
  if ((vCard = [result valueForKey:@"vCardData"]) == nil) {
    return [NSException exceptionWithHTTPStatus:500 /* server error */
			reason:@"vcard renderer failed"];
  }
  
  contentData = [vCard dataUsingEncoding:NSUTF8StringEncoding];
  
  response = [WOResponse responseWithRequest:[_ctx request]];
  [response setStatus:200 /* OK */];
  [response setHeader:@"text/x-vcard; charset=utf-8" forKey:@"content-type"];
  [response setContent:contentData];
  return response;
}

/* DAV default attributes (allprop queries by ZideLook ;-) */

- (NSArray *)defaultWebDAVPropertyNamesInContext:(id)_ctx {
  static NSMutableArray *defNames = nil;
  if (defNames == nil) {
    defNames = [[[self propertySetNamed:@"DefaultContactProperties"] 
		       allObjects] copy];
  }
  return defNames;
}


@end /* SxAddress */
