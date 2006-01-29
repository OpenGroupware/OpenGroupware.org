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

#include <OGoFoundation/SkyEditorPage.h>

@class NSString, NSData;

@interface SkyPersonEditor : SkyEditorPage
{
  BOOL     deleteImage;
  NSData   *pictureData;
  NSString *pictureFilePath;
  BOOL     limitAccessToCreator; // only if isNew
  NSString *addressType;
}

- (id)person;

@end

// TODO: this code should be cleaned up !

#include "common.h"
#include <GDLAccess/EONull.h>
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoContacts/SkyPersonDataSource.h>

@interface SkyPersonEditor(PrivateMethodes)
- (NSString *)_violatedUniqueKeyName;
@end

@implementation SkyPersonEditor

- (void)dealloc {
  [self->pictureFilePath release];
  [self->pictureData     release];
  [self->addressType     release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cfg
{
  BOOL r;
  id   obj;

  r = [super prepareForActivationCommand:_command
	     type:_type configuration:_cfg];
  
  if (![[self object] isKindOfClass:[SkyDocument class]]) {
    obj = [[self object] globalID];
    obj = [self runCommand:@"object::get-by-globalid", @"gid", obj, nil];
    obj = [obj lastObject];
    [self setObject:obj];
  }
  
  obj = [self object];
    
  if ([obj respondsToSelector:@selector(setBirthday:)] &&
      ![[obj valueForKey:@"birthday"] isNotNull]) {
    [obj setBirthday:(id)[EONull null]];
  }
  
  return r;
}

- (NSString *)windowTitle {
  return [[self labels] valueForKey:[self isInNewMode]
                        ? @"persons_new_person_title"
                        : @"person_editor_title"];
}

/* accessors */

- (id)person {
  return [self object];
}

- (SkyDocument *)addressDocument {
  return [[self person] addressForType:[self valueForKey:@"addressType"]];
}

/* callback for LSWObjectEditor */
- (id)couldNotFormatBirthday {
  [[self person] setBirthday:nil];
  return nil;
}

- (void)setAddressType:(NSString *)_data {
  ASSIGN(self->addressType, _data);
}
- (id)addressType {
  return self->addressType;
}

/* picture */

- (void)setData:(id)_data {
  ASSIGN(self->pictureData, _data);
}
- (id)data {
  return self->pictureData;
}

- (void)setFilePath:(id)_path {
  ASSIGNCOPY(self->pictureFilePath, _path);
}
- (id)filePath {
  return self->pictureFilePath;
}

- (BOOL)hasImage {
  return [[[self person] imageData] length] > 0;
}

- (void)setDeleteImage:(BOOL)_del {
  self->deleteImage = _del;
}
- (BOOL)deleteImage {
  return self->deleteImage;
}

- (void)setLimitAccessToCreator:(BOOL)_flag {
  self->limitAccessToCreator = _flag;
}
- (BOOL)limitAccessToCreator {
  return self->limitAccessToCreator;
}

- (BOOL)isCompanyIdRoot:(NSNumber *)_pkey {
  // TODO: remove direct check for 10000
  return [_pkey intValue] == 10000 ? YES : NO;
}

- (BOOL)isDeleteEnabled {
  // TODO: remove direct check for 10000
  id obj;
  
  if ([self isInNewMode])
    return NO; /* no delete button in new-mode ... */

  obj = [self object];
  
  if ([self isCompanyIdRoot:[obj companyId]])
    return NO; /* forbid deletion of root account */
  
  return ![obj isAccount];
  /* user = [[self person] owner] */
}

- (BOOL)isOwnerLoggedInOrNew {
  NSNumber *accountId;
  
  if ([self isInNewMode])
    return YES;
  
  accountId = [[[self session] activeAccount] valueForKey:@"companyId"];
  return [accountId isEqual:[[self object] valueForKey:@"ownerId"]];
}

- (BOOL)checkConstraintsForSave {
  NSMutableString *error;
  NSString        *lname;
  id              labels;

  labels = [self labels];
  error  = [NSMutableString stringWithCapacity:128];
  lname  = [[self person] valueForKey:@"name"];
  
  if (![lname isNotEmpty])
    [error appendString:[labels valueForKey:@"error_no_name"]];

  if ([[self person] birthday] == nil)
    [error appendString:[labels valueForKey:@"error_birthday_format"]];

  if ([error isNotEmpty]) {
    [self setErrorString:error];
    return NO;
  }

  [self setErrorString:nil];
  return [super checkConstraintsForSave];
}

- (BOOL)isAccessRightEnabled {
  return YES;
}

- (void)postAccessChangedNotification:(EOGlobalID *)objectGID {
  [[NSNotificationCenter defaultCenter]
    postNotificationName:@"SkyAccessHasChangedNotification"
    object:objectGID userInfo:nil];
}

- (id)save {
  NSString *key   = nil;
  id       result;

  result = [super save];
  
  if ([self isAccessRightEnabled]) {
    if (result != nil && ([self isInNewMode]) && self->limitAccessToCreator) {
      OGoSession       *sn;
      SkyAccessManager *manager;
      EOGlobalID *accessGID, *objectGID;
      
      sn        = [self session];
      manager   = [[sn commandContext] accessManager];
      accessGID = [[sn activeAccount] globalID];
      objectGID = [[self person] globalID];
      
      if (![manager setOperation:@"rw" onObjectID:objectGID
                    forAccessGlobalID:accessGID]) {
	[self logWithFormat:
		@"%s: cannot save limited access for creator %@ to person %@",
                __PRETTY_FUNCTION__, accessGID, objectGID];
      }
      else
	[self postAccessChangedNotification:objectGID];
    }
  }

  if (result) {
    if ([self deleteImage] || ([[self data] length] > 0 &&
			       [[self filePath] isNotEmpty])) {
      [[self person] setImageData:[self data] filePath:[self filePath]];
    }
    return result;
  }
  
  if ((key = [self _violatedUniqueKeyName]) != nil) {
    NSMutableString *str;
    
    str = [[NSMutableString alloc] initWithCapacity:128];
    [str appendString:[[self labels] valueForKey:@"couldNotSavePerson"]];
    [str appendString:@". "];
    [str appendString:[[self labels] valueForKey:@"fieldMustBeUnique"]];
    [str appendString:@": "];
    [str appendString:[[self labels] valueForKey:key]];
    [self setErrorString:str];
    [str release]; str = nil;
    return nil;
  }
  
  return nil;
}

/* PrivateMethodes */

- (BOOL)_isKeyViolated:(NSString *)_key {
  static id searchRec = nil;  
  NSArray   *list;
  unsigned  maxCount;
  
  if (searchRec == nil) {
    searchRec = [self runCommand:@"search::newrecord",
                                  @"entity", @"Person", nil];
    [searchRec setComparator:@"EQUAL"];
    searchRec = [searchRec retain];
  }
  
  [searchRec takeValue:[[self object] valueForKey:_key] forKey:_key];
  list = [self runCommand:@"person::extended-search",
               @"operator",       @"OR",
               @"searchRecords",  [NSArray arrayWithObject:searchRec],
               @"fetchIds",       [NSNumber numberWithBool:YES],
               @"maxSearchCount", [NSNumber numberWithInt:2],
               nil];
  
  maxCount  = [self isInNewMode] ? 0 : 1;
  return ([list count] > maxCount) ? YES : NO;
}

- (NSString *)_violatedUniqueKeyName {
  if ([self _isKeyViolated:@"number"])
    return @"number";
  if ([self _isKeyViolated:@"login"])
    return @"login";
  
  return nil;
}

- (id)doNothing {
  return nil;
}

@end /* SkyPersonEditor */
