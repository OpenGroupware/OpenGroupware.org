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

#include <OGoDatabaseProject/SkyProjectDocument.h>

/*
  supported JS properties:
    
    String path         (readonly)
    String name         (readonly)
    BOOL   isVersioned  (readonly)
    BOOL   isReadable   (readonly)
    BOOL   isWriteable  (readonly)
    BOOL   isRemovable  (readonly)
    BOOL   isLocked     (readonly)
    BOOL   isEdited     (readonly)
    BOOL   isDirectory  (readonly)
    
  supported JS functions:
    
    Object getAttribute(name [,ns-uri])
    BOOL   hasAttribute(name [,ns-uri])
    BOOL   setAttribute(name [,ns-uri], value)
    BOOL   removeAttribute(name [,ns-uri])

    BOOL   save()
    BOOL   reload([newpath])
    BOOL   remove()

    String getLastVersion()
    Array  getVersionTags()
    BOOL   moveToPath(newpath)
    BOOL   copyToPath(newpath)
    BOOL   checkout()
    BOOL   release()
    BOOL   reject()
    
    DataSource getHistoryDataSource([cache=YES])
    DataSource getFolderDataSource([cache=YES])
*/

#include <OGoDatabaseProject/SkyProjectDocument.h>
#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include <NGExtensions/EOCacheDataSource.h>
#include "common.h"

@implementation SkyProjectDocument(JSSupport)

static NSNumber *yesNum = nil;
static NSNumber *noNum  = nil;

static void _ensureBools(void) {
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  if (noNum  == nil) noNum  = [[NSNumber numberWithBool:NO]  retain];
}

/* properties (use KVC to ensure access via keypath !!!) */

- (id)_jsprop_path {
  return [self valueForKey:@"path"];
}
- (id)_jsprop_name {
  return [self valueForKey:@"name"];
}

- (id)_jsprop_isVersioned {
  _ensureBools();
  return [self isVersioned] ? yesNum : noNum;
}
- (id)_jsprop_isLocked {
  _ensureBools();
  return [self isLocked] ? yesNum : noNum;
}

- (id)_jsprop_isReadable {
  _ensureBools();
  return [self isReadable] ? yesNum : noNum;
}
- (id)_jsprop_isWriteable {
  _ensureBools();
  return [self isWriteable] ? yesNum : noNum;
}
- (id)_jsprop_isRemovable {
  _ensureBools();
  return [self isDeletable] ? yesNum : noNum;
}
- (id)_jsprop_isEdited {
  _ensureBools();
  return [self isEdited] ? yesNum : noNum;
}
- (id)_jsprop_isDirectory {
  _ensureBools();
  return [self isDirectory] ? yesNum : noNum;
}

/* methods */

- (id)_jsfunc_getAttribute:(NSArray *)_args {
  unsigned count;
  NSString *key;
  NSString *ns;

  if ((count = [_args count]) == 0)
    return nil;

  if (count == 1)
    return [self valueForKey:[_args objectAtIndex:0]];
    
  key = [_args objectAtIndex:0];
  ns  = [_args objectAtIndex:1];
    
  key = [ns length] > 0
    ? [NSString stringWithFormat:@"{%@}%@", ns, key]
    : key;
    
  return [self valueForKey:key];
}

- (id)_jsfunc_hasAttribute:(NSArray *)_args {
  _ensureBools();
  return ([self _jsfunc_getAttribute:_args] != nil)
    ? yesNum : noNum;
}

- (id)_jsfunc_setAttribute:(NSArray *)_args {
  unsigned count;
  NSString *key;
  id   value;
  BOOL result;
  _ensureBools();
  
  if ((count = [_args count]) < 2) {
    return noNum;
  }
  else if (count == 2) {
    key   = [_args objectAtIndex:0];
    value = [_args objectAtIndex:1];
  }
  else {
    NSString *ns;
    
    key   = [_args objectAtIndex:0];
    ns    = [_args objectAtIndex:1];
    value = [_args objectAtIndex:2];
    
    key = [ns length] > 0
      ? [NSString stringWithFormat:@"{%@}%@", ns, key]
      : key;
  }

  result = YES;
  NS_DURING
    [self takeValue:value forKey:key];
  NS_HANDLER
    result = NO;
  NS_ENDHANDLER;
  
  return result ? yesNum : noNum;
}

- (id)_jsfunc_removeAttribute:(NSArray *)_args {
  unsigned count;
  NSString *key;
  BOOL result;
  _ensureBools();
  
  if ((count = [_args count]) == 0)
    return noNum;
  else if (count == 1)
    key = [_args objectAtIndex:0];
  else {
    NSString *ns;
    
    key = [_args objectAtIndex:0];
    ns  = [_args objectAtIndex:1];
    
    key = [ns length] > 0
      ? [NSString stringWithFormat:@"{%@}%@", ns, key]
      : key;
  }

  result = YES;
  NS_DURING
    [self takeValue:nil forKey:key];
  NS_HANDLER
    result = NO;
  NS_ENDHANDLER;
  
  return result ? yesNum : noNum;
}

- (id)_jsfunc_remove:(NSArray *)_args {
  _ensureBools();
  return [self delete] ? yesNum : noNum;
}

- (id)_jsfunc_save:(NSArray *)_args {
  unsigned count;
  _ensureBools();
  
  count = [_args count];

  if (count > 0) {
#if DEBUG
    NSLog(@"%s: -save() doesn't support arguments (%@) ... ",
          __PRETTY_FUNCTION__, _args);
#endif
  }
  
  return [self save] ? yesNum : noNum;
}

- (id)_jsfunc_reload:(NSArray *)_args {
  unsigned count;
  _ensureBools();
  
  if ((count = [_args count]) == 0)
    return [self reload] ? yesNum : noNum;
  else
    return noNum;
}

/* filemanager stuff */

- (id)_jsfunc_getLastVersion:(NSArray *)_args {
  _ensureBools();
  if (![[self fileManager] supportsVersioningAtPath:[self _jsprop_path]])
    return nil;
  
  return [[self fileManager] lastVersionAtPath:[self _jsprop_path]];
}
- (id)_jsfunc_getVersionTags:(NSArray *)_args {
  _ensureBools();
  if (![[self fileManager] supportsVersioningAtPath:[self _jsprop_path]])
    return [NSArray array];
  
  return [[self fileManager] versionsAtPath:[self _jsprop_path]];
}

- (id)_jsfunc_moveToPath:(NSArray *)_args {
  NSString *newpath;
  id   fm;
  BOOL res;
  BOOL isDir;
  _ensureBools();
  
  if ([_args count] > 0)
    newpath = [_args objectAtIndex:0];
  else
    newpath = nil;
  
  if (newpath == nil)
    return noNum;

  fm = [self fileManager];

  if (![fm fileExistsAtPath:newpath isDirectory:&isDir])
    isDir = NO;
  if (isDir)
    newpath = [newpath stringByAppendingPathComponent:[self _jsprop_name]];
  
  res = [fm movePath:[self _jsprop_path] toPath:newpath handler:self];
  
  if (!res) {
#if DEBUG
    NSLog(@"%s: move failed: %@", __PRETTY_FUNCTION__,
          [[self fileManager] lastException]);
#endif
    return noNum;
  }
  return yesNum;
}

- (id)_jsfunc_copyToPath:(NSArray *)_args {
  NSString *newpath;
  BOOL res;
  BOOL isDir;
  id   fm;
  _ensureBools();
  
  newpath = ([_args count] > 0)
    ? [_args objectAtIndex:0]
    : nil;
  
  if (newpath == nil)
    return noNum;
  
  fm = [self fileManager];
  
  if (![fm fileExistsAtPath:newpath isDirectory:&isDir])
    isDir = NO;
  if (isDir)
    newpath = [newpath stringByAppendingPathComponent:[self _jsprop_name]];
  
  res = [fm copyPath:[self _jsprop_path] toPath:newpath handler:self];
  
  if (!res) {
#if DEBUG
    NSLog(@"%s: copy failed: %@", __PRETTY_FUNCTION__,
          [[self fileManager] lastException]);
#endif
    return noNum;
  }
  return yesNum;
}

- (id)_jsfunc_checkout:(NSArray *)_args {
  _ensureBools();
  if ([_args count] > 0) {
    NSString *v;

    v = [_args objectAtIndex:0];
  
    if ([[self fileManager] checkoutFileAtPath:[self _jsprop_path] version:v handler:self])
      return yesNum;
  }
  else {
    if ([[self fileManager] checkoutFileAtPath:[self _jsprop_path] handler:self])
      return yesNum;
  }
  return noNum;
}
- (id)_jsfunc_release:(NSArray *)_args {
  _ensureBools();
  if ([[self fileManager] releaseFileAtPath:[self _jsprop_path] handler:self])
    return yesNum;
  else
    return noNum;
}
- (id)_jsfunc_reject:(NSArray *)_args {
  _ensureBools();
  if ([[self fileManager] rejectFileAtPath:[self _jsprop_path] handler:self])
    return yesNum;
  else
    return noNum;
}

/* datasources */

- (id)_jsfunc_getFolderDataSource:(NSArray *)_args {
  EODataSource *fds;
  unsigned count;
  BOOL     doCache = YES;

  if ((fds = [self folderDataSource]) == nil)
    return nil;
  
  if ((count = [_args count]) > 0)
    doCache = [[_args objectAtIndex:0] boolValue];
  
  if (doCache)
    fds = [[[EOCacheDataSource alloc] initWithDataSource:fds] autorelease];
  
  return fds;
}
- (id)_jsfunc_getHistoryDataSource:(NSArray *)_args {
  EODataSource *ds;
  unsigned count;
  BOOL     doCache = YES;
  
  NS_DURING {
    ds = (id)[self historyDataSource];
  }
  NS_HANDLER {
    printf("getHistoryDataSource(): catched %s\n",
           [[localException description] cString]);
    *(&ds) = nil;
  }
  NS_ENDHANDLER;

  if ((count = [_args count]) > 0)
    doCache = [[_args objectAtIndex:0] boolValue];

  if (doCache)
    ds = [[[EOCacheDataSource alloc] initWithDataSource:ds] autorelease];
  
  return ds;
}

@end /* SkyProjectDocument(JSSupport) */
