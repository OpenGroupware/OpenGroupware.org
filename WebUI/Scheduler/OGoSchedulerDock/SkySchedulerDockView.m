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

#include <OGoFoundation/LSWComponent.h>

@interface SkySchedulerDockView : LSWComponent
{
  BOOL hideLink;
}
@end

#include <OGoFoundation/LSWSession.h>
#import <NGObjWeb/WOContext.h>
#import <NGMime/NGMimeType.h>
#import <EOAccess/EOAccess.h>
#import <EOControl/EOControl.h>
#import <NGExtensions/NGExtensions.h>
#import <Foundation/Foundation.h>

@implementation SkySchedulerDockView

+ (int)version {
  return [super version] + 0; /* v2 */
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)init {
  id p;

  /* this component is a session-singleton */
  
  if ((p = [self persistentInstance])) {
    [self release];
    return [p retain];
  }

  if ((self = [super init])) {
    /* register as persistent component */
    [self registerAsPersistentInstance];
  }
  return self;
}

- (void)setHideLink:(BOOL)_flag {
  self->hideLink = _flag;
}
- (BOOL)hideLink {
  return self->hideLink;
}

/* actions */

- (id)objectDropped {
  EOKeyGlobalID *gid;
  id            obj;
  NSString      *entityName = nil;
  BOOL          isPerson = NO;
  
  obj = [self valueForKey:@"droppedObject"];
  //NSLog(@"dropped object: %@", obj);
  
  if ([obj isKindOfClass:[EOGenericRecord class]]) {
    entityName = [[obj entity] name];
    if ([entityName isEqualToString:@"Person"]) 
      isPerson = YES;
  }
  else if ((gid = [obj valueForKey:@"globalID"])) {
    entityName = [gid entityName];

    if ([entityName isEqualToString:@"Person"]) {
      id ctx;
      isPerson = YES;
      ctx = [[self session] commandContext];
      obj = [ctx runCommand:@"person::get-by-globalid",
                 @"gid", gid, nil];
      obj = [obj lastObject];
      if (obj == nil) {
        NSLog(@"%s: failed to fetch person for gid %@",
              __PRETTY_FUNCTION__, gid);
        return nil;
      }
    }
    else if ([entityName isEqualToString:@"Date"]) {
      /* if date is dropped, show week overview for date */
      NSCalendarDate *startDate;
      
      if ((startDate = [obj valueForKey:@"startDate"])) {
        int            weekNo, year;
        int            month;
        NSTimeZone     *tz;
        NSCalendarDate *date;
        id             page;
        
        page   = [self pageWithName:@"SkySchedulerPage"];
        
        weekNo = [startDate weekOfYear];
        year   = [startDate yearOfCommonEra];
        month  = [startDate monthOfYear];
        tz     = [startDate timeZone];

        if (tz == nil)
          tz = [(id)[self session] timeZone];
        
        date = [NSCalendarDate mondayOfWeek:weekNo inYear:year timeZone:tz];
        
        //NSLog(@"CONFIGURE WEEK page ..");
        [page takeValue:tz          forKey:@"timeZone"];
        [page takeValue:date        forKey:@"weekStart"];
        [page takeValue:[NSNumber numberWithInt:year]  forKey:@"year"];
        [page takeValue:[NSNumber numberWithInt:month] forKey:@"month"];
        [page takeValue:@"weekoverview" forKey:@"selectedTab"];
        //        [page reconfigure];
        return page;
      }
    }
  }

  if (isPerson) {
    /* if person is dropped, make new apt with person as participant */      
    NSDictionary *d;

    d = [NSDictionary dictionaryWithObject:
                      [NSArray arrayWithObjects:&obj count:1]
                      forKey:@"participants"];
      
    [[self session] transferObject:d owner:self];
    
    return [[self session] instantiateComponentForCommand:@"new"
                           type:[NGMimeType mimeType:@"eo/date"]];
  }
  
  return nil;
}

@end /* SkySchedulerDockView */
