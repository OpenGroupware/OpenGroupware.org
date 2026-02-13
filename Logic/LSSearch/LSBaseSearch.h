/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#ifndef __LSLogic_LSSearch_LSBaseSearch_H__
#define __LSLogic_LSSearch_LSBaseSearch_H__

#import <Foundation/NSObject.h>

@class LSGenericSearchRecord, NSArray, NSString;
@class EOAttribute, EOEntity, EOSQLQualifier, EOAdaptor;

/**
 * @class LSBaseSearch
 *
 * Abstract base class for constructing SQL qualifier
 * format strings used in OGo search operations.
 * Provides helper methods that format string, number,
 * and text attribute values into SQL LIKE/ILIKE or
 * equality expressions suitable for use in
 * EOSQLQualifier format strings.
 *
 * Subclasses (LSExtendedSearch, LSFullSearch) use
 * these formatting methods to build qualifiers for
 * their specific search strategies.
 *
 * The dbAdaptor is used for database-specific value
 * formatting and expression generation. The comparator
 * controls whether LIKE, ILIKE, or EQUAL matching is
 * used.
 */
@interface LSBaseSearch : NSObject
{
  EOAdaptor *dbAdaptor;
  NSString  *comparator;
}

/* protected */

- (NSString *)_formatForStringValue:(id)_value;
- (NSString *)_formatForNumberValue:(id)_value;
- (NSString *)_formatForTextAttribute:(EOAttribute *)_attr andValue:(id)_value;
- (NSString *)_formatForStringAttribute:(EOAttribute *)_attr andValue:(id)_val;
- (NSString *)_formatForNumberAttribute:(EOAttribute *)_attr andValue:(id)_val;
- (NSString *)_formatForTextAttribute:(EOAttribute *)_attr andValue:(id)_value
  entity:(EOEntity *)_entity;
- (NSString *)_formatForStringAttribute:(EOAttribute *)_attr andValue:(id)_val
  entity:(EOEntity *)_entity;
- (NSString *)_formatForNumberAttribute:(EOAttribute *)_attr andValue:(id)_val
  entity:(EOEntity *)_entity;

- (void)setDbAdaptor:(EOAdaptor *)_adaptor;
- (EOAdaptor *)dbAdaptor;

- (void)setComparator:(NSString *)_comparator;
- (NSString *)comparator;

@end

#endif /* __LSLogic_LSSearch_LSBaseSearch_H__ */
