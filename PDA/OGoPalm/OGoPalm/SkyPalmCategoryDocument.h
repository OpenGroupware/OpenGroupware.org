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

#ifndef __SkyPalmCategoryDocument_H__
#define __SkyPalmCategoryDocument_H__

#import <Foundation/Foundation.h>

@class SkyPalmCategoryDataSource;

@interface SkyPalmCategoryDocument : NSObject
{
  NSDictionary              *source;     // original values
  SkyPalmCategoryDataSource *dataSource; // dataSource of category

  // values
  int                       palmId;      // eq. categoryId
  BOOL                      isModified;
  int                       categoryIndex;
  NSString                  *categoryName;
  NSString                  *md5Hash;
  NSString                  *deviceId;
}

// initalizing
- (id)initWithDictionary:(NSDictionary *)_src
          fromDataSource:(SkyPalmCategoryDataSource *)_ds;
- (id)initAsNewWithDictionary:(NSDictionary *)_src
               fromDataSource:(SkyPalmCategoryDataSource *)_ds;
- (id)initAsNewFromDataSource:(SkyPalmCategoryDataSource *)_ds;

- (void)prepareAsNew;

// values
- (void)setPalmId:(int)_pid;
- (int)palmId;
- (void)setIsModified:(BOOL)_flag;
- (BOOL)isModified;
- (void)setCategoryIndex:(int)_idx;
- (int)categoryIndex;
- (void)setCategoryName:(NSString *)_name;
- (NSString *)categoryName;
- (void)setMd5Hash:(NSString *)_hash;
- (NSString *)md5Hash;
- (NSString *)deviceId;

// other
- (id)globalID;
- (NSNumber *)companyId;
- (NSArray *)devices;
- (BOOL)isNewRecord;
- (NSMutableDictionary *)asDictionary;

// overwriting
- (NSString *)palmTable;

// helper
- (NSString *)generateMD5Hash;

// actions
- (id)save;
- (id)saveWithoutReset;
- (id)revert;
- (id)delete;
- (id)reload;

- (void)updateSource:(NSDictionary *)_src
      fromDataSource:(SkyPalmCategoryDataSource *)_ds;

@end

#endif /* __SkyPalmCategoryDocument_H__ */
