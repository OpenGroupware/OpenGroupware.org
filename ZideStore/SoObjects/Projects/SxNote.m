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
// $Id: SxNote.m 1 2004-08-20 11:17:52Z znek $

#include "SxNote.h"
#include "common.h"

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

  if (self->noteEO)
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

/* permissions */

- (BOOL)isDeletionAllowed {
  // TODO: implement!
  return NO;
}

/* actions */

- (id)GETAction:(id)_ctx {
  [self logWithFormat:@"get note ..."];
  return [self noteContent];
}

- (id)PUTAction:(id)_ctx {
  LSCommandContext *cmdctx;
  NSData           *data;
  id               neo;
  
  if ([[self nameInContainer] hasPrefix:@"._"]) {
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"rejecting writes to resourcefork file"];
  }
  
  [self debugWithFormat:@"write file content: %@ ...", [self nameInContainer]];

  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: got no command context ..."];
    return nil;
  }
  
  if ((neo = [self _fetchNoteEOInContext:_ctx]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"did not find EO for note"];
  }
  
  if ((data = [[(WOContext *)_ctx request] content]) == nil) {
    static NSData *emptyData = nil;
    if (emptyData == nil) emptyData = [[NSData alloc] init];
    data = (id)emptyData;
  }
  
  [neo takeValue:[NSNumber numberWithInt:[data length]] forKey:@"fileSize"];
  [neo takeValue:data forKey:@"fileContent"];
  
  [cmdctx runCommand:@"note::set" arguments:neo];
  
  if ([cmdctx isTransactionInProgress]) {
    if (![cmdctx commit]) {
      return [NSException exceptionWithHTTPStatus:500
			  reason:@"could not commit transaction!"];
    }
  }
  
  return [NSNumber numberWithBool:YES];
}

- (id)DELETEAction:(WOContext *)_ctx {
  if (![self isDeletionAllowed]) {
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:@"note deletion is not allowed"];
  }
  
  return [NSException exceptionWithHTTPStatus:501 /* not implemented */
		      reason:@"note deletion is not implemented yet"];
  
  // TODO: insert note delete code here
  
#if 0
  cmdctx = [self commandContextInContext:_ctx];
  if ([cmdctx isTransactionInProgress]) {
    if (![cmdctx commit])
      return [self internalError:@"could not commit transaction!"];
  }
#endif

  return [NSNumber numberWithBool:NO];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

- (NSString *)description {
  NSMutableString *ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  [ms appendFormat:@" name=%@", [self nameInContainer]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SxNote */
