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

#include "SkyContactAddressDataSource.h"
#include "SkyAddressDocument.h"
#import <Foundation/Foundation.h>
#include <EOControl/EOControl.h>

#include <LSFoundation/LSFoundation.h>
#include <NGExtensions/NGExtensions.h>

@interface NSObject(UsedPrivates)
- (void)_setGlobalID:(EOGlobalID *)_gid;
@end

@implementation SkyContactAddressDataSource

- (id)initWithContext:(id)_context contact:(id)_gid {
  if (_context == nil) {
#if DEBUG
    NSLog(@"WARNING(%s): missing context for datasource creation ..",
          __PRETTY_FUNCTION__);
#endif
    [self release];
    return nil;
  }
  if ((self = [super init])) {
    ASSIGN(self->context,_context);
    if (![_gid isKindOfClass:[EOKeyGlobalID class]]) {
      _gid = [_gid valueForKey:@"globalID"];
    }
    ASSIGN(self->contactGID,_gid);
  }
  return self;
}

- (id)init {
  return [self initWithContext:nil contact:nil];
}

- (void)dealloc {
  [self->contactGID release];
  [self->context    release];
  [self->fetchSpecification release];
  [super dealloc];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if ([self->fetchSpecification isEqual:_fSpec]) return;

  ASSIGNCOPY(self->fetchSpecification, _fSpec);
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return [[self->fetchSpecification copy] autorelease];
}

- (id)context {
  return self->context;
}

// subclass responisiblity
- (NSString *)contactType {
#if LIB_FOUNDATION_LIBRARY
  return [self subclassResponsibility:_cmd];
#else
  [self logWithFormat:@"ERROR: subclass should override %s", 
          __PRETTY_FUNCTION__];
  return nil;
#endif
}
- (NSArray *)validAddressTypes {
#if LIB_FOUNDATION_LIBRARY
  return [self subclassResponsibility:_cmd];
#else
  [self logWithFormat:@"ERROR: subclass should override %s", 
          __PRETTY_FUNCTION__];
  return nil;
#endif
}

/* fetching */

- (NSArray *)_fetchEOs {
  NSArray *eos = nil;

  eos = [self->context runCommand:@"address::get",
             @"companyId",  [[self->contactGID keyValuesArray] lastObject],
             @"returnType", intObj(LSDBReturnType_ManyObjects),
             nil];
  return eos;
}

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  BOOL           addAsObserver = YES;
  NSMutableArray *result       = nil;
  NSDictionary   *hints        = nil;
  int            i, count;

  if (_eos == nil)
    return nil;
  if ((count = [_eos count]) == 0)
    return [NSArray array];

  result = [NSMutableArray arrayWithCapacity:(count + 1)];

  hints  = [self->fetchSpecification hints];
  if ([hints objectForKey:@"addDocumentsAsObserver"])
    addAsObserver = [[hints objectForKey:@"addDocumentsAsObserver"] boolValue];

  for (i = 0; i < count; i++) {
    id addr;
    addr = [_eos objectAtIndex:i];
    addr = [[SkyAddressDocument alloc]
                                initWithObject:addr
                                globalID:[addr valueForKey:@"globalID"]
                                dataSource:self
                                addAsObserver:addAsObserver];
    [result addObject:addr];
    [addr release];
  }
  return result;
}

- (NSArray *)fetchObjects {
  NSArray *sortOrderings = nil;
  NSArray *addrs         = nil;

  addrs         = [self _fetchEOs];
  addrs         = [self _morphEOsToDocuments:addrs];
  sortOrderings = [self->fetchSpecification sortOrderings];

  if (addrs == nil)
    addrs = [NSArray array];

  if (sortOrderings != nil)
    addrs = [addrs sortedArrayUsingKeyOrderArray:sortOrderings];

  return addrs;
}

- (SkyAddressDocument *)createObject {
#if 1
  SkyAddressDocument  *doc = nil;
  NSMutableDictionary *src =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         @"", @"name1",
                         @"", @"name2",
                         @"", @"name3",
                         @"", @"street",
                         @"", @"zip",
                         @"", @"city",
                         @"", @"country",
                         @"", @"state",
                         [[self validAddressTypes] lastObject], @"type",
                         nil];
  doc = [[SkyAddressDocument alloc] initWithObject:src
                                    globalID:nil
                                    dataSource:self];
  return [doc autorelease];
#else
  return nil;
#endif
}

- (void)insertObject:(SkyAddressDocument *)_object {
  id dict = [_object asDict];
  
  dict = [self->context runCommand:@"address::new" arguments:dict];
  [_object _setGlobalID:[dict valueForKey:@"globalID"]];
  
  [self postDataSourceChangedNotification];
}
- (void)deleteObject:(SkyAddressDocument *)_object {
  id dict = [_object asDict];
  [self->context runCommand:@"address::delete" arguments:dict];
  [self postDataSourceChangedNotification];
}
- (void)updateObject:(SkyAddressDocument *)_object {
  id dict = [_object asDict];
  [self->context runCommand:@"address::set" arguments:dict];
  [self postDataSourceChangedNotification];
}

@end /* SkyContactAddressDataSource */
