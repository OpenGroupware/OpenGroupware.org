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

#include <OGoPalm/SkyPalmCategoryDocument.h>

#if 0
@interface SkyPalmAddressCategoryDocument : SkyPalmCategoryDocument
{
}
@end

@interface SkyPalmMemoCategoryDocument : SkyPalmCategoryDocument
{}
@end

@interface SkyPalmJobCategoryDocument : SkyPalmCategoryDocument
{}
@end
#endif

@interface SkyPalmCategoryDocument(PrivatMethods)
- (void)_setSourceAndParse:(NSDictionary *)_src;
- (void)_setDataSource:(SkyPalmCategoryDataSource *)_ds;
@end

#include <OGoPalm/SkyPalmCategoryDataSource.h>
#include <OGoPalm/NGMD5Generator.h>
#include "common.h"

@implementation SkyPalmCategoryDocument

- (id)initWithDictionary:(NSDictionary *)_src
  fromDataSource:(SkyPalmCategoryDataSource *)_ds
{
  if ((self = [self init])) {
    self->palmId        = 0;
    self->categoryIndex = 0;
    [self _setSourceAndParse:_src];
    [self _setDataSource:_ds];
    if ([self isNewRecord])
      [self prepareAsNew];
  }
  return self;
}

- (id)initAsNewWithDictionary:(NSDictionary *)_src
  fromDataSource:(SkyPalmCategoryDataSource *)_ds
{
  NSMutableDictionary *dict;

  dict = [_src mutableCopy];
  [dict removeObjectForKey:@"globalID"];
  
  self = [self initWithDictionary:dict fromDataSource:_ds];
  [dict release];;
  
  return self;
}
- (id)initAsNewFromDataSource:(SkyPalmCategoryDataSource *)_ds {
  return [self initWithDictionary:[NSDictionary dictionary]
               fromDataSource:_ds];
}

- (void)dealloc {
  [self->source       release];
  [self->dataSource   release];
  [self->categoryName release];
  [self->md5Hash      release];
  [self->deviceId     release];
  [super dealloc];
}

/* accessors */

- (void)setPalmId:(int)_pid {
  self->palmId = _pid;
}
- (int)palmId {
  return self->palmId;
}

- (void)setIsModified:(BOOL)_flag {
  self->isModified = _flag;
}
- (BOOL)isModified {
  return self->isModified;
}

- (void)setCategoryIndex:(int)_idx {
  self->categoryIndex = _idx;
}
- (int)categoryIndex {
  return self->categoryIndex;
}

- (void)setCategoryName:(NSString *)_name {
  ASSIGNCOPY(self->categoryName,_name);
}
- (NSString *)categoryName {
  return self->categoryName;
}

- (void)setMd5Hash:(NSString *)_hash {
  ASSIGNCOPY(self->md5Hash,_hash);
}
- (NSString *)md5Hash {
  return self->md5Hash;
}

- (void)setDeviceId:(NSString *)_did {
  ASSIGNCOPY(self->deviceId,_did);
}
- (NSString *)deviceId {
  return self->deviceId;
}

// initalizing
- (void)_setSource:(NSDictionary *)_dict {
  ASSIGN(self->source,_dict);
}

- (void)_parseDict:(NSDictionary *)_dict {
  [self setPalmId:        [[_dict valueForKey:@"palm_id"] intValue]];
  [self setIsModified:    [[_dict valueForKey:@"is_modified"] boolValue]];
  [self setCategoryIndex: [[_dict valueForKey:@"category_index"] intValue]];
  [self setCategoryName:  [_dict valueForKey:@"category_name"]];
  [self setMd5Hash:       [_dict valueForKey:@"md5hash"]];
  [self setDeviceId:      [_dict valueForKey:@"device_id"]];
}

- (void)_setSourceAndParse:(NSDictionary *)_src {
  [self _setSource:_src];
  [self _parseDict:_src];
}

- (void)_setDataSource:(SkyPalmCategoryDataSource *)_ds {
  ASSIGN(self->dataSource, _ds);
}

- (void)prepareAsNew {
  NSString *device;
  
  //  NSLog(@"%s Preparing as new", __PRETTY_FUNCTION__);

  if ((device = [[self devices] objectAtIndex:0]) == nil) {
    [self logWithFormat:@"WARNING(%s): parent %@ has no valid devices",
          __PRETTY_FUNCTION__, self->dataSource];
    return;
  }

  [self setPalmId:0];
  [self setIsModified:NO];
  [self setCategoryIndex:0];
  [self setCategoryName:@"Unfiled"];
  
  [self setMd5Hash:@" "];
  [self setDeviceId:device];
}

- (void)updateSource:(NSDictionary *)_src
  fromDataSource:(SkyPalmCategoryDataSource *)_ds
{
  if (_ds == self->dataSource)
    [self _setSourceAndParse:_src];
  else {
    // _ds has no access to modify document
  }
}

// other
- (id)globalID {
  return [self->source valueForKey:@"globalID"];
}

- (NSNumber *)companyId {
  return [self->source valueForKey:@"company_id"];
}
- (NSArray *)devices {
  return [self->dataSource devices];
}

- (BOOL)isNewRecord {
  if ([self globalID] == nil)
    return YES;
  return NO;
}

- (NSMutableDictionary *)asDictionary {
  NSMutableDictionary *dict = [self->source mutableCopy];

  [dict takeValue:[NSNumber numberWithInt:[self palmId]]
        forKey:@"palm_id"];
  [dict takeValue:[NSNumber numberWithBool:[self isModified]]
        forKey:@"is_modified"];
  [dict takeValue:[NSNumber numberWithInt:[self categoryIndex]]
        forKey:@"category_index"];
  [dict takeValue:[self categoryName]
        forKey:@"category_name"];
  [dict takeValue:[self md5Hash]
        forKey:@"md5hash"];
  [dict takeValue:[self deviceId]
        forKey:@"device_id"];
  [dict takeValue:[self palmTable]
        forKey:@"palm_table"];

  AUTORELEASE(dict);

  return dict;
}

- (NSString *)palmTable {
  return [self->dataSource palmTable];
}

// helper
- (NSString *)_md5Source {
  return
    [NSString stringWithFormat:@"%@%@%@%@",
              [[NSNumber numberWithInt:[self palmId]] stringValue],
              [[NSNumber numberWithInt:[self categoryIndex]] stringValue],
              [self categoryName],
              [self palmTable]];
}
- (NSString *)generateMD5Hash {
  NGMD5Generator *generator = nil;
  NSString       *src       = nil;
  NSString       *digest    = nil;

  generator = [[NGMD5Generator alloc] init];
  src       = [self _md5Source];
  [generator encodeData:[src dataUsingEncoding:NSUTF8StringEncoding]];
  digest    = [generator digestAsString];

  RELEASE(generator);
  return digest;
}

// actions
- (id)saveWithoutReset {
  if ([self isNewRecord]) {
    [self->dataSource insertObject:self];
  }
  else {
    [self->dataSource updateObject:self];
  }

  return self;
}

- (id)save {
  if (![self isNewRecord])
    [self setIsModified:YES];
  return [self saveWithoutReset];
}

- (id)revert {
  if ([self isNewRecord])
    [self prepareAsNew];
  [self _parseDict:self->source];
  return self;
}

- (id)delete {
  if ([self globalID] != nil)
    [self->dataSource deleteObject:self];
  return nil;
}

- (id)reload {
  [self _setSource:[self->dataSource fetchDictionaryForDocument:self]];
  return nil;
}

// description

- (NSString *)description {
  return
    [NSString stringWithFormat:@"<%@ Name:'%@' Index:%d PalmID:%d>",
              [super description],
              [self categoryName],
              [self categoryIndex],
              [self palmId]];
}

- (BOOL)isEqual:(id)_other {
  // both should not be modified
  if (self == _other)
    return YES;
  if ([_other categoryIndex] != [self categoryIndex])
    return NO;
  if (![[_other palmTable] isEqualToString:[self palmTable]])
    return NO;
  return YES;
}

@end /* SkyPalmCategoryDocument */
