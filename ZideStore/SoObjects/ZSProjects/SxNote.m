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

#include "SxNote.h"
#include "SxProjectFolder.h"
#include "common.h"

@interface SxProjectFolder(FetchEO)
- (id)_fetchEOInContext:(id)_ctx;
@end

@implementation SxNote

static BOOL debugOn = NO;

- (id)initWithName:(NSString *)_name inContainer:(id)_container {
  return [self initWithName:_name inFolder:_container];
}

- (void)dealloc {
  [self->noteEO release];
  [super dealloc];
}

/* project */

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx {
  // TODO: need to tweak that if used as an appointment note
  return [[self container] projectGlobalIDInContext:_ctx];
}
- (SxProjectFolder *)projectFolder {
  return [[self container] projectFolder];
}

/* notes folder */

- (id)notesFolder {
  /* can be either an appointment notes folder or a project notes folder */
  return [self container];
}

/* note object */

- (NSNumber *)primaryKey {
  return [NSNumber numberWithInt:[[self nameInContainer] intValue]];
}

- (id)_fetchNoteEOInContext:(id)_ctx {
  LSCommandContext *cmdctx;
  NSNumber *pkey;
  id       note;

  if (self->noteEO != nil)
    return self->noteEO;
  
  if (_ctx == nil) _ctx = [[WOApplication application] context];
  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: got no command context ..."];
    return nil;
  }
  
  if ((pkey = [self primaryKey]) == nil) {
    [self logWithFormat:@"ERROR: got no primary key for note ..."];
    return nil;
  }
  
  note = [cmdctx runCommand:@"note::get", @"documentId", pkey, nil];
  [self debugWithFormat:@"fetched note: %@", note];
  [cmdctx runCommand:@"note::get-attachment-name", @"notes", note, nil];
  
  if ([note isKindOfClass:[NSArray class]])
    note = [note lastObject];
  else if (![note isNotNull])
    note = nil;
  
  self->noteEO = [note retain];
  return self->noteEO;
}

- (NSString *)noteContent {
  NSString *fileName;
  id neo;
  
  if ((neo = [self _fetchNoteEOInContext:nil]) == nil) {
    [self logWithFormat:@"ERROR: could not fetch note EO ..."];
    return nil;
  }
  
  if ((fileName = [neo valueForKey:@"attachmentName"]) == nil) {
    [self logWithFormat:@"ERROR: got no attachment path for note: %@", neo];
    return nil;
  }
  
  [self debugWithFormat:@"load note from: '%@'", fileName];
  return [NSString stringWithContentsOfFile:fileName];
}
- (NSString *)contentAsString {
  return [self noteContent];
}

/* permissions */

- (BOOL)isDeletionAllowed {
  /* only owner may delete notes */
  LSCommandContext *cmdctx;
  WOContext *ctx;
  NSNumber  *accountId;
  id        neo;

  ctx = [[WOApplication application] context];
  
  if ((cmdctx = [self commandContextInContext:ctx]) == nil) {
    [self logWithFormat:@"ERROR: missing command context!"];
    return NO;
  }
  if ((neo = [self _fetchNoteEOInContext:ctx]) == nil) {
    [self logWithFormat:@"ERROR: missing EO!"];
    return NO;
  }
  
  accountId = [[cmdctx valueForKey:LSAccountKey] valueForKey:@"companyId"];
  if ([accountId isEqual:[neo valueForKey:@"currentOwnerId"]])
    return YES;
  if ([accountId isEqual:[neo valueForKey:@"firstOwnerId"]])
    return YES;
  
  [self logWithFormat:
	  @"Note: delete denied, account id does not match: %@ vs %@",
	  accountId, [neo valueForKey:@"currentOwnerId"]];
  return NO;
}

/* operations */

- (id)createNoteWithTitle:(NSString *)_title content:(id)_content
  inContext:(id)_ctx
{
  return [[self container] createNoteWithTitle:_title content:_ctx 
			   inContext:_ctx];
}

/* actions */

- (id)GETAction:(id)_ctx {
  NSString *content;
  
  content = [self contentAsString];
  if ([content isNotNull]) {
    WOResponse *r;
    
    r = [(WOContext *)_ctx response];
    if ([content hasPrefix:OGo_HTML_MARKER]) {
      [r setHeader:@"text/html" forKey:@"content-type"];
      content = [content substringFromIndex:[OGo_HTML_MARKER length]];
    }
    else
      [r setHeader:@"text/plain" forKey:@"content-type"];
    [r appendContentString:content];
    return r;
  }
  if ([content isKindOfClass:[NSException class]])
    return content;
  
  return [NSException exceptionWithHTTPStatus:404 /* Not Found */
		      reason:@"did not find note!"];
}

- (id)asPreHTMLAction:(id)_ctx {
  /* for use in RSS, wrap note content in <pre> tags */
  WOResponse *r;
  
  r = [(WOContext *)_ctx response];
  [r setHeader:@"text/html" forKey:@"content-type"];
  [r appendContentString:@"<pre>"];
  [r appendContentHTMLString:[self contentAsString]];
  [r appendContentString:@"</pre>"];
  return r;
}

- (id)asBrHTMLAction:(id)_ctx {
  /* for use in RSS, replace newlines with <br /> tags */
  WOResponse   *r;
  NSString     *s;
  NSEnumerator *e;
  
  if ((s = [self contentAsString]) == nil)
    return nil;
  
  r = [(WOContext *)_ctx response];
  [r setHeader:@"text/html" forKey:@"content-type"];
  e = [[s componentsSeparatedByString:@"\n"] objectEnumerator];
  while ((s = [e nextObject])) {
    [r appendContentHTMLString:s];
    [r appendContentString:@"<br />"];
  }
  return r;
}

- (NSString *)defaultNoteTitle {
  NSCalendarDate *now;
  
  now = [[[NSCalendarDate alloc] init] autorelease];
  [now setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
  return [@"x" stringByAppendingString:
	     [now descriptionWithCalendarFormat:@"%Y%m%dZ"]];
}

- (id)PUTAction:(id)_ctx {
  LSCommandContext *cmdctx;
  NSException      *error;
  NSData           *data;
  id               neo;
  
  if ([[self nameInContainer] hasPrefix:@"._"]) {
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"rejecting writes to resourcefork file"];
  }
  
  [self debugWithFormat:@"write file content: %@ ...", [self nameInContainer]];
  
  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: got no command context ..."];
    return [NSException exceptionWithHTTPStatus:500 /* Internal Error */
			reason:@"got no command context"];
  }

  if ((data = [[(WOContext *)_ctx request] content]) == nil) {
    static NSData *emptyData = nil;
    if (emptyData == nil) emptyData = [[NSData alloc] init];
    data = (id)emptyData;
  }
  
  error = nil;
  if ((neo = [self _fetchNoteEOInContext:_ctx]) != nil) {
    /* modify existing note */
    [neo takeValue:[NSNumber numberWithInt:[data length]] forKey:@"fileSize"];
    [neo takeValue:data forKey:@"fileContent"];
  
    NS_DURING {
      [cmdctx runCommand:@"note::set", @"object", neo, @"fileContent", data,
	      nil];
    }
    NS_HANDLER
      error = [localException retain];
    NS_ENDHANDLER;
  }
  else {
    /* create new note */
    // TODO: we might want to set a location header for the new object
    id tmp;
    
    tmp = [self createNoteWithTitle:[self defaultNoteTitle]
		content:data inContext:_ctx];
    if ([tmp isKindOfClass:[NSException class]])
      error = [tmp retain];
  }
  
  if ([cmdctx isTransactionInProgress]) {
    if (error == nil) {
      if (![cmdctx commit]) {
	return [NSException exceptionWithHTTPStatus:500
			    reason:@"could not commit transaction!"];
      }
    }
    else
      [cmdctx rollback];
  }
  
  if (error != nil) {
    [self debugWithFormat:@"failed: %@", error];
    return [error autorelease];
  }
  
  return [NSNumber numberWithBool:YES];
}

- (id)DELETEAction:(WOContext *)_ctx {
  LSCommandContext *cmdctx;
  id neo;
  
  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: got no command context ..."];
    return [NSException exceptionWithHTTPStatus:500 /* Internal Error */
			reason:@"got no command context"];
  }
  if ((neo = [self _fetchNoteEOInContext:_ctx]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"did not find note!"];
  }
  
  if (![self isDeletionAllowed]) {
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:@"note deletion is not allowed"];
  }
  
  [cmdctx runCommand:@"note::delete",
	    @"object",       neo,
	    @"reallyDelete", [NSNumber numberWithBool:YES],
	  nil];
  if (![cmdctx commit]) {
    return [NSException exceptionWithHTTPStatus:500 /* internal error */
			reason:@"could not commit transaction!"];
  }
  return [NSNumber numberWithBool:YES];
}

/* WebDAV */

- (NSString *)davDisplayName {
  // TODO: use title if available?
  id       lNoteEO;
  NSString *title;
  
  lNoteEO = [self _fetchNoteEOInContext:nil];
  title   = [lNoteEO valueForKey:@"title"];
  
  if ([title isNotNull])
    return title;
  
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
  // TODO: a bit expensive, maybe we can do that faster
  NSString *s;
  
  s = [self contentAsString];
  return [s isNotNull] ? [NSNumber numberWithInt:[s length]] : nil;
}

- (NSDate *)davLastModified {
  id note;

  if ((note = [self _fetchNoteEOInContext:nil]) == nil)
    return note;
  
  // TODO: hm, where is the _modification_ date stored?
  return [note valueForKey:@"creationDate"];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

- (NSString *)loggingPrefix {
  return [NSString stringWithFormat:@"|%@:%@|",
                     NSStringFromClass([self class]), 
                     [self nameInContainer]];
}

/* description */

- (NSString *)description {
  NSMutableString *ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  [ms appendFormat:@" name=%@", [self nameInContainer]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SxNote */
