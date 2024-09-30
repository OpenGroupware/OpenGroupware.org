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

#include "OGoHelpManager.h"
#include "common.h"
#import <Foundation/NSURL.h>

@implementation OGoHelpManager

static OGoHelpManager *shared = nil; // THREAD

+ (id)sharedHelpManager {
  if (shared) return shared;
  shared = [[self alloc] init];
  return shared;
}

- (id)init {
  if ((self = [super init])) {
    NSFileManager  *fm;
    NSMutableArray *ma;
    NSArray  *sp;
    unsigned i, count;
    
    fm = [NSFileManager defaultManager];
    sp = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
					     NSAllDomainsMask,
					     YES);
    count = [sp count];
    ma = [[NSMutableArray alloc] initWithCapacity:(count + 1)];
    for (i = 0; i < count; i++) {
      NSString *p;
      BOOL isDir;
      
      p = [sp objectAtIndex:i]; 
      p = [p stringByAppendingPathComponent:@"Documentation"];
      p = [p stringByAppendingPathComponent:@"OpenGroupware.org"];
      
      if (![fm fileExistsAtPath:p isDirectory:&isDir])
	continue;
      if (!isDir)
	continue;
      
      [ma addObject:p];
    }
    self->pathes = [ma count] > 0 ? [ma copy] : nil;
    [ma release]; ma = nil;
    
    if ([self->pathes count] == 0)
      [self logWithFormat:@"Note: no OGo documentation installed!"];
    
    [self logWithFormat:@"SP: %@", self->pathes];
  }
  return self;
}

- (void)dealloc {
  [self->pathes release];
  [super dealloc];
}

/* sections */

- (NSArray *)availableSections {
  NSFileManager *fm;
  NSMutableSet  *ms;
  NSEnumerator  *e;
  NSString      *path;
  
  fm = [NSFileManager defaultManager];
  ms = [NSMutableSet setWithCapacity:16];
  
  e = [self->pathes objectEnumerator];
  while ((path = [e nextObject])) {
    NSArray *sp;
    
    sp = [fm directoryContentsAtPath:path];
    [ms addObjectsFromArray:sp];
  }
  return [ms allObjects];
}

/* operations */

- (NSURL *)helpURLForKey:(NSString *)_key section:(NSString *)_section
  inContext:(WOContext *)_ctx
{
  // TODO: could support custom URL templates (eg "/Docs/$section$/$key$")
  NSURL *url;
  
  if ((url = [_ctx urlForKey:@"so"]) == nil) {
    [self errorWithFormat:@"got no baseURL!"];
    return nil;
  }
  url = [NSURL URLWithString:_section relativeToURL:url];
  url = [NSURL URLWithString:_key     relativeToURL:url];
  [self debugWithFormat:@"URL: %@", url];
  return url;
}

- (NSURL *)helpURLForComponent:(WOComponent *)_component {
  if (_component == nil)
    return nil;
  
  return [self helpURLForKey:[_component helpKey]
	       section:[_component helpSection]
	       inContext:[_component context]];
}

- (NSString *)shortHelp:(NSString *)_name inComponent:(WOComponent *)_comp {
  if (_comp == nil || [_name length] == 0)
    return nil;
  
  return nil;
}

- (NSString *)fieldHelp:(NSString *)_name inComponent:(WOComponent *)_comp {
  if (_comp == nil || [_name length] == 0)
    return nil;
  
  return nil;
}

@end /* OGoHelpManager */

@implementation NSBundle(HelpMethods)

- (NSString *)helpSection {
  NSString *section;
  id principalObject;

  if ((principalObject = [self principalObject])) {
    if ([principalObject respondsToSelector:_cmd])
      return [principalObject helpSection];
  }
  
  section = [self bundlePath];
  section = [section lastPathComponent];
  section = [section stringByDeletingPathExtension];
  return section;
}

@end /* NSBundle(HelpMethods) */

@implementation WOComponent(HelpMethods)

- (NSString *)helpKey {
  return NSStringFromClass([self class]);
}

- (NSString *)helpSection {
  NSBundle *hbundle;
  
  if ((hbundle = [NSBundle bundleForClass:[self class]]) == nil)
    return nil;
  
  return [hbundle helpSection];
}

@end /* WOComponent(HelpMethods) */
