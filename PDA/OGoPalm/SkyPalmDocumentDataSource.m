/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include <OGoPalm/SkyPalmDocumentDataSource.h>
#include <OGoPalm/SkyPalmAddressDocument.h>
#include <OGoPalm/SkyPalmDateDocument.h>
#include <OGoPalm/SkyPalmMemoDocument.h>
#include <OGoPalm/SkyPalmJobDocument.h>

@implementation SkyPalmDocumentDataSource

- (id)init {
  if ((self = [super init])) {
    self->defaultDevice = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->defaultDevice);
  [super dealloc];
}
#endif

// accessors
- (void)setDefaultDevice:(NSString *)_dev {
  ASSIGN(self->defaultDevice,_dev);
}
- (NSString *)defaultDevice {
  return self->defaultDevice;
}

// overwrite these methods
- (NSString *)palmDb {
  // warning
  return nil;
}
- (SkyPalmDocument *)allocDocument {
  NSString *p = [self palmDb];
  if ([p isEqualToString:@"AddressDB"])
    return [SkyPalmAddressDocument alloc];
  if ([p isEqualToString:@"DatebookDB"])
    return [SkyPalmDateDocument alloc];
  if ([p isEqualToString:@"MemoDB"])
    return [SkyPalmMemoDocument alloc];
  if ([p isEqualToString:@"ToDoDB"])
    return [SkyPalmJobDocument alloc];
  return nil;
}
- (void)insertObject:(SkyPalmDocument *)_doc {
  // warning
}
- (void)updateObject:(SkyPalmDocument *)_doc {
  // warning
}
- (void)deleteObject:(SkyPalmDocument *)_doc {
  // warning
}
- (NSArray *)devices {
  return nil;
}
- (NSArray *)categoriesForDevice:(NSString *)_dev {
  return nil;
}
- (NSArray *)saveCategories:(NSArray *)_cats 
                  forDevice:(NSString *)_dev
{
  return nil;
}
- (NSNumber *)companyId {
  return nil;
}
- (NSString *)primaryKey {
  return @"palm_id";
}
- (id)currentAccount {
  return nil;
}
- (id)fetchDictionaryForDocument:(SkyPalmDocument *)_doc {
  return nil;
}

// till here

- (SkyPalmDocument *)documentForObject:(id)_obj {
  SkyPalmDocument *doc =
    [[self allocDocument] initWithDictionary:_obj
                          fromDataSource:self];
  return AUTORELEASE(doc);
}
- (SkyPalmDocument *)newDocument {
  SkyPalmDocument *doc =
    [[self allocDocument] initAsNewFromDataSource:self];
  return AUTORELEASE(doc);
}

- (void)dotLog {
  // this method isn't used here
  // but overwritten in the special nhs device datasource to prevent timeouts
  // ...
  NSLog(@"%s preventing timeout ...", __PRETTY_FUNCTION__);
}


@end /* SkyPalmDocumentDataSource */
