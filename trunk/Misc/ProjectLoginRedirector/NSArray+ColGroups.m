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

#include "NSArray+ColGroups.h"
#include "common.h"

@implementation NSArray(ColGroups)

- (NSArray *)arrayByGroupingIntoColumns:(int)_cols {
  unsigned int i, count, batchCount;
  NSArray *result;
  id      *objs;
  
  if ((count = [self count]) == 0)
    return [NSArray array];
  if (count <= _cols)
    return [NSArray arrayWithObject:self];
  
  batchCount = (count / _cols) + (count % _cols);
  objs = calloc(batchCount, sizeof(id));
  for (i = 0; i < batchCount; i++) {
    unsigned int j;
    id subobjs[_cols];
    
    for (j = 0; j < _cols; j++) {
      unsigned int idx;
      
      idx = (i * _cols) + j;
      if (idx >= count) break; // last object
      subobjs[j] = [self objectAtIndex:idx];
    }
    
    objs[i] = [NSArray arrayWithObjects:subobjs count:j];
  }
  
  result = [NSArray arrayWithObjects:objs count:batchCount];
  if (objs) free(objs);
  return result;
}

@end /* NSArray(ColGroups) */
