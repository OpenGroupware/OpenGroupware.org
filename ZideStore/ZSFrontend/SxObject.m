/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "SxObject.h"
#include "SxFolder.h"
#include <Main/SxAuthenticator.h>
#include "OLDavPropMapper.h"
#include "mapiflags.h"
#include "common.h"

@implementation SxObject

- (id)initWithEO:(id)_eo inFolder:(id)_folder {
  if ((self = [super init])) {
    self->nameInContainer = 
      [[[_eo valueForKey:[[self class] primaryKeyName]] stringValue] copy];
    self->container = _folder;
    self->eo        = [_eo retain];

    if ([self->container shouldRetainAsSoContainer])
      self->container = [self->container retain];
  }
  return self;
}

- (id)initWithName:(NSString *)_key inFolder:(id)_folder {
  if ((self = [super init])) {
    self->nameInContainer = [_key copy];
    self->container       = _folder;
    
    if ([self->container shouldRetainAsSoContainer])
      self->container = [self->container retain];
  }
  return self;
}

- (id)initNewWithName:(NSString *)_name inFolder:(id)_folder {
  if ((self = [self initWithName:_name inFolder:_folder])) {
    self->flags.isNew = 1;
  }
  return self;
}

- (id)init {
  return [self initWithName:nil inFolder:nil];
}

- (void)dealloc {
  [self detachFromContainer];
  [self->eo release];
  [super dealloc];
}

/* containment */

- (id)container {
  return self->container;
}
- (NSString *)nameInContainer {
  return self->nameInContainer;
}

- (void)detachFromContainer {
  if ([self->container shouldRetainAsSoContainer])
    [self->container release];
  self->container = nil;
  
  [self->nameInContainer release]; self->nameInContainer = nil;
}

/* primary key, EO, ... */

- (BOOL)isNew {
  return self->flags.isNew ? YES : NO;
}

- (NSNumber *)primaryKey {
  if (self->eo != nil)
    /* we have an EO and therefore a "real" primary key */
    return [self->eo valueForKey:[[self class] primaryKeyName]];
  
  /* we don't have an EO yet, so try to construct the key from the name */
  return [NSNumber numberWithInt:[[self nameInContainer] intValue]];
}

- (EOGlobalID *)globalID {
  id key;
  
  if (self->eo) 
    return [self->eo globalID];
  
  key = [self primaryKey];
  return [EOKeyGlobalID globalIDWithEntityName:[[self class] entityName]
                        keys:&key keyCount:1 zone:NULL];
}

/* resolving the object */

- (LSCommandContext *)commandContextInContext:(id)_ctx {
  SxAuthenticator *auth;
  
  if ((auth = [self authenticatorInContext:_ctx]) == nil)
    return nil;
  
  return [auth commandContextInContext:_ctx];
}

- (id)objectInContext:(id)_ctx {
  LSCommandContext *ctx;
  NSString *getCmdName, *pkeyName;
  id o;
  
  if (self->eo)
    return self->eo;
  
  if (_ctx == nil) _ctx = [[WOApplication application] context];
  
  if ((ctx = [self commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"missing command context !"];
    return nil;
  }

  /* get reflection info */
  
  getCmdName = [[self class] getCommandName];
  if ([getCmdName length] == 0) {
    [self logWithFormat:@"found no get-command name ..."];
    return nil;
  }
  
  pkeyName = [[self class] primaryKeyName];
  if ([pkeyName length] == 0) {
    [self logWithFormat:@"found no primary-key name ..."];
    return nil;
  }

  /* run command */
  
  o = [ctx runCommand:getCmdName, 
	     pkeyName, [self primaryKey], 
	     nil];
  if (o == nil) {
    [self logWithFormat:@"%@ returned no result for pkey %@",
            [[self class] getCommandName], [self primaryKey]];
    return nil;
  }
  if (![ctx commit]) {
    [self logWithFormat:@"could not commit transaction !"];
    [ctx rollback];
  }
  
  if ([o isKindOfClass:[NSArray class]])
    self->eo = [[o lastObject] retain];
  else
    self->eo = [o retain];
  
  return self->eo;
}

- (id)object {
  return self->eo
    ? self->eo
    : [self objectInContext:[[WOApplication application] context]];
}

/* attribute mappings */

- (id)davAttributeMapInContext:(id)_ctx {
  static OLDavPropMapper *davMap = nil;
  if (davMap == nil) {
    davMap = [[OLDavPropMapper alloc] initWithDictionary:
		    [[self class] defaultWebDAVAttributeMap]];
  }
  return davMap;
}

/* common DAV attributes */

- (id)davUid {
  return [self baseURLInContext:[[WOApplication application] context]];
}
- (NSString *)davResourceType {
  return @"";
}
- (BOOL)davIsCollection {
  return NO;
}

- (NSString *)davEntityTag {
  id obj;
  
  if ((obj = [self object]) == nil)
    return nil;
  if ((obj = [obj valueForKey:@"objectVersion"]) == nil)
    return nil;
  if (![obj isNotNull])
    return nil;
  
  /* NOTE: do _not_ change etag, used in other places! */
  return [NSString stringWithFormat:@"%@:%@", [self primaryKey], obj];
}

/* property sets */

- (NSSet *)propertySetNamed:(NSString *)_name {
  return [[self container] propertySetNamed:_name];
}

/* common Exchange attributes */

- (int)refreshInterval {
  return 300; /* every five minutes */
}
- (int)zlGenerationCount {
  [self logWithFormat:
          @"object should override -zlGenerationCount method to return the "
          @"OGo object-version!"];
  return (time(NULL) - 1047000000) / [self refreshInterval];
}

- (NSString *)outlookMessageClass {
  return @"IPM.Note"; /* email, default class */
}
- (NSString *)davContentClass {
  NSString *mc = [self outlookMessageClass];
  
  if ([mc isEqualToString:@"IPM.Contact"])
    return @"urn:content-classes:person";
  if ([mc isEqualToString:@"IPM.Task"])
    return @"urn:content-classes:task";

  if ([mc isEqualToString:@"IPM.Appointment"])
    return @"urn:content-classes:appointment";
  
  return @"urn:content-classes:message";
}

- (BOOL)isReadAllowed {
  return YES;
}
- (BOOL)isModificationAllowed {
  return YES;
}
- (BOOL)isDeletionAllowed {
  return NO;
}

- (NSNumber *)cdoAccess {
  // TODO: use proxy to find out, how we are supposed to format the number
  unsigned int permissionMask = 0;

  static NSDictionary *typing = nil;
  if (typing == nil) {
    typing = [[NSDictionary alloc] 
	       initWithObjectsAndKeys:
		 @"int", 
	         @"{urn:uuid:c2f41010-65b3-11d1-a29f-00aa00c14882/}dt",
	       nil];
  }
  
  permissionMask = 0;
  
  if ([self isReadAllowed])         
    permissionMask |= MAPI_ACCESS_READ; // 0x02
  if ([self isModificationAllowed]) 
    permissionMask |= MAPI_ACCESS_MODIFY; // 0x01
  if ([self isDeletionAllowed])
    permissionMask |= MAPI_ACCESS_DELETE; // 0x04
  
  permissionMask |= 0x00000020; // always add leading (create assoc?)
  
  // found out why 63:
  // 63  - 111111
  // x01 - 000001 - modify
  // x02 - 000010 - read
  // x04 - 000100 - delete
  // x08 - 001000 - create hier
  // x10 - 010000 - create item
  // x20 - 100000 - ? (create associated ?)
  // permissionMask = 63; // 0x3F
  
  return [SoWebDAVValue valueForObject:[NSNumber numberWithInt:permissionMask]
			attributes:typing];
}
- (int)cdoAccessLevel {
  return 1;
}

- (id)cdoMessageFlags {
  /* 
   Flag Values:
      READ=1,UNMODIFIED=2,SUBMIT=4,UNSENT=8,HASATTACH=10,FROMME=20
      ASSOCIATED=40,RESEND=80,RN_PENDING=100,NRN_PENDING=200
  */
  return @"1";
}

- (id)exLastModified {
  return [[self davLastModified] exDavDateValue];
}

- (NSCalendarDate *)now {
  return [NSCalendarDate calendarDate];
}
- (id)clientSubmitTime {
  return [[self now] exDavDateValue];
}
- (id)messageDeliveryTime {
  return [[self now] exDavDateValue];
}
- (id)cdoCreationTime {
  return [[self now] exDavDateValue];
}

- (int)deleteAfterSubmit {
  return 0; /* bool, means no */
}
- (int)messageSize {
  return 1024; /* default size ... */
}
- (int)rtfInSync {
  return 0;
}
- (int)cdoDepth {
  return 0; // TODO: don't know this
}
- (int)cdoStatus {
  return 0; // TODO: don't know this
}

- (NSString *)locationURL {
  return [NSString stringWithFormat:
                     @"http://localhost:20001/Skyrix/wa/activate?oid=%@",
                     [self primaryKey]];
}

/* checking if-headers */

- (NSArray *)parseETagList:(NSString *)_c {
  NSMutableArray *ma;
  NSArray  *etags;
  unsigned i, count;
  
  if ([_c length] == 0)
    return nil;
  if ([_c isEqualToString:@"*"])
    return nil;
  
  etags = [_c componentsSeparatedByString:@","];
  count = [etags count];
  ma    = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString *etag;
    
    etag = [[etags objectAtIndex:i] stringByTrimmingSpaces];
    if ([etag hasPrefix:@"\""] && [etag hasSuffix:@"\""])
      etag = [etag substringWithRange:NSMakeRange(1, [etag length] - 2)];
    
    if (etag != nil) [ma addObject:etag];
  }
  return ma;
}

- (NSException *)checkIfMatchCondition:(NSString *)_c inContext:(id)_ctx {
  /* only run the request if one of the etags matches the resource etag */
  NSArray  *etags;
  NSString *etag;
  
  if ([_c isEqualToString:@"*"])
    /* to ensure that the resource exists! */
    return nil;
  
  if ((etags = [self parseETagList:_c]) == nil)
    return nil;
  if ([etags count] == 0) /* no etags to check for? */
    return nil;
  
  etag = [self davEntityTag];
  if ([etag length] == 0) /* has no etag, ignore */
    return nil;
  
  if ([etags containsObject:etag]) {
    [self debugWithFormat:@"etag '%@' matches: %@", etag, etags];
    return nil; /* one etag matches, so continue with request */
  }
  
  // TODO: we might want to return the davEntityTag in the response
  [self debugWithFormat:@"etag '%@' does not match: %@", etag, etags];
  return [NSException exceptionWithHTTPStatus:412 /* Precondition Failed */
		      reason:@"Precondition Failed"];
}

- (NSException *)checkIfNoneMatchCondition:(NSString *)_c inContext:(id)_ctx {
  /*
    If one of the etags is still the same, we can ignore the request.
    
    Can be used for PUT to ensure that the object does not exist in the store
    and for GET to retrieve the content only if if the etag changed.
  */
#if 0
  if ([_c isEqualToString:@"*"])
    return nil;
  
  if ((a = [self parseETagList:_c]) == nil)
    return nil;
#else
  [self logWithFormat:@"TODO: implement if-none-match for etag: '%@'", _c];
#endif
  return nil;
}

- (NSException *)matchesRequestConditionInContext:(id)_ctx {
  NSException *error;
  WORequest *rq;
  NSString  *c;
  
  if ((rq = [_ctx request]) == nil)
    return nil; /* be tolerant - no request, no condition */
  
  if ((c = [rq headerForKey:@"if-match"]) != nil) {
    if ((error = [self checkIfMatchCondition:c inContext:_ctx]) != nil)
      return error;
  }
  if ((c = [rq headerForKey:@"if-none-match"]) != nil) {
    if ((error = [self checkIfNoneMatchCondition:c inContext:_ctx]) != nil)
      return error;
  }
  
  return nil;
}

/* actions */

- (id)davCreateObject:(NSString *)_name properties:(NSDictionary *)_props 
  inContext:(id)_ctx
{
  [self logWithFormat:@"CREATE: %@: %@", _name, _props];
  
  return [NSException exceptionWithHTTPStatus:500
		      reason:@"object creation not yet implemented"];
}

- (id)PUTAction:(id)_ctx {
  /* per default, return nothing ... */
  NSException *error;
  WOResponse *r;

  /* check HTTP preconditions */
  
  if ((error = [self matchesRequestConditionInContext:_ctx]))
    return error;
  
  /* fake default */
  
  r = [(WOContext *)_ctx response];
  [r setStatus:200 /* Ok */];
  [self logWithFormat:@"PUT on object, just saying OK"];
  return r;
}

- (id)primaryDeleteObjectInContext:(id)_ctx {
  LSCommandContext *cmdctx;
  NSException *error;
  NSString    *delCmdName;
  
  /* get context */
  
  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    return [NSException exceptionWithHTTPStatus:500
			reason:@"could not get command context"];
  }
  
  /* lookup delete command */

  delCmdName = [[self class] deleteCommandName];
  if ([delCmdName length] == 0) {
    [self logWithFormat:@"did not find delete command !"];
    return [NSException exceptionWithHTTPStatus:500
			reason:@"delete command not set !"];
  }
  
  /* delete the object */
  
  error = nil;
  NS_DURING {
    id obj = [self object];
    [cmdctx runCommand:[[self class] deleteCommandName], @"object", obj, nil];
  }
  NS_HANDLER
    error = [localException retain];
  NS_ENDHANDLER;
  error = [error autorelease];

  if (error != nil) {
    [self logWithFormat:@"delete failed: %@", error];
    [cmdctx rollback];
  }
  else if (![cmdctx commit]) {
    [self logWithFormat:@"commit failed !"];
    [cmdctx rollback];
    error = [NSException exceptionWithHTTPStatus:409 /* conflict */
			 reason:@"transaction commit failed."];
  }
  
  return error;
}
- (id)DELETEAction:(WOContext *)_ctx {
  NSException *error;
  id obj;
  
  /* preconditions */
  
  if ([self isNew]) {
    [self debugWithFormat:@"tried delete on new key ..."];
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"this object does not exist"];
  }
  if ((obj = [self object]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"this object could not be found"];
  }
  
  if (![self isDeletionAllowed]) {
    [self logWithFormat:@"tried to delete a protected object"];
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:@"object deletion is not allowed"];
  }

  /* check HTTP preconditions */
  
  if ((error = [self matchesRequestConditionInContext:_ctx]))
    return error;

  /* perform actual delete */
  
  error = [self primaryDeleteObjectInContext:_ctx];
  
  /* check result or commit */
  return error ? error : (id)[NSNumber numberWithBool:YES];
}

- (id)GETAction:(WOContext *)_ctx {
  if ([self isNew]) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"this object does not exist"];
  }
  
  if ([[[_ctx request] headerForKey:@"user-agent"] hasPrefix:@"Evolution/"]) {
    WOResponse *r = [_ctx response];
    [self logWithFormat:@"GET from Evolution, just saying OK ..."];
    [r setStatus:200];
    return r;
  }
  
  return self;
}

/* reflection necessary for operation */

+ (NSString *)primaryKeyName {
  return nil;
}
+ (NSString *)entityName {
  return nil;
}

+ (NSString *)getCommandName {
  return nil;
}
+ (NSString *)deleteCommandName {
  return nil;
}
+ (NSString *)newCommandName {
  return nil;
}
+ (NSString *)setCommandName {
  return nil;
}

/* KVC */

- (id)valueForUndefinedKey:(NSString *)_key {
  [self debugWithFormat:@"queried undefined KVC key: '%@'", _key];
  return nil;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  ms = [NSMutableString stringWithCapacity:64];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  if (self->nameInContainer)  
    [ms appendFormat:@" name=%@",  self->nameInContainer];
  if (self->eo) 
    [ms appendString:@" has-eo"];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SxObject */
