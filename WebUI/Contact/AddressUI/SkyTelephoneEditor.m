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

#include <OGoFoundation/LSWEditorPage.h>

@class NSMutableDictionary, NSArray;

@interface SkyTelephoneEditor : LSWEditorPage
{
@protected
  NSMutableDictionary *snapshots;
  id                  teleType;
  id                  company;
  BOOL                createNewTeleTypes;
  BOOL                telephonesAreFetched;
}

- (NSArray *)teleTypes;

@end

#include "common.h"
#include <OGoFoundation/LSWNotifications.h>
#include <GDLAccess/EOEntity+Factory.h>

@implementation SkyTelephoneEditor

static int cmpTypes(id t1, id t2, void* context) {
  return [(NSString *)t1 compare:(NSString *)t2];
}

- (id)init {
  if ((self = [super init])) {
    self->snapshots = [[NSMutableDictionary alloc] initWithCapacity:6];
    self->createNewTeleTypes   = YES;
    self->telephonesAreFetched = NO;
  }
  return self;
}

- (void)dealloc {
  [self->snapshots release];
  [self->teleType  release];
  [self->company   release];
  [super dealloc];
}

/* operations */

- (void)_createNewTeleTypes {
  id  typeDict;
  NSArray *types   = nil;

  typeDict = [[[self session] userDefaults] objectForKey:@"LSTeleType"];
  
  if (self->telephonesAreFetched == NO)
    return;
  
  if (self->company == nil) {
    NSLog(@"Warning: Cannot check userDefaults for new teleTypes!!! "
          @"(company entity is unknown)");
    return;
  }
  types = [typeDict valueForKey:[self->company entityName]];

  {
    NSArray      *oldTypes;
    NSEnumerator *typeEnum;
    NSZone       *z;
    id           type      = nil;

    oldTypes = [self teleTypes];
    typeEnum = [types objectEnumerator];
    z        = [self zone];
    
    while ((type = [typeEnum nextObject])) {
      if (![oldTypes containsObject:type]) {
        id                  newPhone = nil;
        NSMutableDictionary *dict;
        NSNumber            *cmpId;
        
        dict = [NSMutableDictionary dictionaryWithCapacity:2];
        cmpId   = [self->company valueForKey:@"companyId"];
        
        [dict setObject:type   forKey:@"type"];
        [dict setObject:cmpId  forKey:@"companyId"];
        
        newPhone = [self runCommand:@"telephone::new" arguments:dict];

        {
          NSArray *keys = [[newPhone entity] attributeNames];

          dict = [[newPhone valuesForKeys:keys] mutableCopyWithZone:z];
          [self->snapshots setObject:dict forKey:type];
        }
      }
    }
  }
  self->createNewTeleTypes = NO;
}

- (void)_fetchSnaphotsWith:(NSArray *)_telephones {
  NSEnumerator *phoneEnum;
  id           phone      = nil;

  phoneEnum = [_telephones objectEnumerator];
  
  [self->snapshots removeAllObjects];

  while ((phone = [phoneEnum nextObject])) {
    NSArray             *keys;
    NSMutableDictionary *dict;
    
    keys = [[phone entity] attributeNames];
    dict = [[phone valuesForKeys:keys] mutableCopy];
    
    [self->snapshots setObject:dict forKey:[phone valueForKey:@"type"]];
  }
  self->telephonesAreFetched = YES;
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];

  if (self->createNewTeleTypes)
    [self _createNewTeleTypes];
}

/* accessors */

- (void)setCompany:(id)_company {
  ASSIGN(self->company, _company);
}
- (id)company {
  return self->company;
}

- (NSArray *)teleTypes {
  return [[self->snapshots allKeys]
                  sortedArrayUsingFunction:cmpTypes context:NULL];
}

- (void)setTeleType:(NSString *)_teleType {
  ASSIGNCOPY(self->teleType, _teleType);
}
- (NSString *)teleType {
  return self->teleType;
}

- (void)setTelephones:(NSArray *)_telephones {
  [self _fetchSnaphotsWith:_telephones];
}

- (void)setTelephone:(NSMutableDictionary *)_telephone {
  [self->snapshots setObject:_telephone forKey:self->teleType];
}
- (NSMutableDictionary *)telephone {
  return [self->snapshots objectForKey:self->teleType];
}

- (NSString *)insertNotificationName {
  return LSWNewAddressNotificationName;
}

/* teletype */

- (NSString *)telephoneType {
  NSString *str;
  
  str = [[self labels] valueForKey:self->teleType];
  return (str == nil) ? self->teleType : str;
}

- (NSString *)textFieldNumberName {
  return [[self->teleType stringValue] stringByAppendingString:@"number"];
}
- (NSString *)textFieldInfoName {
  return [[self->teleType stringValue] stringByAppendingString:@"info"];
}

/* actions */

- (id)save {
  NSEnumerator *phoneEnum;
  id           phone      = nil;

  phoneEnum = [[self->snapshots allValues] objectEnumerator];
  
  while ((phone = [phoneEnum nextObject])) {
    [self runCommand:@"telephone::set" arguments:phone];
  }
  if (self->company)
    [self runCommand:@"object::increase-version",
                     @"object", self->company, nil];
  
  return [self backWithCount:1];
}

@end /* SkyTelephoneEditor */
