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

#ifndef __PLRApp_NSArray_ColGroups_H__
#define __PLRApp_NSArray_ColGroups_H__

#import <Foundation/NSArray.h>

@interface NSArray(ColGroups)

/*
  Groups the array elements into an array of arrays, eg:
    @(1,2,3,4,5) => @( ( 1, 2 ), ( 3, 4 ), ( 5 ))   [2 columns]
*/
- (NSArray *)arrayByGroupingIntoColumns:(int)_cols;

@end

#endif /* __PLRApp_NSArray_ColGroups_H__ */
