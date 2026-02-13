/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#ifndef __OGoProject_EOQualifier_Project_H__
#define __OGoProject_EOQualifier_Project_H__

#include <EOControl/EOQualifier.h>

@class NSArray;

/**
 * @category EOQualifier(Project)
 * @brief Project-specific qualifier utilities.
 *
 * Adds methods to EOQualifier for working with project kind
 * restrictions and for creating qualifiers that filter by
 * project type or project IDs. Used by SkyProjectDataSource
 * to manage the visibility of hidden project kinds.
 *
 * @see SkyProjectDataSource
 */
@interface EOQualifier(Project)

- (BOOL)isProjectCheckKindQualifier;
- (NSArray *)flattenQualifierForProjectKindsCheck;
- (NSArray *)reduceProjectKindRestrictionByUsedNames:(NSArray *)_hiddenKinds;

+ (EOQualifier *)qualifierForProjectType:(NSString *)_type;
+ (EOQualifier *)qualifierForProjectIDs:(NSArray *)_projectIds;

@end

#endif /* __OGoProject_EOQualifier_Project_H__ */
