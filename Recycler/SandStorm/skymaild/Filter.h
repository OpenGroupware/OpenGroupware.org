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

#ifndef __SkyMailXmlRpcServer__Filter_H__
#define __SkyMailXmlRpcServer__Filter_H__

#import <Foundation/NSObject.h>

@class NSString, NSArray, NSDictionary;

@interface Filter : NSObject
{
@private
  NSString *filterName;
  int      filterPos;
  BOOL     active;
  NSString *action;
  NSString *folder;
  NSString *match;
  NSArray  *entries;
}

+ (Filter *)filter;
+ (Filter *)filterWithDictionary:(NSDictionary *)_dict;

- (NSDictionary *)dictionaryRepresentation;

- (void)setFilterName:(NSString *)_filterName;
- (NSString *)filterName;

- (void)setFilterPos:(int)_filterPos;
- (int)filterPos;

- (void)setActive:(BOOL)_active;
- (BOOL)active;

- (void)setAction:(NSString *)_action;
- (NSString *)action;

- (void)setFolder:(NSString *)_folder;
- (NSString *)folder;

- (void)setMatch:(NSString *)_match;
- (NSString *)match;

- (void)setEntries:(NSArray *)_entries;
- (NSArray *)entries;

- (BOOL)isEqualToFilter:(Filter *)_filter;
- (BOOL)isEqual:(id)_obj;

@end // Filter

#endif /* __SkyMailXmlRpcServer__Filter_H__ */
