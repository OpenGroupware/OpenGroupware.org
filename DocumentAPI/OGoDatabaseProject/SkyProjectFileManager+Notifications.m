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

#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include "common.h"

// TODO: notification names should be constant
/*
  Currently such notifications are posted:
    notification 29950/_change object 0x00000000
  
  In such a case the name should be "OGoProjectChange", the object should be
  the project global id and the userinfo of the notification should contain
  information on the object which changed.
  
  We could -in addition- also send out notifications on document global ids.
*/

@interface SkyProjectFileManager(ErrorHandling_Internals)
- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel;
@end /* SkyProjectFileManager(ErrorHandling+Internals) */

@interface SkyProjectFileManager(Internals)

- (void)_checkCWDFor:(NSString *)_source;
- (id)_project;
- (NSString *)_defaultCompleteProjectDocumentNamespace;
- (NSArray *)subDirectoryNamesForPath:(NSString *)_path;
- (NSString *)_makeAbsolute:(NSString *)_path;
- (void)_subpathsAtPath:(NSString *)_path array:(NSMutableArray *)_array;
- (BOOL)_copyPath:(NSString*)_src toPath:(NSString*)_dest handler:(id)_handler;

- (BOOL)moveDir:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_dirName
  extension:(NSString *)_dirExt
  handler:(id)_handleru;

- (BOOL)moveLink:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_linkName
  extension:(NSString *)_linkExt
  handler:(id)_handler;

- (BOOL)moveFile:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_fileName
  extension:(NSString *)_fileExt
 handler:(id)_handler;

@end /* SkyProjectFileManager(Internals) */

@interface SkyProjectFileManager(Notifications_Internals)

- (NSNotificationCenter *)notificationCenter;
- (NSString *)notificationNameForPath:(NSString *)_path;
- (NSString *)unvalidateNotifyNameForPath:(NSString *)_path;
- (NSString *)changeNotifyNameForPath:(NSString *)_path;
- (NSString *)changeVersionNotifyNameForPath:(NSString *)_path;

@end /* SkyProjectFileManager(Notifications+Internals) */

@implementation SkyProjectFileManager(Notifications)

- (void)registerObject:(id)_obj selector:(SEL)_sel
  forUnvalidateOnPath:(NSString *)_path
{
  [[self notificationCenter] addObserver:_obj selector:_sel 
                             name:[self unvalidateNotifyNameForPath:_path]
                             object:self];
  
}

- (void)registerObject:(id)_obj selector:(SEL)_sel
  forChangeOnPath:(NSString *)_path
{
  [[self notificationCenter] addObserver:_obj selector:_sel
                             name:[self changeNotifyNameForPath:_path]
                             object:nil];
}

- (void)registerObject:(id)_obj selector:(SEL)_sel
  forVersionChangeOnPath:(NSString *)_path
{
  [[self notificationCenter] addObserver:_obj selector:_sel
                             name:[self changeVersionNotifyNameForPath:_path]
                             object:nil];
}

- (void)postUnvalidateNotificationForPath:(NSString *)_path {
  [[self notificationCenter] postNotificationName:
                             [self unvalidateNotifyNameForPath:_path]
                             object:nil];
}

- (void)postChangeNotificationForPath:(NSString *)_path {
  [[self notificationCenter] postNotificationName:
                             [self changeNotifyNameForPath:_path]
                             object:nil];
}

- (void)postVersionChangeNotificationForPath:(NSString *)_path {
  [[self notificationCenter] postNotificationName:
                             [self changeVersionNotifyNameForPath:_path]
                             object:nil];
}

- (void)postSkyGlobalIDWasDeleted:(EOGlobalID *)_gid {
  return;
}
- (void)postSkyGlobalIDWasCopied:(EOGlobalID *)_gid {
  return;
}

@end /* SkyProjectFileManager(Notifications) */

@implementation SkyProjectFileManager(Notifications_Internals)

static NSNotificationCenter *notificationCenter = nil;

- (NSNotificationCenter *)notificationCenter {
  if (notificationCenter == nil)
    notificationCenter = [[NSNotificationCenter defaultCenter] retain];
  return notificationCenter;
}

// TODO: notification names should be constant - see top of file

- (NSString *)notificationNameForPath:(NSString *)_path {
  if (self->notifyPathName == nil) {
    self->notifyPathName =
      [[[[self->cache project] valueForKey:@"projectId"] stringValue] copy];
  }
  if (!(_path = [self _makeAbsolute:_path])) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  return [self->notifyPathName stringByAppendingString:_path];
}

- (NSString *)unvalidateNotifyNameForPath:(NSString *)_path {
  return [[self notificationNameForPath:_path]
                stringByAppendingString:@"_unvalidate"];
}
- (NSString *)changeNotifyNameForPath:(NSString *)_path {
  return [[self notificationNameForPath:_path]
                stringByAppendingString:@"_change"];
}
- (NSString *)changeVersionNotifyNameForPath:(NSString *)_path {
  return [[self notificationNameForPath:_path]
                stringByAppendingString:@"_changeVersion"];
}

@end /* SkyProjectFileManager(Notifications_Internals) */
