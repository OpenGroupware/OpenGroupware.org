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

#include "SkyAccountDocument.h"
#include "common.h"
#include "SkyAccountDataSource.h"

@implementation SkyAccountDocumentType
@end /* SkyAccountDocumentType */

@interface NSObject(GID)
- (EOGlobalID *)globalID;
@end

@interface SkyAccountDocument(PrivateMethodes)
- (void)_setObjectVersion:(NSNumber *)_version;
- (void)_setIsLocked:(BOOL)_flag;
- (void)_setIsExtraAccount:(BOOL)_flag;
- (void)_registerForGID;
@end

#include "SkyAccountTeamsDataSource.h"

@implementation SkyAccountDocument

// designated initializer
- (id)initWithAccount:(id)_account
            globalID:(EOGlobalID *)_gid
          dataSource:(EODataSource *)_ds
{
  if ((self = [super init])) {
    [self _setObjectVersion:[_account valueForKey:@"objectVersion"]];
    [self _setIsLocked:[[_account valueForKey:@"isLocked"] boolValue]];
    [self _setIsExtraAccount:
          [[_account valueForKey:@"isExtraAccount"] boolValue]];
    
    ASSIGN(self->dataSource, _ds);
    ASSIGN(self->globalID,   _gid);
    ASSIGN(self->eo,         _account);
    [self _registerForGID];
    
    [self setLogin:     [_account valueForKey:@"login"]];
    [self setPassword:  [_account valueForKey:@"password"]];
    [self setNumber:    [_account valueForKey:@"number"]];
    [self setFirstname: [_account valueForKey:@"firstname"]];
    [self setMiddlename:[_account valueForKey:@"middlename"]];
    [self setName:      [_account valueForKey:@"name"]];
    [self setNickname:  [_account valueForKey:@"description"]];
    
    self->status.isComplete  = YES;
    self->status.isValid     = YES;
    self->status.isEdited    = NO;
  }
  return self;
}

- (id)initWithAccount:(id)_account dataSource:(EODataSource *)_ds {
  EOKeyGlobalID *gid;

  if ([_account respondsToSelector:@selector(globalID)])
    gid = (EOKeyGlobalID *)[_account globalID];
  else
    gid = [_account valueForKey:@"globalID"];
  
  return [self initWithAccount:_account globalID:gid dataSource:_ds];
}

- (id)initWithGlobalID:(EOGlobalID *)_gid dataSource:(EODataSource *)_ds {
  id account = nil;

  if (_gid != nil) {
    account = [[[(id)_ds context] runCommand:@"object::get-by-globalid",
                              @"gid", _gid, nil] lastObject];
  }
  
  return [self initWithAccount:account globalID:_gid dataSource:_ds];
}

- (id)initWithGlobalID:(EOGlobalID *)_gid context:(id)_ctx {
  id           account = nil;
  EODataSource *ds     = nil;

  if (_gid != nil) {
    account = [[_ctx runCommand:@"object::get-by-globalid",
                                @"gid", _gid, nil] lastObject];
  }
  ds = [[[SkyAccountDataSource alloc] initWithContext:_ctx] autorelease];
  return [self initWithAccount:account dataSource:ds];
}

/* create a virtual document */
- (id)initWithContext:(id)_ctx {
  EODataSource *ds;
  NSDictionary *dict;
  id           own;

  own  = [_ctx valueForKey:LSAccountKey];
  ds   = [[[SkyAccountDataSource alloc] initWithContext:_ctx] autorelease];
  dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES],  @"isAccount",
                              [own valueForKey:@"companyId"], @"ownerId",
                              nil];
  return [self initWithAccount:dict globalID:nil dataSource:ds];
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  RELEASE(self->dataSource);
  RELEASE(self->globalID);
  RELEASE(self->eo);

  RELEASE(self->firstname);
  RELEASE(self->middlename);
  RELEASE(self->name);
  RELEASE(self->nickname);

  RELEASE(self->number);
  RELEASE(self->login);
  RELEASE(self->password);
  RELEASE(self->objectVersion);
  
  [super dealloc];
}
#endif

- (SkyDocumentType *)documentType {
  static SkyAccountDocumentType *docType = nil;
  
  if (docType == nil)
    docType = [[SkyAccountDocumentType alloc] init];

  return docType;
}

- (BOOL)isValid {
  return self->status.isValid;
}

- (BOOL)isComplete {
  if ([self isValid] == NO)
    return NO;

  return self->status.isComplete;
}

- (BOOL)isNew {
  return (self->globalID == nil) ? YES : NO;
}

- (void)invalidate {
  [self reload]; /* clear all attrs */
  RELEASE(self->globalID); self->globalID = nil;
  self->status.isValid = NO;
}

- (BOOL)isEdited {
  return (self->globalID == nil || self->status.isEdited) ? YES : NO;
}

- (EOGlobalID *)globalID {
  return self->globalID;
}

- (NSArray *)attributesForNamespace:(NSString *)_namespace {
  if (_namespace == nil)
    return nil;

  return nil;
}

- (id)context {
  if (self->dataSource)
    return [(id)self->dataSource context];
  
#if DEBUG
  NSLog(@"WARNING(%s): document %@ has no datasource/context !!",
        __PRETTY_FUNCTION__, self);
#endif
  return nil;
}

/* accessors */

- (void)setFirstname:(NSString *)_firstName {
  ASSIGNCOPY_IFNOT_EQUAL(self->firstname, _firstName, self->status.isEdited);
}
- (NSString *)firstname {
  return self->firstname; // "firstname"
}

- (void)setMiddlename:(NSString *)_middlename {
  ASSIGNCOPY_IFNOT_EQUAL(self->middlename, _middlename, self->status.isEdited);
}
- (NSString *)middlename {
  return self->middlename; // "middlename"
}

- (void)setName:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->name, _name, self->status.isEdited);
}
- (NSString *)name {
  return self->name; // "name"
}

- (void)setNickname:(NSString *)_nickname {
  ASSIGNCOPY_IFNOT_EQUAL(self->nickname, _nickname, self->status.isEdited);
}
- (NSString *)nickname {
  return self->nickname; // "description"
}

- (void)setPassword:(NSString *)_password {
  ASSIGNCOPY_IFNOT_EQUAL(self->password, _password, self->status.isEdited);
}
- (NSString *)password {
  return self->password;
}

- (void)setLogin:(NSString *)_login {
  ASSIGNCOPY_IFNOT_EQUAL(self->login, _login, self->status.isEdited);
}
- (NSString *)login {
  return self->login;
}

- (void)setNumber:(NSString *)_number {
  ASSIGNCOPY_IFNOT_EQUAL(self->number, _number, self->status.isEdited);
}
- (NSString *)number {
  return self->number;
}


- (NSNumber *)objectVersion {
  return self->objectVersion;
}
- (BOOL)isLocked {
  return self->isLocked;
}
- (BOOL)isExtraAccount {
  return self->isExtraAccount;
}

- (id)asEO {
  [self->eo takeValue:[self password]      forKey:@"password"];
  [self->eo takeValue:[self login]         forKey:@"login"];
  [self->eo takeValue:[self number]        forKey:@"number"];
  [self->eo takeValue:[self objectVersion] forKey:@"objectVersion"];
  [self->eo takeValue:[NSNumber numberWithBool:[self isLocked]]
       forKey:@"isLocked"];
  [self->eo takeValue:[NSNumber numberWithBool:[self isExtraAccount]]
       forKey:@"isExtraAccount"];

  return self->eo;
}

- (BOOL)isEqual:(id)_other {
  if (_other == self)
    return YES;
  
  if (![_other isKindOfClass:[self class]])
    return NO;
  
  if (![[_other globalID] isEqual:[self globalID]])
    return NO;

  /* docs have same global-id, but could be in different editing state .. */
  
  if (![_other isEdited] && ![self isEdited])
    return YES;
  
  return NO;
}


- (SkyAccountTeamsDataSource *)teamsDataSource {
  id ds = [[SkyAccountTeamsDataSource alloc] initWithContext:[self context]
                                             account:self->eo];
  return AUTORELEASE(ds);
}
- (NSArray *)teams {
  return [[self teamsDataSource] fetchObjects];
}
/* actions */

- (BOOL)reload {
  if ([self isValid] == NO)
    return NO;

  RELEASE(self->login);        self->login    = nil;
  RELEASE(self->password);     self->password = nil;
  RELEASE(self->number);       self->number   = nil;

  return YES;
}

- (NSDictionary *)asDict {
  NSMutableDictionary *dict;
  NSNumber            *companyId;

  dict      = [NSMutableDictionary dictionaryWithCapacity:16];
  companyId = [[(EOKeyGlobalID *)self->globalID keyValuesArray] lastObject];

  if (companyId != nil)
    [dict setObject:companyId forKey:@"companyId"];

  [dict takeValue:[self firstname]     forKey:@"firstname"];
  [dict takeValue:[self middlename]    forKey:@"middlename"];
  [dict takeValue:[self name]          forKey:@"name"];
  [dict takeValue:[self login]         forKey:@"login"];
  [dict takeValue:[self password]      forKey:@"password"];
  [dict takeValue:[self number]        forKey:@"number"];
  [dict takeValue:[self objectVersion] forKey:@"objectVersion"];

  [dict takeValue:[NSNumber numberWithBool:[self isLocked]]
                            forKey:@"isLocked"];
  [dict takeValue:[NSNumber numberWithBool:[self isExtraAccount]]
                            forKey:@"isExtraAccount"];

  return dict;
}

- (void)logException:(NSException *)_exception {
  NSLog(@"%s: catched exception: %@", __PRETTY_FUNCTION__, _exception);
}

- (BOOL)save {
  BOOL result = YES;

  if (self->status.isEdited == NO) return YES;
  if (![self isComplete])          return NO;
  
  NS_DURING {
    if (self->globalID == nil) {
      [self->dataSource insertObject:self];
    }
    else {
      [self->dataSource updateObject:self];
    }
    self->status.isEdited = NO;
  }
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  return result;
}


@end /* SkyAccountDocument */

@implementation SkyAccountDocument(PrivateMethodes)

- (void)_registerForGID {
  if (self->globalID) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(invalidate)
                                          name:SkyGlobalIDWasDeleted
                                          object:self->globalID];
  }
}

- (void)_setObjectVersion:(NSNumber *)_version {
  ASSIGNCOPY_IFNOT_EQUAL(self->objectVersion,_version,self->status.isEdited);
}
- (void)_setIsLocked:(BOOL)_flag {
  if (self->isLocked != _flag)
    self->status.isEdited = YES;
  self->isLocked = _flag;
}
- (void)_setIsExtraAccount:(BOOL)_flag {
  if (self->isExtraAccount != _flag)
    self->status.isEdited = YES;
  self->isExtraAccount = _flag;
}

@end /* SkyAccountDocument(PrivateMethodes) */
