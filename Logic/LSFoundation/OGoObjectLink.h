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
//$Id: OGoObjectLink.h 1 2004-08-20 11:17:52Z znek $

#ifndef __OGoObjectLink_H__
#define __OGoObjectLink_H__

#import <Foundation/NSObject.h>

/*
  OGoObjectLink
  
  Note: instances of this class are considered immutable (eg copy will return
        self)
*/

@class EOGlobalID, EOKeyGlobalID;
@class NSDictionary, NSString;

@interface OGoObjectLink : NSObject < NSCopying >
{
  /* Global id`s are calculated from id and type */
  EOGlobalID   *sourceGID;
  EOGlobalID   *targetGID;
  unsigned int sourceID;
  unsigned int targetID;
  NSString     *sourceType;
  NSString     *targetType;
  NSString     *target;
  NSString     *label;
  NSString     *linkType;
  EOGlobalID   *globalID;
}

+ (id)objectLinkWithAttributes:(NSDictionary *)_attrs;

- (id)initWithSource:(EOKeyGlobalID *)_gid target:(id)_id
  type:(NSString *)_type label:(NSString *)_label;

- (EOGlobalID *)sourceGID;
- (EOGlobalID *)targetGID;
- (unsigned int)sourceId;
- (unsigned int)targetId;
- (NSString *)target;
- (NSString *)targetType;

- (NSString *)label;
- (NSString *)linkType;

- (BOOL)isNew;
- (EOGlobalID *)globalID;

@end /* OGoObjectLink */

#endif /* __OGoObjectLink_H__ */
