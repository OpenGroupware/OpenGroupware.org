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

#include "SkyPalmSelectableListing.h"

@interface SkyPalmJobListing : SkyPalmSelectableListing
{
}

@end /* SkyPalmJobListing */

#import <Foundation/Foundation.h>
#include <OGoPalm/SkyPalmJobDocument.h>

@implementation SkyPalmJobListing

// accessors
- (NSArray *)jobs {
  return [self list];
}
- (void)setJob:(id)_job {
  [self setItem:_job];
}
- (id)job {
  return [self item];
}

// label keys
- (NSString *)stateLabelKey {
  return [NSString stringWithFormat:@"skyrixjob_state_%@",
                   [[self item] valueForKey:@"status"]];
}
- (NSString *)priorityLabelKey {
  int pri = [[[self item] valueForKey:@"priority"] intValue];
  return [SkyPalmJobDocument priorityStringForPriority:pri];
}

// action
- (id)chooseJob {
  return [self selectItem];
}
- (id)chooseJobs {
  return [self selectItems];
}

@end /* SkyPalmJobListing */
