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

#ifndef __Tasks_SxTaskStatus_H__
#define __Tasks_SxTaskStatus_H__

#import <Foundation/NSObject.h>

/*
  SxTaskStatus
  
  This class is used to encapsulate the different task properties of
  Evolution which form a logical unit that needs to be serialized into
  a SKYRiX job action.
  
  Evolution has these properties:
    cdoItemIsComplete - bool, is it done or not
    status            - ...
    completion        - 0.00 to 1.00 were 0.00 is 0% and 1.00 is 100% complete
    
  Evo Status:
    0 - Not Started
    1 - In Progress (Evo sets completion to 50% ...)
    2 - Completed   (Evo sets completion to 100% and date-completed)
    3 - Needs Action
    4 - Canceled
*/

@class NSString, NSDictionary, NSMutableArray, NSNumber;

@interface SxTaskStatus : NSObject
{
  BOOL  isDone;
  char  status;
  float completion;

  NSString *sxStatus;
}

+ (id)statusWithDavProps:(NSDictionary *)_props;
+ (id)statusWithSxStatus:(NSString *)_status
         percentComplete:(NSNumber *)_percent;
+ (id)statusWithSxObject:(id)_object;

- (void)removeExtractedDavPropsFromArray:(NSMutableArray *)_array;

/* accessors */

- (BOOL)isDone;
- (int)status;
- (float)completion;

/* calculated accessors */

- (float)completionInPercent;

- (NSString *)sxStatusForCompletion;
- (NSString *)sxStatusForStatus;

#if 0
- (NSString *)sxActionForCompletion;

- (BOOL)sxNeedsActionAfterCreate;
#endif

@end

#endif /* __Tasks_SxTaskStatus_H__ */
