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

#ifndef __SxFetchContact__H_
#define __SxFetchContact__H_

#import <Foundation/NSObject.h>

@class NSDictionary, NSMutableDictionary, NSString, NSNumber;

@interface SxFetchContact : NSObject
{
  id ctx;
  id eo;

  NSMutableDictionary *addr;
  NSMutableDictionary *phones;
}

- (void)clearVars;
- (void)clearCache;
- (NSString *)entityName;
- (NSString *)getName;
- (NSString *)phoneForType:(NSString *)_type;
- (NSDictionary *)addressForType:(NSString *)_kind;
- (id)addressObjForType:(NSString *)_type;
- (id)eo;
- (void)setEo:(id)_eo;
- (void)loadEOForID:(NSNumber *)_id;
- (NSDictionary *)dictWithPrimaryKey:(NSNumber *)_number;

- (NSDictionary *)otherKeys;
- (NSDictionary *)contactKeys;

@end

#endif /* __SxFetchContact__H_ */
