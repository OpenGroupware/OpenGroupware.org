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

#include <SOGoUI/UIxComponent.h>

/*
  UIxMailListView
  
  This component represent a list of mails and is attached to an SOGoMailFolder
  object.
*/

@interface UIxMailListView : UIxComponent
{
  NSArray  *sortedUIDs; /* we always need to retrieve all anyway! */
  NSArray  *messages;
  unsigned firstMessageNumber;
  id       message;
}

- (NSString *)defaultSortKey;
- (NSString *)imap4SortKey;
- (NSString *)imap4SortOrdering;

- (BOOL)isSortedDescending;

@end

#include "common.h"
#include <SOGo/SoObjects/Mailer/SOGoMailFolder.h>
#include <SOGo/SoObjects/Mailer/SOGoMailObject.h>

@implementation UIxMailListView

static int attachmentFlagSize = 8096;

- (void)dealloc {
  [self->sortedUIDs release];
  [self->messages   release];
  [self->message    release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->sortedUIDs release]; self->sortedUIDs = nil;
  [self->messages   release]; self->messages = nil;
  [self->message    release]; self->message  = nil;
  [super sleep];
}

/* accessors */

- (void)setMessage:(id)_msg {
  ASSIGN(self->message, _msg);
}
- (id)message {
  return self->message;
}

- (BOOL)showToAddress {
  NSString *ftype;
  
  ftype = [[self clientObject] valueForKey:@"outlookFolderClass"];
  return [ftype isEqual:@"IPF.Sent"];
}

/* title */

- (NSString *)objectTitle {
  return [[self clientObject] nameInContainer];
}
- (NSString *)panelTitle {
  NSString *s;
  
  s = [self labelForKey:@"View Mail Folder"];
  s = [s stringByAppendingString:@": "];
  s = [s stringByAppendingString:[self objectTitle]];
  return s;
}

/* derived accessors */

- (BOOL)isMessageDeleted {
  NSArray *flags;
  
  flags = [[self message] valueForKey:@"flags"];
  return [flags containsObject:@"deleted"];
}

- (BOOL)isMessageRead {
  NSArray *flags;
  
  flags = [[self message] valueForKey:@"flags"];
  return [flags containsObject:@"seen"];
}
- (NSString *)messageUidString {
  return [[[self message] valueForKey:@"uid"] stringValue];
}

- (NSString *)messageSubjectStyleClass {
  return [self isMessageRead]
    ? @"mailer_readmailsubject"
    : @"mailer_unreadmailsubject";
}
- (NSString *)messageCellStyleClass {
  return [self isMessageDeleted]
    ? @"mailer_listcell_deleted"
    : @"mailer_listcell_regular";
}

- (BOOL)hasMessageAttachment {
  /* we detect attachments by size ... */
  unsigned size;
  
  size = [[[self message] valueForKey:@"size"] intValue];
  return size > attachmentFlagSize;
}

/* fetching messages */

- (NSArray *)fetchKeys {
  /* Note: see SOGoMailManager.m for allowed IMAP4 keys */
  static NSArray *keys = nil;
  if (keys == nil) {
    keys = [[NSArray alloc] initWithObjects:
			      @"FLAGS", @"ENVELOPE", @"RFC822.SIZE", nil];
  }
  return keys;
}

- (id)qualifier {
  return nil;
}

- (NSString *)defaultSortKey {
  return @"DATE";
}
- (NSString *)imap4SortKey {
  NSString *sort;
  
  sort = [[[self context] request] formValueForKey:@"sort"];
  
  if ([sort length] == 0)
    sort = [self defaultSortKey];
  return [sort uppercaseString];
}

- (BOOL)isSortedDescending {
  NSString *desc;
  
  desc = [[[self context] request] formValueForKey:@"desc"];
  if(!desc)
    return NO;
  return [desc boolValue] ? YES : NO;
}

- (NSString *)imap4SortOrdering {
  NSString *sort;
  
  sort = [self imap4SortKey];
  if(![self isSortedDescending])
    return sort;
  return [@"REVERSE " stringByAppendingString:sort];
}

- (NSRange)fetchRange {
  if (self->firstMessageNumber == 0)
    return NSMakeRange(0, 50);
  return NSMakeRange(self->firstMessageNumber - 1, 50);
}

- (NSArray *)sortedUIDs {
  if (self->sortedUIDs != nil)
    return self->sortedUIDs;
  
  self->sortedUIDs 
    = [[[self clientObject] fetchUIDsMatchingQualifier:[self qualifier]
			    sortOrdering:[self imap4SortOrdering]] retain];
  return self->sortedUIDs;
}
- (unsigned int)totalMessageCount {
  return [self->sortedUIDs count];
}
- (BOOL)showsAllMessages {
  return ([[self sortedUIDs] count] <= [self fetchRange].length) ? YES : NO;
}

- (NSRange)fetchBlock {
  NSRange  r;
  unsigned len;
  NSArray  *uids;
  
  r    = [self fetchRange];
  uids = [self sortedUIDs];
  
  /* only need to restrict if we have a lot */
  if ((len = [uids count]) <= r.length) {
    r.location = 0;
    r.length   = len;
    return r;
  }
  
  if (len < r.location) {
    // TODO: CHECK CONDITION (< vs <=)
    /* out of range, recover at first block */
    r.location = 0;
    return r;
  }
  
  if (r.location + r.length > len)
    r.length = len - r.location;
  return r;
}
- (unsigned int)firstMessageNumber {
  return [self fetchBlock].location + 1;
}
- (unsigned int)lastMessageNumber {
  NSRange r;
  
  r = [self fetchBlock];
  return r.location + r.length;
}
- (BOOL)hasPrevious {
  return [self fetchBlock].location == 0 ? NO : YES;
}
- (BOOL)hasNext {
  NSRange r = [self fetchBlock];
  return r.location + r.length >= [[self sortedUIDs] count] ? NO : YES;
}

- (unsigned int)nextFirstMessageNumber {
  return [self firstMessageNumber] + [self fetchRange].length;
}
- (unsigned int)prevFirstMessageNumber {
  NSRange  r;
  unsigned idx;
  
  idx = [self firstMessageNumber];
  r   = [self fetchRange];
  if (idx > r.length)
    return (idx - r.length);
  return 1;
}

- (NSArray *)messages {
  NSArray  *uids;
  NSArray  *msgs;
  NSRange  r;
  unsigned len;
  
  if (self->messages != nil)
    return self->messages;
  
  r    = [self fetchBlock];
  uids = [self sortedUIDs];
  if ((len = [uids count]) > r.length)
    /* only need to restrict if we have a lot */
    uids = [uids subarrayWithRange:r];
  
  msgs = [[self clientObject] fetchUIDs:uids parts:[self fetchKeys]];
  self->messages = [[msgs valueForKey:@"fetch"] retain];
  return self->messages;
}

/* URL processing */

- (NSString *)messageViewTarget {
  return [@"SOGo_msg_" stringByAppendingString:[self messageUidString]];
}
- (NSString *)messageViewURL {
  // TODO: noframe only when view-target is empty
  // TODO: markread only if the message is unread
  NSString *s;
  
  s = [[self messageUidString] stringByAppendingString:@"/view?noframe=1"];
  if (![self isMessageRead]) s = [s stringByAppendingString:@"&markread=1"];
  return s;
}
- (NSString *)markReadURL {
  return [@"markMessageRead?uid=" stringByAppendingString:
	     [self messageUidString]];
}
- (NSString *)markUnreadURL {
  return [@"markMessageUnread?uid=" stringByAppendingString:
	     [self messageUidString]];
}

/* JavaScript */

- (NSString *)msgRowID {
  return [@"row_" stringByAppendingString:[self messageUidString]];
}
- (NSString *)msgDivID {
  return [@"div_" stringByAppendingString:[self messageUidString]];
}

- (NSString *)msgIconReadDivID {
  return [@"readdiv_" stringByAppendingString:[self messageUidString]];
}
- (NSString *)msgIconUnreadDivID {
  return [@"unreaddiv_" stringByAppendingString:[self messageUidString]];
}
- (NSString *)msgIconReadVisibility {
  return [self isMessageRead] ? nil : @"display: none;";
}
- (NSString *)msgIconUnreadVisibility {
  return [self isMessageRead] ? @"display: none;" : nil;
}

- (NSString *)clickedMsgJS {
  /* return 'false' aborts processing */
  return [NSString stringWithFormat:@"clickedUid(this, '%@'); return false", 
		     [self messageUidString]];
}
- (NSString *)dblClickedMsgJS {
  return [NSString stringWithFormat:@"doubleClickedUid(this, '%@')", 
		     [self messageUidString]];
}
- (NSString *)highlightRowJS {
  return [NSString stringWithFormat:@"highlightUid(this, '%@')", 
		     [self messageUidString]];
}
- (NSString *)lowlightRowJS {
  return [NSString stringWithFormat:@"lowlightUid(this, '%@')", 
		     [self messageUidString]];
}

- (NSString *)jsCode {
  static NSString *script = \
  @"var rowSelectionCount = 0;\n"
  @"\n"
  @"validateControls();\n"
  @"\n"
  @"function showElement(e, shouldShow) {\n"
  @"	e.style.display = shouldShow ? \"\" : \"none\";\n"
  @"}\n"
  @"\n"
  @"function enableElement(e, shouldEnable) {\n"
  @"  if(!e)\n"
  @"    return;\n"
  @"  if(shouldEnable) {\n"
  @"    if(e.hasAttribute(\"disabled\"))\n"
  @"      e.removeAttribute(\"disabled\");\n"
  @"  }\n"
  @"  else {\n"
  @"    e.setAttribute(\"disabled\", \"1\");\n"
  @"  }\n"
  @"}\n"
  @"\n"
  @"function toggleRowSelectionStatus(sender) {\n"
  @"  rowID = sender.value;\n"
  @"  tr = document.getElementById(rowID);\n"
  @"  if(sender.checked) {\n"
  @"    tr.className = \"tableview_selected\";\n"
  @"    rowSelectionCount += 1;\n"
  @"  }\n"
  @"  else {\n"
  @"    tr.className = \"tableview\";\n"
  @"    rowSelectionCount -= 1;\n"
  @"  }\n"
  @"  this.validateControls();\n"
  @"}\n"
  @"\n"
  @"function validateControls() {\n"
  @"  var e = document.getElementById(\"moveto\");\n"
  @"  this.enableElement(e, rowSelectionCount > 0);\n"
  @"}\n"
  @"\n"
  @"function moveTo(uri) {\n"
  @"  alert(\"MoveTo: \" + uri);\n"
  @"}\n"
  @"";
  return script;
}

/* active message */

- (SOGoMailObject *)lookupActiveMessage {
  NSString *uid;
  
  if ((uid = [[[self context] request] formValueForKey:@"uid"]) == nil)
    return nil;

  return [[self clientObject] lookupName:uid inContext:[self context]
			      acquire:NO];
}

/* actions */

- (id)defaultAction {
#if 0
  [self logWithFormat:@"default action ..."];
#endif
  self->firstMessageNumber = 
    [[[[self context] request] formValueForKey:@"idx"] intValue];
  return self;
}

- (id)markMessageUnreadAction {
  NSException *error;
  
  if ((error = [[self lookupActiveMessage] removeFlags:@"seen"]) != nil)
    // TODO: improve error handling
    return error;
  
  return [self redirectToLocation:@"view"];
}
- (id)markMessageReadAction {
  NSException *error;
  
  if ((error = [[self lookupActiveMessage] addFlags:@"seen"]) != nil)
    // TODO: improve error handling
    return error;
  
  return [self redirectToLocation:@"view"];
}

- (id)getMailAction {
  // TODO: we might want to flush the caches?
  id client;
  
  if ((client = [self clientObject]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"did not find mail folder"];
  }
  
  if (![client respondsToSelector:@selector(flushMailCaches)]) {
    return [NSException exceptionWithHTTPStatus:500 /* Server Error */
			reason:
			  @"invalid client object (does not support flush)"];
  }
  
  [client flushMailCaches];
  return [self redirectToLocation:@"view"];
}

- (id)expungeAction {
  // TODO: we might want to flush the caches?
  NSException *error;
  id client;
  
  if ((client = [self clientObject]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"did not find mail folder"];
  }
  
  if ((error = [[self clientObject] expunge]) != nil)
    return error;
  
  if ([client respondsToSelector:@selector(flushMailCaches)])
    [client flushMailCaches];
  return [self redirectToLocation:@"view"];
}

@end /* UIxMailListView */
