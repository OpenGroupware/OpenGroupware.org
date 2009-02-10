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

#include <OGoDocuments/SkyDocumentType.h>
#include "SkyAddressDocument.h"
#include "SkyContactAddressDataSource.h"
#include <EOControl/EOKeyGlobalID.h>
#include "common.h"

@interface SkyAddressDocumentType : SkyDocumentType
@end /* SkyAddressDocumentType */

@implementation SkyAddressDocumentType
@end /* SkyAddressDocumentType */

@interface SkyAddressDocument(PrivateMethodes)
- (void)_registerForGID;
- (void)_loadDocument:(id)_object;
@end /* SkyAddressDocument(PrivateMethodes) */

@implementation SkyAddressDocument

- (id)initWithGlobalID:(EOGlobalID *)_gid
  context:(id)_context
{
  SkyContactAddressDataSource *ds  = nil;
  id                          addr = nil;

  if ([[_gid entityName] isEqualToString:@"Address"]) {
    EOKeyGlobalID *contactGID;
    id            values[1];


    addr = [[_context runCommand:@"address::get",
                     @"addressId", [[(EOKeyGlobalID *)_gid keyValuesArray]
                                                    lastObject],
                     nil] lastObject];
    values[0] = [addr valueForKey:@"companyId"];

    // ??? entityName should be Person or Enterprise!!!
    contactGID = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                                keys:values
                                keyCount:1
                                zone:[self zone]];
    
    ds = [[SkyContactAddressDataSource alloc]
                                       initWithContext:_context
                                       contact:contactGID];
  }
  return [self initWithObject:addr globalID:_gid dataSource:AUTORELEASE(ds)];
}

- (id)initWithObject:(id)_address
  globalID:(EOGlobalID *)_gid
  dataSource:(SkyContactAddressDataSource *)_ds
  addAsObserver:(BOOL)_addAsObserver
{
  if ((self = [super init])) {
    self->addAsObserver = _addAsObserver;
    self->globalID   = [_gid retain];
    self->dataSource = [_ds  retain];
    
    [self _loadDocument:_address];
    [self _registerForGID];
  }
  return self;
}

- (id)initWithObject:(id)_address
  globalID:(EOGlobalID *)_gid
  dataSource:(SkyContactAddressDataSource *)_ds
{
  return [self initWithObject:_address
               globalID:_gid
               dataSource:_ds
               addAsObserver:YES];
}

- (id)initWithObject:(id)_address
  dataSource:(SkyContactAddressDataSource *)_ds
{
  NSNumber   *pk;
  EOGlobalID *gid;
  
  pk  = [_address valueForKey:@"addressId"];
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Address"
                       keys:&pk keyCount:1 zone:NULL];

  return [self initWithObject:_address globalID:gid dataSource:_ds];
}

- (id)initWithGlobalID:(EOGlobalID *)_gid
  dataSource:(SkyContactAddressDataSource *)_ds
{
  return [self initWithObject:nil globalID:_gid dataSource:_ds];
}

- (id)init {
  return [self initWithObject:nil globalID:nil dataSource:nil];
}

- (id)initWithContext:(id)_context {
  EODataSource *ds;

  ds = [[SkyContactAddressDataSource alloc] initWithContext:_context
                                            contact:nil];
  return [self initWithGlobalID:nil dataSource:[ds autorelease]];
}

- (void)dealloc {
  if (self->addAsObserver)
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [self->globalID       release];
  [self->dataSource     release];
  [self->name1          release];
  [self->name2          release];
  [self->name3          release];
  [self->street         release];
  [self->zip            release];
  [self->city           release];
  [self->country        release];
  [self->state          release];
  [self->type           release];
  [self->companyId      release];
  [self->objectVersion  release];
  
  [super dealloc];
}

/* tracking modification */

- (BOOL)isValid {
  if (!self->status.isValid) {
    [self logWithFormat:@"WARNING[%s]: call for invalid SkyAddressDocument",
          __PRETTY_FUNCTION__];
  }
  return self->status.isValid;
}

- (void)invalidate {
  RELEASE(self->name1);     self->name1     = nil;
  RELEASE(self->name2);     self->name2     = nil;
  RELEASE(self->name3);     self->name3     = nil;
  RELEASE(self->street);    self->street    = nil;
  RELEASE(self->zip);       self->zip       = nil;
  RELEASE(self->city);      self->city      = nil;
  RELEASE(self->country);   self->country   = nil;
  RELEASE(self->state);     self->state     = nil;
  RELEASE(self->companyId); self->companyId = nil;

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  RELEASE(self->globalID); self->globalID = nil;
  self->status.isValid = NO;
}
- (void)invalidate:(NSNotification *)_notification {
  [self invalidate];
}

- (BOOL)isNew {
  return (self->globalID == nil) ? YES : NO;
}

- (BOOL)isEdited {
  return (self->globalID == nil || self->status.isEdited) ? YES : NO;
}

- (BOOL)isComplete {
  if ([self isValid] == NO)
    return NO;

  return self->status.isComplete;
}

/* attributes */

- (EOGlobalID *)globalID {
  return self->globalID;
}

- (void)setName1:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->name1, _name, self->status.isEdited);
}
- (NSString *)name1 {
  return self->name1;
}

- (void)setName2:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->name2, _name, self->status.isEdited);
}
- (NSString *)name2 {
  return self->name2;
}

- (void)setName3:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->name3, _name, self->status.isEdited);
}
- (NSString *)name3 {
  return self->name3;
}

- (void)setStreet:(NSString *)_street {
  ASSIGNCOPY_IFNOT_EQUAL(self->street, _street, self->status.isEdited);
}
- (NSString *)street {
  return self->street;
}

- (void)setZip:(NSString *)_zip {
  ASSIGNCOPY_IFNOT_EQUAL(self->zip, _zip, self->status.isEdited);
}
- (NSString *)zip {
  return self->zip;
}

- (void)setCity:(NSString *)_city {
  ASSIGNCOPY_IFNOT_EQUAL(self->city, _city, self->status.isEdited);
}
- (NSString *)city {
  return self->city;
}

- (void)setCountry:(NSString *)_country {
  ASSIGNCOPY_IFNOT_EQUAL(self->country, _country, self->status.isEdited);
}
- (NSString *)country {
  return self->country;
}

- (void)setState:(NSString *)_state {
  ASSIGNCOPY_IFNOT_EQUAL(self->state, _state, self->status.isEdited);
}
- (NSString *)state {
  return self->state;
}

- (void)setType:(NSString *)_type {
  ASSIGNCOPY_IFNOT_EQUAL(self->type, _type, self->status.isEdited);
}
- (NSString *)type {
  return self->type;
}

- (void)setObjectVersion:(NSNumber *)_objectVersion {
  ASSIGNCOPY_IFNOT_EQUAL(self->objectVersion, _objectVersion, self->status.isEdited);
}
- (NSNumber *)objectVersion {
  return self->objectVersion;
}

/* eo commands support */
- (id)asDict {
  NSMutableDictionary *dict;
  NSNumber            *addressId;

  dict      = [NSMutableDictionary dictionaryWithCapacity:16];
  addressId = [[(EOKeyGlobalID *)self->globalID keyValuesArray] lastObject];

  if (addressId != nil)
    [dict setObject:addressId      forKey:@"addressId"];
 
  [dict takeValue:[self name1]    forKey:@"name1"];
  [dict takeValue:[self name2]    forKey:@"name2"];
  [dict takeValue:[self name3]    forKey:@"name3"];
  [dict takeValue:[self street]   forKey:@"street"];
  [dict takeValue:[self zip]      forKey:@"zip"];
  [dict takeValue:[self city]     forKey:@"city"];
  [dict takeValue:[self country]  forKey:@"country"];
  [dict takeValue:[self state]    forKey:@"state"];
  [dict takeValue:[self type]     forKey:@"type"];
  [dict takeValue:self->companyId forKey:@"companyId"];
  [dict takeValue:self->objectVersion forKey:@"objectVersion"];
  
  return dict;
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


/* actions */

- (void)logException:(NSException *)_exception {
  NSLog(@"%s: catched exception: %@", __PRETTY_FUNCTION__, _exception);
}

- (BOOL)save {
  BOOL result = YES;

  if (self->status.isEdited == NO) return YES;
  if (self->companyId == nil) return YES;
  
  NS_DURING {
    if (self->globalID == nil)
      [self->dataSource insertObject:self];
    else
      [self->dataSource updateObject:self];
    self->status.isEdited = NO;
  }
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)delete {
  BOOL result = YES;
  
  NS_DURING
    [self->dataSource deleteObject:self];
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)reload {
  if ([self isValid] == NO)
    return NO;

  if ([self globalID] == nil) {
    [self invalidate];
  }
  else {
    id obj;

    obj = [[[self context] runCommand:@"object::get-by-globalid",
                           @"gid", [self globalID], nil] lastObject];
    [self _loadDocument:obj];
  }
  
  return YES;
}

@end /* SkyAddressDocument */


@implementation SkyAddressDocument(PrivateMethodes)

- (void)_registerForGID {
  if (!self->addAsObserver) return;

  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"DebugDocumentRegistration"]) {
    NSLog(@"++++++++++++++++++ Warning: register Document"
          @" in NotificationCenter(%s)",
          __PRETTY_FUNCTION__);
  }
  
  if (self->globalID) {
    [[NSNotificationCenter defaultCenter]
                           addObserver:self
                           selector:@selector(invalidate:)
                           name:SkyGlobalIDWasDeleted
                           object:self->globalID];
  }
}

- (void)_setGlobalID:(id)_gid {
  if (self->globalID == nil) {
    ASSIGN(self->globalID,_gid);
    [self _registerForGID];
  }
}

- (void)_setCompanyId:(id)_companyId {
  ASSIGNCOPY_IFNOT_EQUAL(self->companyId, _companyId, self->status.isEdited);
}

- (void)_loadDocument:(id)_object {
  [self setName1:      [_object valueForKey:@"name1"]];
  [self setName2:      [_object valueForKey:@"name2"]];
  [self setName3:      [_object valueForKey:@"name3"]];
  [self setStreet:     [_object valueForKey:@"street"]];
  [self setZip:        [_object valueForKey:@"zip"]];
  [self setCity:       [_object valueForKey:@"city"]];
  [self setCountry:    [_object valueForKey:@"country"]];
  [self setState:      [_object valueForKey:@"state"]];
  [self setType:       [_object valueForKey:@"type"]];
  [self setObjectVersion: [_object valueForKey:@"objectVersion"]];
  [self _setCompanyId: [_object valueForKey:@"companyId"]];

  self->status.isValid    = YES;
  self->status.isComplete = YES;
  self->status.isEdited   = NO;
}

@end /* SkyAddressDocument(PrivateMethodes) */
