// $Id: SxDocument.m 1 2004-08-20 11:17:52Z znek $

#include "SxDocument.h"
#include "SxProjectFolder.h"
#include "common.h"

// TODO: might add support for versions?! (aka name.txt;1)

@implementation SxDocument

static BOOL debugOn = NO;

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
  return [NSException exceptionWithHTTPStatus:500 /* server error */
		      reason:_error ? _error : @"unknown internal error"];
}

- (id)PUTAction:(id)_ctx {
  LSCommandContext *cmdctx;
  NSException *error;
  NSData   *data;
  unsigned len;
  id       fm;
  NSString *p;
  
  if ([[self nameInContainer] hasPrefix:@"._"]) {
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"rejecting writes to resourcefork file"];
  }
  
  [self debugWithFormat:@"write file content: %@ ...", [self nameInContainer]];
  
  if ((fm = [self fileManagerInContext:_ctx]) == nil)
    return [self internalError:@"could not locate filemanager for project"];
  
  if ([(p = [self storagePath]) length] == 0)
    return [self internalError:@"could not calc project relative path"];
  
  /* check locking status and lock on demand */
  // TODO: check whether its a locking or versioned storage etc
  // TODO: checkout-on-demand, "checkin-after-time?"
  
  /* write the file */
  
  if ((data = [[(WOContext *)_ctx request] content]) == nil) {
    static NSData *emptyData = nil;
    if (emptyData == nil) emptyData = [[NSData alloc] init];
    data = (id)emptyData;
  }
  
  len = [data length];
  
  if (![fm writeContents:data atPath:p]) {
    [self debugWithFormat:@"could not write %i bytes to %@ (fm=%@)", 
	    len, p, fm];
    
    if ([fm respondsToSelector:@selector(lastException)])
      error = [fm lastException];
    if (error)
      return error;
    return [self internalError:@"file writing failed, reason unknown"];
  }
  
  cmdctx = [self commandContextInContext:_ctx];
  if ([cmdctx isTransactionInProgress]) {
    if (![cmdctx commit])
      return [self internalError:@"could not commit transaction!"];
  }
  
  return [NSNumber numberWithBool:YES];
}

- (id)GETAction:(id)_ctx {
  id       fm;
  NSString *p;
  NSData   *content;
  
  if ((fm = [self fileManagerInContext:_ctx]) == nil)
    return [self internalError:@"could not locate filemanager for project"];
  
  if ([(p = [self storagePath]) length] == 0)
    return [self internalError:@"could not calc project relative path"];
  
  if ((content = [fm contentsAtPath:p]) == nil) {
    if ([fm respondsToSelector:@selector(lastException)])
      return [fm lastException];
    
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"could not read content of document"];
  }
  
  // TODO: add MIME typing etc
  return content;
}

- (id)DELETEAction:(WOContext *)_ctx {
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
  return [[self projectFolder] moveObject:self toTarget:_target
			       newName:_name inContext:_ctx];
}

- (NSException *)davCopyToTargetObject:(id)_target newName:(NSString *)_name
  inContext:(id)_ctx
{
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
