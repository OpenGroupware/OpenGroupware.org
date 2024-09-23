/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxProjectFolder.h"
#include "SxDocumentFolder.h"
#include "SxDocument.h"
#include <OGoProject/OGoFileManagerFactory.h>
#include "common.h"

@interface NSObject(GID)
- (EOGlobalID *)globalID;
@end

@implementation SxProjectFolder

static NSArray *projectFolderNames = nil;
static BOOL    debugOn = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"SxProjectFolderDebugEnabled"];
  
  if (projectFolderNames == nil) {
    // TODO: move to resource plist
    projectFolderNames = 
      [[NSArray alloc] initWithObjects:
                         @"Tasks", @"Notes", @"Contacts", @"Accounts",
                         @"Documents", nil];
  }
}

- (void)dealloc {
  [self->projectGlobalID release];
  [self->fileManager     release];
  [super dealloc];
}

/* project information */

- (NSString *)projectNameKey {
  /* we could remap that in theory */
  return @"number";
}

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx {
  LSCommandContext *cmdctx;
  id tmp;
  
  if (self->projectGlobalID)
    return self->projectGlobalID;
  
  /* convert name into gid */
  
  [self debugWithFormat:@"lookup global-id of project %@", 
          [self nameInContainer]];
  
  cmdctx = [self commandContextInContext:_ctx];
  tmp = [cmdctx runCommand:@"project::get",
		  [self projectNameKey], [self nameInContainer],
		nil];
  if ([tmp count] == 0) /* not found */
    return nil;
  
  if ([tmp count] > 1) {
    [self warnWithFormat:
	    @"multiple projects mapped to filename '%@' (key=%@)",
	    [self nameInContainer], [self projectNameKey]];
  }
  self->projectGlobalID = [[[tmp objectAtIndex:0] globalID] retain];
  
  return self->projectGlobalID;
}
- (EOGlobalID *)projectGlobalID {
  return [self projectGlobalIDInContext:[[WOApplication application] context]];
}

- (id)fileManagerInContext:(id)_ctx {
  LSCommandContext *cmdctx;
  EOGlobalID *gid;

  if (self->fileManager)
    return self->fileManager;
  
  cmdctx = [self commandContextInContext:_ctx];
  if ((gid = [self projectGlobalIDInContext:_ctx]) == nil)
    return nil;
  
  self->fileManager = 
    [[[OGoFileManagerFactory sharedFileManagerFactory]
       fileManagerInContext:cmdctx forProjectGID:gid] retain];
  
  if ([self->fileManager respondsToSelector:@selector(flush)])
    [(LSCommandContext *)self->fileManager flush];
  
  return self->fileManager;
}

- (id)_fetchEOInContext:(id)_ctx {
  LSCommandContext *cmdctx;
  EOGlobalID *gid;
  id eo;
  
  cmdctx = [self commandContextInContext:_ctx];
  if ((gid = [self projectGlobalIDInContext:_ctx]) == nil)
    return nil;
  
  // TODO: command should return one record for a 'gid' query?
  eo = [cmdctx runCommand:@"project::get-by-globalid", @"gid", gid, nil];
  if ([eo isKindOfClass:[NSArray class]]) eo = [eo lastObject];
  return eo;
}

- (NSString *)fetchAbstractInContext:(WOContext *)_ctx {
  // TODO: fetch EO + abstract
  LSCommandContext *cmdctx;
  id eo, tmp;
  
  if (_ctx == nil) _ctx = [[WOApplication application] context];

  /* fetch EO */
  
  if ((eo = [self _fetchEOInContext:_ctx]) == nil) {
    [self logWithFormat:@"Note: did not find EO for fetching comment ..."];
    return nil;
  }
  
  /* fetch comment relation (pretty obfuscated) */
  
  cmdctx = [self commandContextInContext:_ctx];
  [cmdctx runCommand:@"project::get-comment", 
	  @"object", eo, @"relationKey", @"comment", nil];
  tmp = [[eo valueForKey:@"comment"] valueForKey:@"comment"];
  if (tmp != nil)
    [eo takeValue:[[tmp copy] autorelease] forKey:@"comment"];
  
  /* done */
  return tmp;
}

/* child names */

- (NSArray *)toManyRelationshipKeys {
  return projectFolderNames;
}

- (NSEnumerator *)davChildKeysInContext:(id)_ctx {
  [self debugWithFormat:@"davChildKeysInContext:"];
  return [[self toManyRelationshipKeys] objectEnumerator];
}

/* name lookup */

- (id)rootFolder:(NSString *)_name inContext:(id)_ctx {
  id folder;
  
  [self debugWithFormat:@"lookup rootfolder '%@' of %@", _name, 
          [self nameInContainer]];
  
  folder = [[NSClassFromString(@"SxDocumentFolder") alloc] 
             initWithName:_name inContainer:self];
  return [folder autorelease];
}
- (id)notesFolder:(NSString *)_name inContext:(id)_ctx {
  id folder;
  
  [self debugWithFormat:@"lookup notes folder '%@' of %@", _name, 
          [self nameInContainer]];
  
  folder = [[NSClassFromString(@"SxProjectNotesFolder") alloc] 
             initWithName:_name inContainer:self];
  return [folder autorelease];
}

- (id)lookupStoredName:(NSString *)_name inContext:(id)_ctx {
  /* TODO: this should be configurable ... (eg like PersonalFolderInfo) */
  
  if ([_name isEqualToString:@"Documents"])
    return [self rootFolder:_name inContext:_ctx];
  if ([_name isEqualToString:@"Notes"])
    return [self notesFolder:_name inContext:_ctx];
  
  [self debugWithFormat:@"lookup stored '%@'", _name];
  return nil;
}

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_flag {
  id tmp;
  
  if ([_name length] == 0) return nil;
  
  if ([_name isEqualToString:@"getIDsAndVersions"])
    return [self getIDsAndVersionsAction:_ctx];
  
  if ((tmp = [self lookupStoredName:_name inContext:_ctx]))
    return tmp;
  
  return [super lookupName:_name inContext:_ctx acquire:_flag];
}

/* act as a common operation repository ... */

- (BOOL)fileManager:(NSFileManager *)_fm
  shouldProceedAfterError:(NSDictionary *)_error
{
  [self debugWithFormat:@"filemanager: %@ error: %@", _fm, _error];
  return NO;
}
- (void)fileManager:(NSFileManager *)_fm willProcessPath:(NSString *)_path {
  [self debugWithFormat:@"filemanager: %@ process: %@", _fm, _path];
}

- (NSException *)performCopySelector:(SEL)_sel
  source:(id)_source target:(id)_target
  newName:(NSString *)_name inContext:(id)_ctx
{
  /*
    Three cases:
    a) target is a directory
    b) target is a directory and _name is a new filename
    c) target is an existing file
    ?
  */
  LSCommandContext *cmdctx;
  NSString *tp;
  BOOL (*copyMethod)(id, SEL, NSString *, NSString *, id);
  id fm;
  
  if (_target == nil)
    return [_source internalError:@"missing target object?!"];
  
  [_source debugWithFormat:@"shall move to target %@, name %@", 
	   _target, _name];
  
  /*
    Ensure that the target is in the same project.
    TODO: allow cross-project moves!
    TODO: should probably use double-dispatch
    TODO: consider "overwrite" and lock headers etc
  */
  if (![_target respondsToSelector:@selector(projectGlobalIDInContext:)]) {
    [_source logWithFormat:
	    @"tried to move object into an unsupported target folder"];
    return [NSException exceptionWithHTTPStatus:403 /* Forbidden */
			reason:@"target object is not in a project!"];
  }

  if (![[_source projectGlobalIDInContext:_ctx] 
	 isEqual:[_target projectGlobalIDInContext:_ctx]]) {
    [_source logWithFormat:
	    @"tried to move object into a different project"];
    return [NSException exceptionWithHTTPStatus:403 /* Forbidden */
			reason:@"target object is in a different project!"];
  }
  
  if ((fm = [_source fileManager]) == nil)
    return [_source internalError:@"could not locate filemanager for project"];
  copyMethod = (void *)[fm methodForSelector:_sel];
  
  tp = [_target storagePath];
  if ([_name length] > 0) {
    if (![tp hasSuffix:@"/"]) tp = [tp stringByAppendingString:@"/"];
    tp = [tp stringByAppendingString:_name];
  }
  
  [_source debugWithFormat:@"move %@ to %@", [_source storagePath], tp];

  if ([_name length] > 0) { /* a new file */
    /* check whether the target folder is writable */
    if (![fm isWritableFileAtPath:[_target storagePath]]) {
      return [NSException exceptionWithHTTPStatus:403 /* Forbidden */
			  reason:@"no write access to target folder!"];
    }
  }
  else { /* an existing file */
    /* check whether the target folder is writable */
    if (![fm isWritableFileAtPath:[_target storagePath]]) {
      return [NSException exceptionWithHTTPStatus:403 /* Forbidden */
			  reason:@"no write access to target folder!"];
    }
  }
  
  /* 
     Note: using 'self' as the handler implies that you need to implement
           certain methods!
  */
  if (!copyMethod(fm, _sel, [_source storagePath], tp, nil /* handler */)) {
    if ([fm respondsToSelector:@selector(lastException)])
      return [fm lastException];
    return [_source internalError:@"failed to move/copy path"];
  }
  
  cmdctx = [_source commandContextInContext:_ctx];
  if ([cmdctx isTransactionInProgress]) {
    if (![cmdctx commit])
      return [_source internalError:@"could not commit transaction!"];
  }
  
  [_source debugWithFormat:@"successfully moved/copied file %@", _name];
  return nil; /* nil = no error */
}

- (NSException *)moveObject:(id)_source toTarget:(id)_target
  newName:(NSString *)_name inContext:(id)_ctx
{
  return [self performCopySelector:@selector(movePath:toPath:handler:)
	       source:_source target:_target
	       newName:_name inContext:_ctx];
}

- (NSException *)copyObject:(id)_source toTarget:(id)_target
  newName:(NSString *)_name inContext:(id)_ctx
{
  return [self performCopySelector:@selector(copyPath:toPath:handler:)
	       source:_source target:_target
	       newName:_name inContext:_ctx];
}

/* RSS support */

- (NSString *)rssDescriptionInContext:(WOContext *)_ctx {
  return [[self fetchAbstractInContext:_ctx] stringValue];
}

/* description */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

- (NSString *)description {
  NSMutableString *ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<%p[%@]:", self, NSStringFromClass([self class])];
  
  if (self->projectGlobalID)
    [ms appendFormat:@" gid=%@", self->projectGlobalID];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SxProjectFolder */
