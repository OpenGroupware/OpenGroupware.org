/*
  Copyright (C) 2003-2004 SKYRIX Software AG

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

#include "SxProjectNotesFolder.h"
#include "common.h"

@implementation SxProjectNotesFolder

static BOOL debugOn = NO;

- (void)dealloc {
  [self->projectEO release];
  [super dealloc];
}

/* project */

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx {
  id tmp;
  
  if ((tmp = [self container]) == nil)
    return nil;
  if (tmp == self) /* loop?! */
    return nil;
  
  return [tmp projectGlobalIDInContext:_ctx];
}

- (SxProjectFolder *)projectFolder {
  return [self container];
}

/* notes */

- (id)_fetchProjectEOInContext:(id)_ctx {
  // TODO: all this should be moved into a command! Its copy/paste from
  //       SkyNoteList
  LSCommandContext *cmdctx;
  id tmp;
  
  if (self->projectEO != nil) 
    return self->projectEO;
  if ((cmdctx = [self commandContextInContext:_ctx]) == nil)
    return nil;
  
  tmp = [cmdctx runCommand:@"project::get-by-globalid",
		  @"gid", [self projectGlobalIDInContext:_ctx],
		nil];
  if ([tmp isKindOfClass:[NSArray class]])
    self->projectEO = [[tmp lastObject] retain];
  else if ([tmp isNotNull])
    self->projectEO = [tmp retain];
  
  return self->projectEO;
}
- (id)_fetchRootDocumentEOInContext:(id)_ctx {
  // TODO: all this should be moved into a command! Its copy/paste from
  //       SkyNoteList
  LSCommandContext *cmdctx;
  id project, root;
  
  if ((cmdctx = [self commandContextInContext:_ctx]) == nil)
    return nil;
  if ((project = [self _fetchProjectEOInContext:_ctx]) == nil)
    return nil;
  
  [cmdctx runCommand:@"project::get-root-document",
	    @"object"     , project,
            @"relationKey", @"rootDocument", nil];
  root = [project valueForKey:@"rootDocument"];
  if ([root isKindOfClass:[NSArray class]])
    root = [root lastObject];
  else if (![root isNotNull])
    root = nil;
  
  return root;
}

- (NSArray *)_fetchNoteEOsInContext:(id)_ctx {
  // TODO: all this should be moved into a command! Its copy/paste from
  //       SkyNoteList
  id rootDoc, tmp;
  
  if ((rootDoc = [self _fetchRootDocumentEOInContext:_ctx]) == nil)
    return nil;
  
  // TODO: do not use faults!
  tmp = [rootDoc valueForKey:@"toNote"];
  if (![tmp isNotNull])
    return nil;
  
  return tmp;
}

- (NSArray *)namesForNoteEOs:(NSArray *)_noteEOs {
  NSMutableArray *ma;
  unsigned i, count;
  
  count = [_noteEOs count];
  ma = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    id       noteEO;
    NSString *noteName, *noteExt;
    
    noteEO   = [_noteEOs objectAtIndex:i];
    noteName = [noteEO valueForKey:@"documentId"];
    noteExt  = [noteEO valueForKey:@"fileType"];
    if (![noteName isNotNull]) continue;
    if (![noteExt  isNotNull]) noteExt = @"txt";
    
    noteName = [[noteName stringValue] stringByAppendingPathExtension:noteExt];
    [ma addObject:noteName];
  }
  return ma;
}

- (NSArray *)fetchNoteNamesInContext:(id)_ctx {
  NSArray  *noteEOs;
  
  [self debugWithFormat:@"fetch note names ..."];
  
  noteEOs = [self _fetchNoteEOsInContext:_ctx];
  [self debugWithFormat:@"  fetched %i notes ...", [noteEOs count]];
  
  return [self namesForNoteEOs:noteEOs];
}

/* relationships */

- (NSArray *)toOneRelationshipKeys {
  return [self fetchNoteNamesInContext:nil];
}
- (NSArray *)toManyRelationshipKeys {
  return nil;
}

- (NSEnumerator *)davChildKeysInContext:(id)_ctx {
  return [[self fetchNoteNamesInContext:_ctx] objectEnumerator];
}

/* operations */

- (id)createNoteWithTitle:(NSString *)_title content:(id)_content
  inContext:(id)_ctx
{
  LSCommandContext    *cmdctx;
  NSMutableDictionary *newNote;
  NSNumber *accountId;
  id project;
  id tmp;
  
  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    return [NSException exceptionWithHTTPStatus:500 /* Internal Error */
			reason:@"got no command context"];
  }
  project = [self _fetchProjectEOInContext:_ctx];
  if (![project isNotNull]) {
    return [NSException exceptionWithHTTPStatus:500 /* internal error */
			reason:@"did not find project EO for new note!"];
  }
  
  accountId = [[cmdctx valueForKey:LSAccountKey] valueForKey:@"companyId"];
  newNote   = [NSMutableDictionary dictionaryWithCapacity:16];
  
  [newNote takeValue:_title     forKey:@"title"];
  [newNote takeValue:accountId  forKey:@"firstOwnerId"];
  [newNote takeValue:accountId  forKey:@"currentOwnerId"];
  [newNote takeValue:_content   forKey:@"fileContent"];
  [newNote takeValue:[NSNumber numberWithBool:NO] forKey:@"isFolder"];
  [newNote takeValue:[NSNumber numberWithInt:[_content length]] 
	   forKey:@"fileSize"];
  
  [newNote takeValue:project forKey:@"project"];
  
  NS_DURING
    tmp = [cmdctx runCommand:@"note::new" arguments:newNote];
  NS_HANDLER
    tmp = localException;
  NS_ENDHANDLER;
  
  if ([cmdctx isTransactionInProgress]) {
    if (![tmp isKindOfClass:[NSException class]]) {
      if (![cmdctx commit]) {
	return [NSException exceptionWithHTTPStatus:500 /* server error */
			    reason:@"could not commit transaction!"];
      }
    }
    else
      [cmdctx rollback];
  }
  
  return tmp;
}

/* name lookup */

- (BOOL)isPrimaryKeyName:(NSString *)_name {
  if (!isdigit([_name characterAtIndex:0]))
    return NO;
  
  if ([_name rangeOfString:@"-"].length > 0) {
    /* MacOSX submits such filenames: 807-101606857-752.txt */
    return NO;
  }
  
  return YES; /* Note: can still be not available */
}

- (Class)recordClassForKey:(NSString *)_key {
  /* triggered by SxFolder lookup */
  return NSClassFromString(@"SxNote");
}

/* permissions */

- (BOOL)isItemCreationAllowed {
  // TODO: check backend permissions (project write access?)
  return YES;
}
- (BOOL)isFolderCreationAllowed {
  /* no subfolders */
  return NO;
}

- (BOOL)isDeletionAllowed {
  // TODO: check delete permission on note
  return NO;
}

/* common DAV attributes */

- (NSString *)davDisplayName {
  /* TODO: use title if available? */
  return [self nameInContainer];
}
- (BOOL)davIsCollection {
  return YES;
}
- (BOOL)davIsFolder {
  /* this can be overridden by compound documents (aka filewrappers) */
  return [self davIsCollection];
}
- (BOOL)davHasSubFolders {
  return NO;
}

/* blogger */

- (NSString *)bloggerPostEntryWithTitle:(NSString *)_title
  description:(NSString *)_content creationDate:(NSCalendarDate *)_date
  inContext:(id)_ctx
{
  // TODO: can we keep the creationDate?
  id eo;
  
  /* we add an HTML marker (because a note has no type) */
  if (![_content hasPrefix:OGo_HTML_MARKER])
    _content = [OGo_HTML_MARKER stringByAppendingString:_content];
  
  eo = [self createNoteWithTitle:_title content:_content inContext:_ctx];
  if (eo == nil || [eo isKindOfClass:[NSException class]])
    return eo;
  
  /* 
     The current convention for the post IDs is Blog/Post, because post edit
     operations only transfer the post ID and _not_ the blog (so we need to
     embed the blog name).
  */
  return [NSString stringWithFormat:@"%@/%@.txt",
		     [self nameInContainer],
		     [eo valueForKey:@"documentId"]];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

- (NSString *)description {
  NSMutableString *ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  [ms appendFormat:@" name='%@'", [self nameInContainer]];
  [ms appendString:@">"];
  return ms;
}

@end /* SxProjectNotesFolder */
