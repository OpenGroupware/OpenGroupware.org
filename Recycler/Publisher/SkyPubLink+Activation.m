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

#include "SkyPubLink.h"
#include "SkyPubFileManager.h"
#include "common.h"

@interface WOContext(Activation)
- (NSString *)activationURLForGlobalID:(EOGlobalID *)_gid verb:(NSString *)_v;
- (NSString *)p4documentURLForProjectWithGlobalID:(EOGlobalID *)_gid
  path:(NSString *)_path versionTag:(NSString *)_v;
@end
@interface WOComponent(PGID)
- (EOGlobalID *)projectGlobalID;
@end

@implementation SkyPubLink(Activation)

- (NSString *)skyrixUrlInContext:(WOContext *)_ctx {
  EOGlobalID *gid;
  NSString   *verb;
  NSString   *path;
  BOOL       isDir;
  SkyPubFileManager *fm;
  
  if ([self isAbsoluteURL])
    return [self linkValue];
  
  gid = [self targetObjectIdentifier];
  
  if (gid == nil)
    /* invalid link */
    return nil;
  
  if ((verb = [_ctx valueForKey:@"PubActivationVerb"]) == nil)
    verb = @"view";

  fm = [[self fileManager] asPubFileManager];
  
  path = [fm pathForGlobalID:gid];
  if ([fm fileExistsAtPath:path isDirectory:&isDir]) {
    if (isDir) {
      path = [fm indexFilePathForDirectory:path];
      gid  = [fm globalIDForPath:path];
    }
  }
  
  return [_ctx activationURLForGlobalID:gid verb:verb];
}

- (NSString *)downloadUrlInContext:(WOContext *)_ctx {
  NSString *tpath;
  
  if ([self isAbsoluteURL])
    return [self linkValue];
  
  if ((tpath = [self absoluteTargetPath]) == nil)
    /* invalid link */
    return nil;

  return [_ctx p4documentURLForProjectWithGlobalID:
                 [(id)[_ctx component] projectGlobalID]
               path:tpath
               versionTag:nil];
}

@end /* SkyPubLink(Activation) */
