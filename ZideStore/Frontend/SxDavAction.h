/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#ifndef __sxdavd_SxDavAction_H__
#define __sxdavd_SxDavAction_H__

#import <Foundation/NSObject.h>

/*
  SxDavAction
  
  A common superclass for DAV based create and update actions.
  TODO: describe services
*/

@class NSString, NSDictionary, NSMutableArray, NSMutableDictionary, NSNumber;
@class NSArray;
@class SxObject;

@interface SxDavAction : NSObject
{
  SxObject       *object; /* the *controller*, not the EO */
  NSString       *name;
  NSDictionary   *props;
  NSMutableArray *keys;

  NSMutableDictionary *changeSet;
}

- (id)initWithName:(NSString *)_name properties:(NSDictionary *)_props
         forObject:(SxObject *)_object;

- (NSArray *)unusedKeys;
- (BOOL)removeUnknownMAPIKeys; // default YES
// removes keys which are duplicates or unknown/unprocessable
- (void)removeUnusedKeys;

- (NSString *)expectedMessageClass;
// check whether the outlookMessageClass is IPM.Task
- (BOOL)checkMessageClass;

// log keys left over
- (void)logRemainingKeys;

- (NSString *)createdLogText;
- (NSString *)modifiedLogText;

// return a OGo priority code for the outlook prio
- (NSNumber *)skyrixValueForOutlookPriority:(int)_pri;

/* running */
- (id)runInContext:(id)_ctx;


@end /* SxDavAction */

#endif /* __sxdavd_SxDavAction_H__ */
