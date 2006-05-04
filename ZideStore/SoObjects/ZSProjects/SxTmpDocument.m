/*
  Copyright (C) 2006 Helge Hess

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

#include "SxTmpDocument.h"
#include "SxProjectFolder.h"
#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include "common.h"

@implementation SxTmpDocument

static BOOL debugOn = YES;

- (id)initWithName:(NSString *)_name inContainer:(id)_container {
  return [self initWithName:_name inFolder:_container];
}

- (void)dealloc {
  [self->storageDirPath release];
  [self->storagePath    release];
  [super dealloc];
}

/* folder operations */

- (BOOL)isProjectRootFolder {
  return NO;
}

- (SxProjectFolder *)projectFolder {
  return [[self container] projectFolder];
}

- (SkyProjectFileManager *)projectFileManagerInContext:(id)_ctx {
  return [[self container] fileManagerInContext:_ctx];
}

/* storage */

- (NSFileManager *)fileManager {
  static NSFileManager *fm = nil; // THREAD
  if (fm == nil) fm = [[NSFileManager defaultManager] retain];
  return fm;
}

- (NSString *)projectFolderKey {
  /* Note: just the folder ID would be sufficient, but lets be conservative */
  NSDictionary  *attrs;
  EOKeyGlobalID *gid;
  char buf[256];
  
  attrs = [[self container] fileAttributes];
  if ((gid = [attrs valueForKey:@"globalID"]) == nil) {
    [self errorWithFormat:@"did not find global id of container: %@", 
	    [self container]];
    return nil;
  }
  
  snprintf(buf, sizeof(buf), "p%08i-f%08i",
	   [[attrs valueForKey:@"projectId"] intValue],
	   [[gid keyValues][0] intValue]);
  return [NSString stringWithCString:buf];
}

- (NSString *)storageDirPathInContext:(id)_ctx {
  /* 
     Schema:
       LSAttachmentPath/tmp-login-user-id/folder-key/filename
     Sample:
       /var/lib/opengroupware.org/documents/tmp-root-10000/p223-f333/~file.tmp
  */
  static NSString *basePath = nil; // THREAD
  NSMutableString *ms;
  id login;

  if (self->storageDirPath != nil)
    return self->storageDirPath;
  
  if (basePath == nil) {
    basePath = [[[NSUserDefaults standardUserDefaults] 
		                 stringForKey:@"LSAttachmentPath"] copy];
  }
  
  /* setup basepath */
  
  ms = [[NSMutableString alloc] initWithCapacity:[basePath length] + 128];
  [ms appendString:basePath];
  if (![basePath hasSuffix:@"/"]) [ms appendString:@"/"];
  
  /* add user ID (each user has his own tmp section) */
  
  login = [[self commandContextInContext:_ctx] valueForKey:LSAccountKey];
  if (login == nil) {
    [ms release];
    return nil;
  }
  [ms appendString:@"tmp-"];
  [ms appendString:[login valueForKey:@"login"]];
  [ms appendString:@"-"];
  [ms appendString:[[login valueForKey:@"companyId"] stringValue]];
  [ms appendString:@"/"];
  
  /* add folder ID */
  
  [ms appendString:[self projectFolderKey]];
  
  /* cache */
  self->storageDirPath = [ms copy];
  [ms release];
  return self->storageDirPath;
}

- (NSString *)storagePathInContext:(id)_ctx {
  if (self->storagePath == nil) {
    NSString *p;
    
    p = [[self storageDirPathInContext:_ctx] stringByAppendingString:@"/"];
    self->storagePath =
      [[p stringByAppendingString:[self nameInContainer]] copy];
  }
  return self->storagePath;
}

/* methods */

- (id)GETAction:(WOContext *)_ctx {
  WOResponse *r;
  NSString   *p;
  NSData     *data;
  
  p = [self storagePathInContext:_ctx];
  if (debugOn) [self debugWithFormat:@"tmpfile: '%@'", p];
  
  if (![[self fileManager] fileExistsAtPath:p]) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"Did not find temporary file on server!"];
  }
  
  if ((data = [[NSData alloc] initWithContentsOfMappedFile:p]) == nil) {
    [self errorWithFormat:@"Could not open temporary file: '%@'", p];
    return [NSException exceptionWithHTTPStatus:500 /* Server Error */
			reason:@"Could not open temporary file on server!"];
  }
  
  r = [_ctx response];
  [r setStatus:200 /* OK */];
  [r setContent:data];
  [r setHeader:[NSString stringWithFormat:@"%i", [data length]]
     forKey:@"content-length"];
  
  [data release]; data = nil;
  return r;
}

- (id)HEADAction:(WOContext *)_ctx {
  WOResponse *r;
  
  /* a bit expensive, but hey, its just a temporary file */
  r = [self GETAction:_ctx];
  
  if ([r isKindOfClass:[WOResponse class]])
    [r setContent:[NSData data]];
  return r;
}

- (NSException *)_prepareWorkspaceInContext:(WOContext *)_ctx {
  NSFileManager *fm;
  NSString      *dp, *userdir;
  
  fm = [self fileManager];
  dp = [self storageDirPathInContext:_ctx];
  if ([fm fileExistsAtPath:dp])
    return nil;

  [self debugWithFormat:@"creating tmpfile folder workspace: %@", dp];
    
  userdir = [dp stringByDeletingLastPathComponent];
  if (![fm fileExistsAtPath:userdir]) {
    [self debugWithFormat:@"creating tmpfile workspace: %@", userdir];
      
    if (![fm createDirectoryAtPath:userdir attributes:nil]) {
      [self errorWithFormat:
	      @"Could not create user tmpdir workspace: '%@'", userdir];
      return [NSException exceptionWithHTTPStatus:500
			  reason:
			    @"Could not create temporary file workspace!"];
    }
  }
    
  if (![fm createDirectoryAtPath:dp attributes:nil]) {
    [self errorWithFormat:
	    @"Could not create folder tmpdir workspace: '%@'", dp];
    return [NSException exceptionWithHTTPStatus:500
			reason:@"Could not create temporary file folder!"];
  }
  
  return nil; /* everything is fine */
}

- (NSException *)putContent:(NSData *)_content
  asCopyFromDocument:(id)_document
  inContext:(id)_ctx
{
  NSException *error;
  NSString *p;
  
  p  = [self storagePathInContext:_ctx];
  if (debugOn) [self debugWithFormat:@"tmpfile: '%@'", p];
  
  if ((error = [self _prepareWorkspaceInContext:_ctx]) != nil)
    return error;
  
  // TODO: we might want to check the 'overwrite' header ...
  
  if (![_content writeToFile:p atomically:YES]) {
    [self errorWithFormat:@"Could not write temporary file: '%@'",p];
    return [NSException exceptionWithHTTPStatus:500
			reason:@"Could not write temporary file on server!"];
  }
  
  return nil; /* everything is fine */
}

- (id)PUTAction:(WOContext *)_ctx {
  NSException *error;
  NSString *p;

  p  = [self storagePathInContext:_ctx];
  if (debugOn) [self debugWithFormat:@"tmpfile: '%@'", p];
  
  /* ensure that the workspace dir exists (we never delete them!) */
  if ((error = [self _prepareWorkspaceInContext:_ctx]) != nil)
    return error;
  
  /* save file */

  // TODO: maybe we should return 201 for new files?
  
  if (![[[_ctx request] content] writeToFile:p atomically:YES]) {
    [self errorWithFormat:@"Could not write temporary file: '%@'",p];
    return [NSException exceptionWithHTTPStatus:500
			reason:@"Could not write temporary file on server!"];
  }
  
  return [NSNumber numberWithBool:YES]; /* everything OK */
}

- (id)DELETEAction:(id)_ctx {
  NSString *p;
  
  p = [self storagePathInContext:_ctx];
  if (debugOn) [self debugWithFormat:@"tmpfile: '%@'", p];
  
  if (![[self fileManager] fileExistsAtPath:p]) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"Did not find temporary file on server!"];
  }
  
  if (![[self fileManager] removeFileAtPath:p handler:nil]) {
    [self errorWithFormat:@"Could not delete temporary file: '%@'",p];
    return [NSException exceptionWithHTTPStatus:500
			reason:@"Could not delete temporary file on server!"];
  }
  
  return [NSNumber numberWithBool:YES]; /* everything OK */
}


/* copy/move methods */

- (NSException *)davMoveToTargetObject:(id)_target newName:(NSString *)_name
  inContext:(id)_ctx
{
  /*
    Note: this is basically a CHECKIN operation. Its used by Word 2003 over
          NetDrive to update the 'real' file atomically.
  */
  NSException *error;
  NSString *p;
  
  p = [self storagePathInContext:_ctx];
  if (debugOn) [self debugWithFormat:@"tmpfile: '%@'", p];
  
  /* first copy the file */
  
  error = [self davCopyToTargetObject:_target newName:_name inContext:_ctx];
  if (error != nil)
    return error;
  
  /* then delete it */

  if (![[self fileManager] removeFileAtPath:p handler:nil]) {
    [self errorWithFormat:@"Could not delete temporary file: '%@'",p];
#if 0 /* we ignore this, little we can do about it */
    return [NSException exceptionWithHTTPStatus:500
			reason:@"Could not delete temporary file on server!"];
#endif
  }
  
  return nil; /* everything is OK */
}

- (NSException *)davCopyToTargetObject:(id)_target newName:(NSString *)_name
  inContext:(id)_ctx
{
  NSString   *p;
  NSData     *data;
  
  p = [self storagePathInContext:_ctx];
  if (debugOn) [self debugWithFormat:@"tmpfile: '%@'", p];

  if (![[self fileManager] fileExistsAtPath:p]) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"Did not find temporary file on server!"];
  }
  
  /* this should never happen, but better to test ... */
  if ([_name isNotEmpty])
    return [NSException exceptionWithHTTPStatus:501 reason:@"not implemented"];
  
  /* check whether the target can accept our content */
  if (![_target respondsToSelector:
		  @selector(putContent:asCopyFromDocument:inContext:)]) {
    return [NSException exceptionWithHTTPStatus:501 
			reason:
			  @"Unsuitable move target (must be a doc)!"];
  }

  /* retrieve content */
  
  if ((data = [NSData dataWithContentsOfMappedFile:p]) == nil) {
    [self errorWithFormat:@"Could not open temporary file: '%@'", p];
    return [NSException exceptionWithHTTPStatus:500 /* Server Error */
			reason:@"Could not open temporary file on server!"];
  }
  
  /* update the target */
  return [_target putContent:data asCopyFromDocument:self inContext:_ctx];
}

@end /* SxTmpDocument */
