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

#ifndef __LSLogic_LSSearch_LSGenericSearchRecord_H__
#define __LSLogic_LSSearch_LSGenericSearchRecord_H__

#import <Foundation/NSObject.h>

@class EOEntity, NSMutableDictionary, NSDictionary;

/**
 * @class LSGenericSearchRecord
 *
 * A key/value container that pairs an EOEntity with a
 * dictionary of attribute names to search values. Used as
 * input to LSExtendedSearch and LSExtendedSearchCommand
 * to describe the fields and values to match.
 *
 * Supports NSCopying and key/value coding. Values are
 * stored in an internal mutable dictionary and can be
 * set via -takeValue:forKey: or -takeValuesFromDictionary:.
 *
 * The comparator property (e.g. "LIKE", "EQUAL") is
 * passed through to LSBaseSearch to control the SQL
 * matching mode.
 */
@interface LSGenericSearchRecord : NSObject < NSCopying >
{
@private
  EOEntity            *entity;
  NSMutableDictionary *searchDict;
  NSString            *comparator;
}


- (id)initWithEntity:(EOEntity *)_entity;

- (void)takeValuesFromDictionary:(NSDictionary *)_dictionary;

/* accessors */
 
- (void)setEntity:(EOEntity *)_entity;
- (EOEntity *)entity;
- (void)setComparator:(NSString *)_comparator;
- (NSString *)comparator;
- (NSDictionary *)searchDict;

- (void)removeAllObjects;
- (void)removeObjectForKey:(id)_key;

@end

#endif /* __LSLogic_LSSearch_LSGenericSearchRecord_H__ */
