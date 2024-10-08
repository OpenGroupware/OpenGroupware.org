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

#ifndef __sxdavd3_EOQualifier_Additions_H__
#define __sxdavd3_EOQualifier_Additions_H__

#import <Foundation/NSArray.h>
#include <EOControl/EOQualifier.h>

@class NSString, NSDictionary;

@interface NSArray(QualifierArray)

// flat lookup of a key-value qualifier
- (NSUInteger)indexOfKeyValueQualifierForKey:(NSString *)_key;

// lookup the next qualifier matching the class
- (NSUInteger)indexOfQualifierOfClass:(Class)_clazz;

// lookup the next AND or OR qualifier
- (NSUInteger)indexOfAndOrQualifier;

// gives back a dict of all keys mapped to a single value
// eg "(a like 'a' and b like 'a' and c like 'c') "
// will return { a=(a,b), c=c }
- (NSDictionary *)generalizeKeyValueLikeQualifiers:(NSArray **)_remaining;

@end

@interface NSMutableArray(QualifierArray)

// remove a qualifier, returns YES if it did exists, otherwise NO
- (BOOL)removeQualifier:(EOQualifier *)_qualifier;

// removes a KVC qualifier, gives back the value if found
- (id)removeKeyValueQualifierForKey:(NSString *)_key operation:(SEL)_sel;

@end

#endif /* __sxdavd3_EOQualifier_Additions_H__ */
