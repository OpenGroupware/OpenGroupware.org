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

#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include <OGoDocuments/SkyDocumentFileManager.h>
#include "common.h"

@class EOGenericRecord, NSString, NSMutableArray, NSArray;

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

@implementation SkyProjectFileManager(Locking)

- (BOOL)supportsVersioningAtPath:(NSString *)_path {
  return YES;
}
- (BOOL)supportsVersioning {
  return YES;
}
- (BOOL)supportsFolderDataSourceAtPath:(NSString *)_path {
  return YES;
}
- (BOOL)supportsLockingAtPath:(NSString *)_path {
  return YES;
}

- (BOOL)supportsFeature:(NSString *)_featureURI atPath:(NSString *)_path {
  if ([_featureURI isEqualToString:NGFileManagerFeature_DataSources])
    return [self supportsFolderDataSourceAtPath:_path];
  if ([_featureURI isEqualToString:NGFileManagerFeature_Versioning])
    return [self supportsVersioningAtPath:_path];
  if ([_featureURI isEqualToString:NGFileManagerFeature_Locking])
    return [self supportsLockingAtPath:_path];
  
  if ([_featureURI isEqualToString:NGFileManagerFeature_Documents])
    return YES;
  return NO;
}

- (BOOL)checkoutFileAtPath:(NSString *)_path handler:(id)_handler {
  NSDictionary *attrs;
  NSString     *version;
  int          ec;

  if (!(_path = [self _makeAbsolute:_path])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  if ((version = [_path pathVersion])) {
    return [self checkoutFileAtPath:[_path stringByDeletingPathVersion]
                 version:version handler:_handler];
  }
  if (!(attrs  = [self fileAttributesAtPath:_path traverseLink:NO])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:_handler
                 cmd:_cmd];
  }
  if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [self _buildErrorWithSource:_path dest:nil msg:48 handler:_handler
                 cmd:_cmd];
    
  if ([[attrs objectForKey:@"SkyStatus"] isEqualToString:@"edited"]) {
    return [self _buildErrorWithSource:_path dest:nil msg:49 handler:_handler
                 cmd:_cmd];
  }
  if (![self isWritableFileAtPath:_path]) {
    return [self _buildErrorWithSource:_path dest:nil msg:35 handler:nil
                 cmd:_cmd];
  }
  NS_DURING {
    id d;
    ec = 0;
    if ((d = [self->cache genericRecordForAttrs:attrs manager:self])) {
      [[self context] runCommand:@"doc::checkout", @"object", d, nil];
    }
    else
      ec = 4;
  }
  NS_HANDLER {
    ec = 50;
    [self setLastException:localException];
  }
  NS_ENDHANDLER;
  if (ec)
    return [self _buildErrorWithSource:_path dest:nil msg:ec handler:_handler
                 cmd:_cmd];

  [self postChangeNotificationForPath:[_path stringByDeletingLastPathComponent]];
  [self flush];
  attrs  = [self fileAttributesAtPath:_path traverseLink:NO];
  return YES;
}

- (BOOL)releaseFileAtPath:(NSString *)_path handler:(id)_handler {
  NSDictionary *attrs;
  int          ec;

  if (!(_path = [self _makeAbsolute:_path])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  if (!(attrs  = [self fileAttributesAtPath:_path traverseLink:NO])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:_handler
                 cmd:_cmd];
  }
  if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [self _buildErrorWithSource:_path dest:nil msg:48 handler:_handler
                 cmd:_cmd];

  if (![self isWritableFileAtPath:_path]) {
    return [self _buildErrorWithSource:_path dest:nil msg:35 handler:nil
                 cmd:_cmd];
  }    
  if ([[attrs objectForKey:@"SkyStatus"] isEqualToString:@"released"])
    return [self _buildErrorWithSource:_path dest:nil msg:51 handler:_handler
                 cmd:_cmd];
  NS_DURING {
    id d;
    ec = 0;
    if ((d = [self->cache genericRecordForAttrs:attrs manager:self])) {
      d = [d valueForKey:@"toDoc"];
      [[self context] runCommand:@"doc::release", @"object", d, nil];
    }
    else
      ec = 4;
  }
  NS_HANDLER {
    ec = 52;
    [self setLastException:localException];
    [self _buildErrorWithSource:_path dest:nil msg:ec handler:_handler
                 cmd:_cmd];
  }
  NS_ENDHANDLER;
  if (ec)
    return NO;

  [self postChangeNotificationForPath:[_path stringByDeletingLastPathComponent]];
  [self postVersionChangeNotificationForPath:_path];
  [self flush];
  
  return YES;
}

- (BOOL)rejectFileAtPath:(NSString *)_path handler:(id)_handler {
  NSDictionary *attrs;
  int          ec;
  
  if (!(_path = [self _makeAbsolute:_path])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  if (!(attrs  = [self fileAttributesAtPath:_path traverseLink:NO])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:_handler
                 cmd:_cmd];
  }
  if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [self _buildErrorWithSource:_path dest:nil msg:48 handler:_handler
                 cmd:_cmd];

  if (![self isWritableFileAtPath:_path]) {
    return [self _buildErrorWithSource:_path dest:nil msg:35 handler:nil
                 cmd:_cmd];
  }    
  if ([[attrs objectForKey:@"SkyStatus"] isEqualToString:@"released"])
    return [self _buildErrorWithSource:_path dest:nil msg:51 handler:_handler
                 cmd:_cmd];

  NS_DURING {
    id d;

    ec = 0;

    if ((d = [self->cache genericRecordForAttrs:attrs manager:self])) {
      d = [d valueForKey:@"toDoc"];
      [[self context] runCommand:@"doc::reject", @"object", d, nil];
    }
    else
      ec = 4;
  }
  NS_HANDLER {
    ec= 53;
    [self setLastException:localException];
    [self _buildErrorWithSource:_path dest:nil msg:ec handler:_handler
                 cmd:_cmd];
  }
  NS_ENDHANDLER;
  if (ec)
    return NO;

  [self postChangeNotificationForPath:[_path stringByDeletingLastPathComponent]];
  [self flush];
  return YES;
}

- (FMVersioningStatus)versioningStatusAtPath:(NSString *)_path {
  NSString     *status;
  NSDictionary *attrs;
  
  if (!(attrs = [self fileAttributesAtPath:_path traverseLink:NO])) {
    return FMVersioningStatus_UNKNOWN;
  }
  if (!(status = [attrs objectForKey:@"SkyStatus"])) {
    return FMVersioningStatus_UNKNOWN;
  }
  return [status isEqualToString:@"edited"]
    ? FMVersioningStatus_EDIT : FMVersioningStatus_RELEASED;
}

- (BOOL)checkoutFileAtPath:(NSString *)_path version:(NSString *)_version
  handler:(id)_handler
{
  NSDictionary *attrs;
  int          ec;

  if (!(_path = [self _makeAbsolute:_path])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  if (![_version length])
    return [self _buildErrorWithSource:_path dest:nil msg:54 handler:_handler
                 cmd:_cmd];

  if (!(attrs  = [self fileAttributesAtPath:_path traverseLink:NO])) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:_handler
                 cmd:_cmd];
  }
  if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [self _buildErrorWithSource:_path dest:nil msg:48 handler:_handler
                 cmd:_cmd];

  if (![self isReadableFileAtPath:_path]) {
      [self _buildErrorWithSource:_path dest:nil msg:29 handler:_handler
          cmd:_cmd];
  }
  attrs = [self->cache versionAttrsAtPath:_path version:_version manager:self];
  NS_DURING {
    id d;

    ec = 0;
    if ((d = [self->cache genericRecordForAttrs:attrs manager:self])) {
      [[self context] runCommand:@"documentversion::checkout",
                      @"object", d, nil];
    }
    else
      ec = 4;
  }
  NS_HANDLER {
    ec = 55;
    [self setLastException:localException];
  }
  NS_ENDHANDLER;
  if (ec)
    return [self _buildErrorWithSource:_path dest:nil msg:ec handler:_handler
                 cmd:_cmd];

  [self postChangeNotificationForPath:[_path stringByDeletingLastPathComponent]];
  [self flush];
  return YES;
}

- (NSString *)lastVersionAtPath:(NSString *)_path {
  NSEnumerator *versions;
  NSDictionary *v;
  NSDictionary *version = nil;

  if (!(_path = [self _makeAbsolute:_path])) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  versions = [[self->cache allVersionAttrsAtPath:_path manager:self]
                    objectEnumerator];
  while ((v = [versions nextObject])) {
    if (version == nil)
      version = v;
    else {
      if ([(NSDate *)[version valueForKey:@"archiveDate"]
                    compare:[v valueForKey:@"archiveDate"]] == NSOrderedAscending)
        version = v;
    }
  }
  return [[version objectForKey:@"SkyVersionName"] stringValue];
}

- (NSArray *)versionsAtPath:(NSString *)_path {
  if (!(_path = [self _makeAbsolute:_path])) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  return [[[self->cache allVersionAttrsAtPath:_path manager:self]
                        map:@selector(objectForKey:) with:@"SkyVersionName"]
                        map:@selector(stringValue)]; 
}

- (NSData *)contentsAtPath:(NSString *)_path version:(NSString *)_version {
  NSDictionary *attrs;
  NSString     *dataPath;

  if (!(_path = [self _makeAbsolute:_path])) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  if (!(attrs = [self->cache versionAttrsAtPath:_path version:_version
                     manager:self])) {
    return nil;
  }
  if (![self isReadableFileAtPath:_path]) {
    [self _buildErrorWithSource:_path dest:nil msg:29 handler:nil cmd:_cmd];
    return nil;
  }
  if (!(dataPath = [attrs objectForKey:@"SkyBlobPath"])) {
    [self _buildErrorWithSource:_path dest:nil msg:56 handler:nil cmd:_cmd];
    return nil;
  }
  return [NSData dataWithContentsOfFile:dataPath];
}

- (NSDictionary *)fileAttributesAtPath:(NSString *)_path
  traverseLink:(BOOL)_followLink
  version:(NSString *)_version
{
  if (!(_path = [self _makeAbsolute:_path])) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  return [self->cache versionAttrsAtPath:_path version:_version
              manager:self];
}

@end /* SkyProjectFileManager(Locking) */
