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

#include "SkyTeamDocument.h"
#include "SkyMemberDataSource.h"
#include "common.h"

@implementation SkyTeamDocumentType
@end /* SkyTeamDocumentType */

@interface NSObject(GID)
- (EOGlobalID *)globalID;
@end

@interface SkyTeamDocument(PrivateMethodes)
- (void)_setObjectVersion:(NSNumber *)_version;
- (void)_registerForGID;
@end

@implementation SkyTeamDocument

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil; // THREAD
  if (nc == nil)
    nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}

// designated initializer
- (id)initWithTeam:(id)_account
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds
{
  if ((self = [super init])) {
    [self _setObjectVersion:[_account valueForKey:@"objectVersion"]];
    
    self->dataSource = [_ds  retain];
    self->globalID   = [_gid retain];
    self->eo         = [_account retain];
    [self _registerForGID];
    
    [self setLogin:     [_account valueForKey:@"login"]];
    [self setInfo:      [_account valueForKey:@"description"]];
    [self setNumber:    [_account valueForKey:@"number"]];
    [self setEmail:     [_account valueForKey:@"email"]];
    
    self->status.isComplete  = YES;
    self->status.isValid     = YES;
    self->status.isEdited    = NO;
  }
  return self;
}

- (id)initWithTeam:(id)_account dataSource:(EODataSource *)_ds {
  EOKeyGlobalID *gid;

  gid = ([_account respondsToSelector:@selector(globalID)])
    ? (EOKeyGlobalID *)[_account globalID]
    : [_account valueForKey:@"globalID"];
  
  return [self initWithTeam:_account globalID:gid dataSource:_ds];
}

- (id)initWithGlobalID:(EOGlobalID *)_gid dataSource:(EODataSource *)_ds {
  return [self initWithTeam:nil globalID:_gid dataSource:_ds];
}

- (void)dealloc {
  [[self notificationCenter] removeObserver:self];
  
  [self->dataSource    release];
  [self->globalID      release];
  [self->eo            release];
  [self->number        release];
  [self->login         release];
  [self->info          release];
  [self->objectVersion release];
  [self->email         release];
  [super dealloc];
}

- (SkyDocumentType *)documentType {
  static SkyTeamDocumentType *docType = nil;
  
  if (docType == nil)
    docType = [[SkyTeamDocumentType alloc] init];

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

- (void)setInfo:(NSString *)_info {
  ASSIGNCOPY_IFNOT_EQUAL(self->info, _info, self->status.isEdited);
}
- (NSString *)info {
  return self->info;
}

- (void)setEmail:(NSString *)_email {
  ASSIGNCOPY_IFNOT_EQUAL(self->email, _email, self->status.isEdited);
}
- (NSString *)email {
  return self->email;
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

- (BOOL)isTeam { return YES; }

- (NSNumber *)objectVersion {
  return self->objectVersion;
}

- (id)asEO {
  [self->eo takeValue:[self info]          forKey:@"description"];
  [self->eo takeValue:[self login]         forKey:@"login"];
  [self->eo takeValue:[self number]        forKey:@"number"];
  [self->eo takeValue:[self objectVersion] forKey:@"objectVersion"];

  return self->eo;
}

- (SkyMemberDataSource *)memberDataSource {
  id ds = [[SkyMemberDataSource alloc] initWithContext:[self context]
                                       team:self->eo];

  return [ds autorelease];
}
- (NSArray *)members {
  return [[self memberDataSource] fetchObjects];
}

/* actions */

- (BOOL)reload {
  if ([self isValid] == NO)
    return NO;

  [self->login  release]; self->login  = nil;
  [self->info   release]; self->info   = nil;
  [self->number release]; self->number = nil;

  return YES;
}

- (BOOL)save {
  if (![self globalID]) {
    NSLog(@"WARNING: %s not able to save yet", __PRETTY_FUNCTION__);
    return NO;
  }
  [self->dataSource updateObject:self];
  self->status.isEdited    = NO;
  return YES;
}

- (id)companyId {
  return [[(EOKeyGlobalID *)[self globalID] keyValuesArray] lastObject];
}

/* private methods */

- (void)_registerForGID {
  if (self->globalID == nil)
    return;
  
  [[self notificationCenter] addObserver:self
                             selector:@selector(invalidate)
                             name:SkyGlobalIDWasDeleted
                             object:self->globalID];
}

- (void)_setObjectVersion:(NSNumber *)_version {
  ASSIGNCOPY_IFNOT_EQUAL(self->objectVersion,_version,self->status.isEdited);
}

@end /* SkyTeamDocument */
