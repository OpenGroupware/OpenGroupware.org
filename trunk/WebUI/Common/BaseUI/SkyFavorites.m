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

#include <OGoFoundation/OGoComponent.h>

@interface SkyFavorites : OGoComponent
{
  int  index;
  BOOL isClickable;
  id   favorite;
  int  maxDockWidth;
}

- (void)setIndex:(int)_idx;
- (int)index;
- (void)setFavorite:(id)_favorite;
- (id)favorite;

@end

#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/OGoClipboard.h>
#include <OGoFoundation/WOComponent+Commands.h>
#include <NGObjWeb/NGObjWeb.h>
#import <EOControl/EOControl.h>
#import <GDLAccess/GDLAccess.h>

@interface NSObject(gid)
- (EOGlobalID *)globalID;
- (NSString *)favoriteDragType;
@end

@implementation SkyFavorites

/* notifications */

- (void)sleep {
  [self setFavorite:nil];
  [super sleep];
}

/* accessors */

- (void)setIndex:(int)_idx {
  self->index = _idx;
}
- (int)index {
  return self->index;
}

- (void)setLinksDisabled:(BOOL)_flag {
  self->isClickable = !_flag;
}
- (BOOL)linksDisabled {
  return self->isClickable ? NO : YES;
}

- (void)setFavorite:(id)_favorite {
  ASSIGN(self->favorite, _favorite);
}
- (id)favorite {
  return self->favorite;
}

/* computed accessors */

- (int)maxDockLabelWidth {
  if (self->maxDockWidth == 0) {
    NSUserDefaults *ud;
    
    ud = [[self session] userDefaults];
    self->maxDockWidth = [[ud objectForKey:@"OGoDockLabelWidth"] intValue];
    if (self->maxDockWidth < 8) self->maxDockWidth = 16;
  }
  return self->maxDockWidth;
}

- (NSString *)labelForFavorite {
  NSString *s;
  int max;
  
  s = [(OGoSession *)[self session] labelForObject:[self favorite]];
  if ([s length] == 0)
    return @"[ERROR: got no label for favorite from session]";
  
  max = [self maxDockLabelWidth];
  if ([s length] > max) {
    s = [s substringToIndex:(max - 3)];
    s = [s stringByAppendingString:@"..."];
  }
  if ([s length] == 0)
    s = @"[ERROR: could not determine label of favorite]";
  return s;
}

- (NSString *)favoriteDragType {
  id obj;
  NSString *dragType;
  
  obj = [self favorite];
  dragType = ([obj isKindOfClass:NSClassFromString(@"NGImap4Message")])
    ? @"mail" // TODO: fix me
    : (id)[obj favoriteDragType];
  
  if ([dragType isEqualToString:@"date"])
    dragType = @"appointment";
  
  return dragType;
}

/* actions */

- (id)showChoosenFavorite {
  static Class NGImapMsgClass = Nil;
  id obj;
  id gid;
  
  if ((obj = [self favorite]) == nil)
    return nil;

  //NSLog(@"obj is %@", obj);

  if (NGImapMsgClass == Nil)
    NGImapMsgClass = NSClassFromString(@"NGImap4Message");

  if ([obj isKindOfClass:[EOGenericRecord class]])
    gid = nil;
  else if ([obj isKindOfClass:NGImapMsgClass])
    gid = nil;
  else
    gid = [obj valueForKey:@"globalID"];

  // test, whether the favorite is an valid object???
  if (gid != nil) {
    NSArray *objs;
    
    objs = [self runCommand:@"object::get-by-globalid", @"gid", gid, nil];
    if ([objs count] == 0) {
      [[[self session] favorites] removeObject:obj];
      [[[self context] page] takeValue:@"Object is invalid!"
                             forKey:@"errorString"];
      return nil;
    }
  }
  
  return [[(OGoSession *)[self session] navigation]
                       activateObject:gid ? gid : obj
                       withVerb:@"view"];
}

@end /* SkyFavorites */

@implementation NSObject(DragTypes)

- (NSString *)favoriteDragType {
  EOGlobalID *gid;
  
  if ([self respondsToSelector:@selector(globalID)])
    return [[self globalID] favoriteDragType];
  
  if ((gid = [self valueForKey:@"globalID"]) != nil)
    return [gid favoriteDragType];
  
  return @"unknown";
}

@end /* NSObject(DragTypes) */

@implementation EOGenericRecord(DragTypes)

- (NSString *)favoriteDragType {
  return [[[self entity] name] lowercaseString];
}

@end /* EOGenericRecord(DragTypes) */

@implementation EOKeyGlobalID(DragTypes)

- (NSString *)favoriteDragType {
  return [[self entityName] lowercaseString];
}

@end /* EOKeyGlobalID(DragTypes) */
