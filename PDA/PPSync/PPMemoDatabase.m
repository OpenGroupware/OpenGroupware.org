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

#include "PPMemoDatabase.h"
#include "PPMemoPacker.h"
#include "PPClassDescription.h"
#include "common.h"

static EONull *null = nil;

@implementation PPMemoDatabase

+ (void)initialize {
  if (null == nil) null = [EONull null];
}

/* records */

- (EOClassDescription *)classDescriptionNeededForEntityName:(NSString *)_name {
  PPClassDescription *pp;

  pp = nil;
  if ([_name isEqualToString:@"MemoDB"]) {
    pp = [[PPClassDescription alloc] initWithClass:[PPMemoRecord class]
                                     creator:'memo'
                                     type:'DATA'];
  }
  
  return AUTORELEASE(pp);
}

- (Class)databaseRecordClassForGlobalID:(EOGlobalID *)_oid {
  return [PPMemoRecord class];
}

/* accessors */

- (BOOL)sortByAlpha {
  return self->sortByAlpha;
}

/* packing & unpacking */

- (NSData *)packRecord:(id)_eo {
  PPMemoPacker *packer;
  NSData *data;

  packer = [[PPMemoPacker alloc] initWithObject:_eo];
  data = [packer packWithDatabase:self];
  RELEASE(packer);

  if ([data length] >= 65535) {
    NSLog(@"ERROR: got packed address data with length %i ..", [data length]);
    return nil;
  }
  
  return data;
}

- (int)decodeAppBlock:(NSData *)_block {
  const unsigned char *record;
  const unsigned char *start;
  int i, len;
  
  record = start = [_block bytes];
  len    = [_block length];

  i = [super decodeAppBlock:_block];
  record += i;
  len    -= i;

  if (len >= 4) {
    record += 2;
    self->sortByAlpha = get_byte(record) ? YES : NO;
    record += 2;
  }
  else {
    self->sortByAlpha = NO;
  }
  
  self->hasAppInfo = YES;
  return (record - start);
}

- (NSString *)propertyDescription {
#if 0
  if (self->hasAppInfo) {
    NSMutableString *s;

    s = [NSMutableString stringWithString:[super propertyDescription]];
    return s;
  }
  else
#endif
    return [super propertyDescription];
}

@end /* PPMemoDatabase */

@implementation PPMemoRecord

+ (void)initialize {
  if (null == nil) null = [EONull null];
}

+ (long)palmCreator {
  return 'memo';
}
+ (long)palmType {
  return 'DATA';
}

- (void)awakeFromDatabase:(PPRecordDatabase *)_db
  objectID:(EOGlobalID *)_oid
  attributes:(int)_attrs
  category:(int)_category
  data:(NSData *)_data
{
  PPMemoPacker *packer;

  [super awakeFromDatabase:_db objectID:_oid attributes:_attrs
         category:_category
         data:_data];
  
  if ([self isDeleted])
    return;

  packer = [[PPMemoPacker alloc] initWithObject:self];
  [packer unpackWithDatabase:_db data:_data];
  RELEASE(packer);
}

- (void)dealloc {
  RELEASE(self->text);
  [super dealloc];
}

/* accessors */

- (void)setText:(NSString *)_value {
  if (_value == (id)null) _value = nil;
  if ([_value length] == 0) _value = nil;
  
  if (![self->text isEqualToString:_value]) {
    [self willChange];
    ASSIGN(self->text, _value);
  }
}
- (NSString *)text {
  return self->text;
}

- (NSArray *)attributeKeys {
  static NSArray *keys = nil;
  if (keys == nil) {
    keys = [[NSArray alloc] initWithObjects:
                              @"isArchived", @"category", @"isPrivate",
                              @"text",
                              nil];
                            
  }
  return keys;
}

@end /* PPMemoRecord */
