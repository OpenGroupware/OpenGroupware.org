/*
  Copyright (C) 2002-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include "SxDocument.h"
#include "SxProjectFolder.h"
#include "SxTmpDocument.h"
#include <OGoDocuments/SkyDocumentFileManager.h>
#include <OGoDocuments/SkyDocument.h>
#include "common.h"

// TODO: might add support for versions?! (aka name.txt;1)

@implementation SxDocument

static BOOL debugOn = NO;
static BOOL SxDocumentAutoCheckout = YES;

static NSException *FMLastError(id fm) {
  if (![fm respondsToSelector:@selector(lastException)])
    return nil;
  return [fm lastException];
}

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if ((debugOn = [ud boolForKey:@"SxDocumentDebugEnabled"]))
    NSLog(@"SxDocument: debugging enabled.");
  
  if ([ud boolForKey:@"SxDocumentNoAutoCheckout"]) {
    SxDocumentAutoCheckout = NO;
    NSLog(@"SxDocument: auto-checkout disabled.");
  }
}

- (id)initWithName:(NSString *)_name inContainer:(id)_container {
  return [self initWithName:_name inFolder:_container];
}

- (void)dealloc {
  [self->attrCache release];
  [super dealloc];
}

/* folder operations */

- (BOOL)isProjectRootFolder {
  return NO;
}

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx {
  id tmp;
  
  if ((tmp = [self container]) == nil)
    return nil;
  if (tmp == self) /* loop?! */
    return nil;
  
  return [tmp projectGlobalIDInContext:_ctx];
}
- (id)fileManagerInContext:(id)_ctx {
  id tmp;
  
  if ((tmp = [self container]) == nil)
    return nil;
  if (tmp == self) /* loop?! */
    return nil;
  
  return [tmp fileManagerInContext:_ctx];
}
- (id)fileManager {
  return [self fileManagerInContext:nil];
}

- (SxProjectFolder *)projectFolder {
  return [[self container] projectFolder];
}

- (NSString *)storagePath {
  return [[[self container] storagePath] 
                 stringByAppendingString:[self nameInContainer]];
}

- (SkyDocument *)documentInContext:(id)_ctx {
  id<SkyDocumentFileManager> fm;
  NSString *p;
  
  if (_ctx == nil)
    _ctx = [(WOApplication *)[WOApplication application] context];
  
  if ((fm = [self fileManagerInContext:_ctx]) == nil)
    return nil;
  if ([(p = [self storagePath]) length] == 0)
    return nil;
  
  return [fm documentAtPath:p];
}

/* attributes */

- (NSDictionary *)fileAttributes {
  id fm;
  
  if ((fm = [self fileManager]) == nil)
    return nil;
  
  if (self->attrCache == nil) {
    self->attrCache =
      [[fm fileAttributesAtPath:[self storagePath] traverseLink:NO] copy];
    //[self debugWithFormat:@"ATTRS: %@", self->attrCache];
  }
  return self->attrCache;
}

- (NSString *)etag {
  NSDictionary *attrs;
  NSString *s;
  
  if ((attrs = [self fileAttributes]) == nil)
    return nil;

  if ([(s = [attrs valueForKey:@"SkyStatus"]) isNotNull]) {
    /* 
       Note: just the file version is not enough because the file can be
             deleted and then get recreated resulting in the same version
	     for a different file.
	     So we add the file-id which is supposed to be unique forever
	     (well, the livetime of the database).
    */
    EOKeyGlobalID *gid;
    
    gid = [attrs valueForKey:@"globalID"];
    
    /* we assume a DB backend */
    if ([s isEqualToString:@"edited"]) {
      s = [attrs valueForKey:@"NSFileModificationDate"];
      if ([s isKindOfClass:[NSDate class]]) {
        s = [NSString stringWithFormat:@"edit_%09d_",
                      (unsigned int)[(NSDate *)s timeIntervalSince1970]];
      }
      else
        s = [@"edit-" stringByAppendingString:s];
    }
    else
      s = @"v";
    
    s = [s stringByAppendingString:
             [[attrs valueForKey:@"SkyVersionCount"] stringValue]];

    if ([gid isNotNull]) {
      s = [[[[gid keyValues][0] stringValue] stringByAppendingString:@"-"]
	          stringByAppendingString:s];
    }
    
    return s;
  }
  
  if ([(s = [attrs valueForKey:@"NSFileModificationDate"]) isNotNull]) {
    /* we assume an FS backend */
    if ([s isKindOfClass:[NSDate class]]) {
      s = [NSString stringWithFormat:@"md%09d",
                    (unsigned int)[(NSDate *)s timeIntervalSince1970]];
    }
    return s;
  }

  return nil;
}

/* content */

- (NSString *)contentAsStringInContext:(id)_ctx {
  SkyDocument *doc;
  
  if ((doc = [self documentInContext:_ctx]) == nil)
    return nil;
  if ([doc isKindOfClass:[NSException class]])
    return (id)doc;
  
  if (![doc supportsFeature:SkyDocumentFeature_STRINGBLOB])
    return nil;
  
  return [(id<SkyStringBLOBDocument>)doc contentAsString];
}
- (NSString *)contentAsString {
  return [self contentAsStringInContext:nil];
}

/* key/value coding */

- (id)valueForKey:(NSString *)_name {
  unsigned nl;
  unichar  c;
  
  if ((nl = [_name length]) == 0)
    return nil;
  
  c = [_name characterAtIndex:0];
  if (c == 'N' && (nl > 6)) {
    if ([_name hasPrefix:@"NSFile"])
      return [[self fileAttributes] objectForKey:_name];
  }
  
  return [super valueForKey:_name];
}

/* permissions */

- (BOOL)isDeletionAllowed {
  id       fm;
  NSString *p;
  
  if ((fm = [self fileManagerInContext:nil]) == nil)
    return NO;
  if ([(p = [self storagePath]) length] == 0)
    return NO;
  
  return [fm isDeletableFileAtPath:p];
}

/* actions */

- (id)internalError:(NSString *)_error {
  if (![_error isNotEmpty])
    _error = @"unknown internal error";
  return [NSException exceptionWithHTTPStatus:500 /* server error */
		      reason:_error];
}

- (NSException *)putContent:(NSData *)_content
  asCopyFromDocument:(id)_document
  inContext:(id)_ctx
{
  LSCommandContext *cmdctx;
  NSException *error;
  id       fm;
  NSString *p;
  BOOL     doesExist;
  BOOL     isDir;
  
  [self debugWithFormat:@"write file content: %@ ...", [self nameInContainer]];

  if ((fm = [self fileManagerInContext:_ctx]) == nil)
    return [self internalError:@"could not locate filemanager for project"];
  
  if (![(p = [self storagePath]) isNotEmpty])
    return [self internalError:@"could not calc project relative path"];

  doesExist = [fm fileExistsAtPath:p isDirectory:&isDir];
  
  if (doesExist && isDir) {
    // TODO: is 400 a good status for that? Maybe 501 is more appropriate if
    //       the collection supports no content.
    return [NSException exceptionWithHTTPStatus:400 /* bad request */
			reason:@"Tried to write content of a collection"];
  }
  
  /* check locking status and lock on demand */
  // TODO: check whether its a locking or versioned storage etc
  // TODO: checkout-on-demand, "checkin-after-time?"
  
  /* write the file */
  
  if (doesExist) {
    /* overwrite an existing file */
    
    if (![fm isWritableFileAtPath:p]) {
      [self debugWithFormat:@"not allowed to write file: %@", p];
      return [NSException exceptionWithHTTPStatus:403 /* Forbidden */
			  reason:@"You are not allowed to write this file."];
    }
    
    if (SxDocumentAutoCheckout) {
      if ([fm supportsVersioningAtPath:p]) {
	[self debugWithFormat:
		@"supports versioning, auto-checkout of path: %@", p];
	
	if ((error = FMLastError(fm)) != nil)
	  return error;
	
	if ([fm isFileLockedAtPath:p]) {
	  [self debugWithFormat:@"file is locked, no auto-checkout: %@", p];
	}
	else if (![fm checkoutFileAtPath:p handler:nil]) {
	  [self debugWithFormat:@"attempt to checkout file failed: %@",
		  FMLastError(fm)];
	  
	  return [NSException exceptionWithHTTPStatus:403 /* Forbidden */
			      reason:@"Could not checkout this file."];
	}
      }
    }
    
    if (![fm writeContents:_content atPath:p]) {
      [self debugWithFormat:@"could not write %i bytes to %@ (fm=%@)", 
	      [_content length], p, fm];
      
      if ((error = FMLastError(fm)) != nil)
	return error;
      
      return [self internalError:@"file writing failed, reason unknown"];
    }
  }
  else {
    /* create a new file */

#if 0 // TODO: not a public method?    
    if (![fm isInsertableDirectoryAtPath:
	       [p stringByDeletingLastPathComponent]]) {
      return [NSException exceptionWithHTTPStatus:403 /* Forbidden */
			  reason:@"You are not allowed to create a file."];
    }
#endif
    
    if (![fm createFileAtPath:p contents:_content attributes:nil]) {
      [self debugWithFormat:@"could not create file %i bytes at %@ (fm=%@)", 
	      [_content length], p, fm];
      
      if ((error = FMLastError(fm)) != nil)
	return error;
      
      return [self internalError:@"file creation failed, reason unknown"];
    }
  }
  
  /* commit transaction */
  
  cmdctx = [self commandContextInContext:_ctx];
  if ([cmdctx isTransactionInProgress]) {
    if (![cmdctx commit])
      return [self internalError:@"could not commit transaction!"];
  }
  
  return nil;
}

- (id)PUTAction:(id)_ctx {
  NSException *error;
  NSData   *data;
  
  if ([[self nameInContainer] hasPrefix:@"._"]) {
    // TODO: should we fake a 200 instead?
    // Note: this is handled by SxDocumentFolder as temp files now!
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"rejecting writes to resourcefork file"];
  }
  
  /* write the file */
  
  if ((data = [[(WOContext *)_ctx request] content]) == nil) {
    static NSData *emptyData = nil;
    if (emptyData == nil) emptyData = [[NSData alloc] init];
    data = (id)emptyData;
  }
  
  error = [self putContent:data asCopyFromDocument:nil inContext:_ctx];
  if (error != nil)
    return error;
  
  return [NSNumber numberWithBool:YES];
}

- (void)applyFileAttributesOnResponse:(WOResponse *)_response {
  NSDictionary *attrs;
  NSString *s;
  
  if ((attrs = [self fileAttributes]) == nil)
    return;
  
  if ([(s = [attrs valueForKey:@"NSFileMimeType"]) isNotNull])
    [_response setHeader:s forKey:@"content-type"];
  if ([(s = [attrs valueForKey:@"NSFileSize"]) isNotNull])
    [_response setHeader:[s stringValue] forKey:@"content-length"];
  
  if ((s = [self etag]) != nil)
    [_response setHeader:s forKey:@"etag"];
}

- (id)HEADAction:(id)_ctx {
  WOResponse *r;
  id       fm;
  NSString *p;

  if ((fm = [self fileManagerInContext:_ctx]) == nil)
    return [self internalError:@"could not locate filemanager for project"];
  
  if (![(p = [self storagePath]) isNotEmpty])
    return [self internalError:@"could not calc project relative path"];
  
  if (![fm fileExistsAtPath:p]) {
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"document does not exist"];
  }
  
  r = [(WOContext *)_ctx response];
  [r setStatus:200 /* OK */];
  [r setContent:(NSData *)[NSData data]];
  [self applyFileAttributesOnResponse:r];
  return r;
}

- (id)GETAction:(WOContext *)_ctx {
  WOResponse *r;
  id       fm;
  NSString *p;
  NSData   *content;
  
  if ((fm = [self fileManagerInContext:_ctx]) == nil)
    return [self internalError:@"could not locate filemanager for project"];
  
  if (![(p = [self storagePath]) isNotEmpty])
    return [self internalError:@"could not calc project relative path"];
  
  if ((content = [fm contentsAtPath:p]) == nil) {
    if ([fm respondsToSelector:@selector(lastException)])
      return [fm lastException];
    
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"could not read content of document"];
  }

  r = [_ctx response];
  [r setStatus:200 /* OK */];
  [r setContent:content];
  
  [self applyFileAttributesOnResponse:r];
  return r;
}

- (id)DELETEAction:(id)_ctx {
  LSCommandContext *cmdctx;
  id       fm;
  NSString *p;

  if ((fm = [self fileManagerInContext:_ctx]) == nil)
    return [self internalError:@"could not locate filemanager for project"];
  
  if ([(p = [self storagePath]) length] == 0)
    return [self internalError:@"could not calc project relative path"];
  
  if (![self isDeletionAllowed]) {
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:@"file deletion is not allowed"];
  }
  
  /* 
     Note: using 'self' as the handler implies that you need to implement
           certain methods!
  */
  if (![fm removeFileAtPath:p handler:nil]) {
    if ([fm respondsToSelector:@selector(lastException)])
      return [fm lastException];
    return [self internalError:@"file deleting failed, reason unknown"];
  }
  
  cmdctx = [self commandContextInContext:_ctx];
  if ([cmdctx isTransactionInProgress]) {
    if (![cmdctx commit])
      return [self internalError:@"could not commit transaction!"];
  }
  
  return [NSNumber numberWithBool:YES];
}

- (NSException *)davMoveToTargetObject:(id)_target newName:(NSString *)_name
  inContext:(id)_ctx
{
  if ([_target isKindOfClass:NSClassFromString(@"SxTmpDocument")]) {
    /* 
       We do not delete "real" resources for temporary files, see bug #1921 for
       details.
    */
    return [self davCopyToTargetObject:_target newName:_name inContext:_ctx];
  }
  
  return [[self projectFolder] moveObject:self toTarget:_target
			       newName:_name inContext:_ctx];
}

- (NSException *)davCopyToTargetObject:(id)_target newName:(NSString *)_name
  inContext:(id)_ctx
{
  if ([_target isKindOfClass:NSClassFromString(@"SxTmpDocument")]) {
    id       fm;
    NSString *p;
    NSData   *content;
    
    if ((fm = [self fileManagerInContext:_ctx]) == nil)
      return [self internalError:@"could not locate filemanager for project"];
    
    if (![(p = [self storagePath]) isNotEmpty])
      return [self internalError:@"could not calc project relative path"];
    
    if ((content = [fm contentsAtPath:p]) == nil) {
      if ([fm respondsToSelector:@selector(lastException)])
        return [fm lastException];
      
      return [NSException exceptionWithHTTPStatus:404 /* not found */
			  reason:@"could not read content of document"];
    }
    
    return [_target putContent:content asCopyFromDocument:self inContext:_ctx];
  }
  
  return [[self projectFolder] copyObject:self toTarget:_target
			       newName:_name inContext:_ctx];
}

/* common DAV attributes */

- (NSString *)davDisplayName {
  // TODO: use title if available?
  return [self nameInContainer];
}
- (BOOL)davIsCollection {
  return NO;
}
- (BOOL)davIsFolder {
  /* this can be overridden by compound documents (aka filewrappers) */
  return [self davIsCollection];
}
- (BOOL)davHasSubFolders {
  return NO;
}

- (id)davContentLength {
  return [[self fileAttributes] objectForKey:NSFileSize];
}
- (NSDate *)davLastModified {
  return [[self fileAttributes] objectForKey:NSFileModificationDate];
}

/* Blogger support */

- (NSString *)bloggerContentInContext:(id)_ctx {
  NSString *s;
  
  s = [[self nameInContainer] pathExtension];
  if ([s isEqualToString:@"txt"]) {
    s = [self contentAsStringInContext:_ctx];
    s = [@"<pre>" stringByAppendingString:s];
    s = [s stringByAppendingString:@"</pre>"];
    return s;
  }
  if ([s isEqualToString:@"html"])
    return [self contentAsStringInContext:_ctx];
  
  return @"<i>This ZideStore document is unsupported in Blogger</i>";
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

- (NSString *)description {
  NSMutableString *ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  [ms appendFormat:@" path=%@", [self storagePath]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SxDocument */
