/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include "SOGoMailFolder.h"
#include "SOGoMailObject.h"
#include "SOGoMailAccount.h"
#include "SOGoMailManager.h"
#include "common.h"

@implementation SOGoMailFolder

- (void)dealloc {
  [self->filenames  release];
  [self->folderType release];
  [super dealloc];
}

/* IMAP4 */

- (NSString *)relativeImap4Name {
  return [self nameInContainer];
}

/* listing the available folders */

- (NSArray *)toManyRelationshipKeys {
  return [[self mailManager] subfoldersForURL:[self imap4URL] 
			     password:[self imap4Password]];
}
- (NSArray *)toOneRelationshipKeys {
  NSArray  *uids;
  unsigned count;
  
  if (self->filenames != nil)
    return [self->filenames isNotNull] ? self->filenames : nil;
  
  uids = [self fetchUIDsMatchingQualifier:nil sortOrdering:@"DATE"];
  if ([uids isKindOfClass:[NSException class]])
    return nil;
  
  if ((count = [uids count]) == 0) {
    self->filenames = [[NSArray alloc] init];
  }
  else {
    NSMutableArray *keys;
    unsigned i;
    
    keys = [[NSMutableArray alloc] initWithCapacity:count];
    for (i = 0; i < count; i++) {
      NSString *k;
      
      k = [[uids objectAtIndex:i] stringValue];
      k = [k stringByAppendingString:@".mail"];
      [keys addObject:k];
    }
    self->filenames = [keys copy];
    [keys release];
  }
  return self->filenames;
}

/* messages */

- (NSArray *)fetchUIDsMatchingQualifier:(id)_q sortOrdering:(id)_so {
  /* seems to return an NSArray of NSNumber's */
  return [[self mailManager] fetchUIDsInURL:[self imap4URL]
			     qualifier:_q sortOrdering:_so
			     password:[self imap4Password]];
}

- (NSArray *)fetchUIDs:(NSArray *)_uids parts:(NSArray *)_parts {
  return [[self mailManager] fetchUIDs:_uids inURL:[self imap4URL]
			     parts:_parts
			     password:[self imap4Password]];
}

- (NSException *)postData:(NSData *)_data flags:(id)_flags {
  return [[self mailManager] postData:_data flags:_flags
			     toFolderURL:[self imap4URL]
			     password:[self imap4Password]];
}

- (NSException *)expunge {
  return [[self mailManager] expungeAtURL:[self imap4URL]
			     password:[self imap4Password]];
}

/* name lookup */

- (BOOL)isMessageKey:(NSString *)_key inContext:(id)_ctx {
  /*
    Every key starting with a digit is consider an IMAP4 message key. This is
    not entirely correct since folders could also start with a number.
    
    If we want to support folders beginning with numbers, we would need to
    scan the folder list for the _key, which would make everything quite a bit
    slower.
    TODO: support this mode using a default.
  */
  if ([_key length] == 0)
    return NO;
  
  if (isdigit([_key characterAtIndex:0]))
    return YES;
  
  return NO;
}

- (id)lookupImap4Folder:(NSString *)_key inContext:(id)_ctx {
  // TODO: we might want to check for existence prior controller creation
  return [[[SOGoMailFolder alloc] initWithName:_key 
				  inContainer:self] autorelease];
}
- (id)lookupImap4Message:(NSString *)_key inContext:(id)_ctx {
  // TODO: we might want to check for existence prior controller creation
  return [[[SOGoMailObject alloc] initWithName:_key 
				  inContainer:self] autorelease];
}

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  id obj;
  
  /* first check attributes directly bound to the application */
  if ((obj = [super lookupName:_key inContext:_ctx acquire:NO]) != nil)
    return obj;
  
  obj = [self isMessageKey:_key inContext:_ctx]
    ? [self lookupImap4Message:_key inContext:_ctx]
    : [self lookupImap4Folder:_key  inContext:_ctx];
  if (obj != nil)
    return obj;
  
  /* return 404 to stop acquisition */
  return [NSException exceptionWithHTTPStatus:404 /* Not Found */];
}

/* WebDAV */

- (BOOL)davIsCollection {
  return YES;
}

- (NSException *)davCreateCollection:(NSString *)_name inContext:(id)_ctx {
  return [[self mailManager] createMailbox:_name atURL:[self imap4URL]
			     password:[self imap4Password]];
}

/* folder type */

- (NSString *)outlookFolderClass {
  // TODO: detect Trash/Sent/Drafts folders
  SOGoMailAccount *account;
  NSString *n;

  if (self->folderType != nil)
    return self->folderType;
  
  account = [self mailAccountFolder];
  n       = [self nameInContainer];
  
  if ([n isEqualToString:[account trashFolderNameInContext:nil]])
    self->folderType = @"IPF.Trash";
  else if ([n isEqualToString:[account inboxFolderNameInContext:nil]])
    self->folderType = @"IPF.Inbox";
  else if ([n isEqualToString:[account sentFolderNameInContext:nil]])
    self->folderType = @"IPF.Sent";
  else
    self->folderType = @"IPF.Folder";
  
  return self->folderType;
}

/* operations */

- (NSException *)delete {
  /* Note: overrides SOGoObject -delete */
  return [[self mailManager] deleteMailboxAtURL:[self imap4URL]
			     password:[self imap4Password]];
}

@end /* SOGoMailFolder */
