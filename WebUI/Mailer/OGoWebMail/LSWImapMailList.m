/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#include "LSWImapMailList.h"
#include "LSWImapMailMove.h"
#include "NSString+MailEditor.h"
#include "common.h"

@interface LSWImapMailMove(Private)
- (void)setCopyMode:(BOOL)_cp;
@end

@interface LSWImapMailList(Private)
- (void)setSelectedHeader:(NSDictionary *)_header;
- (void)setMails:(NSArray *)_mails;
- (void)setIndex:(int)_index;
- (int)index;
- (NSArray *)filteredMails;
- (NSArray *)markedMails;
- (NSString *)uidForMail:(NGImap4Message *)_msg;
- (NSDictionary *)_getSelectedHeader;
- (BOOL)_isEmptyString:(NSString *)_str;
- (void)sortMessages;
- (void)setEvenRowColor:(NSString *)_color;
- (void)setOddRowColor:(NSString *)_color;
@end

@interface NSString(LSWImapMails)
- (NSString *)shortened:(unsigned int)_length;
@end

@implementation LSWImapMailList

static Class DateClass   = Nil;
static Class StringClass = Nil;

+ (int)version {
  return [super version] + 1 /* v2 */;
}

+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if (StringClass == Nil) StringClass = [NSString class];
  if (DateClass   == Nil) DateClass   = [NSDate   class];
}

- (id)init {
  if ((self = [super init])) {
    self->identifier       = [[NSMutableArray alloc] init];
    self->selectedMessages = [[NSMutableArray alloc] init];
    self->selectAllCheckboxesScript =
      @"function allselect() { \n"
      @"  condition = document.forms[0].elements[\"markAllCheckbox\"].checked\n"
      @"  for (i = 0; i < %d; i++) { \n"
      @"    idx = \"a\" + i\n"
      @"    document.forms[0].elements[idx].checked = condition;\n"
      @"  }\n"
      @"}\n";
  }
  return self;
}

- (void)dealloc {
  [self->folder           release];
  [self->messages         release];
  [self->message          release];
  [self->mailListHeaders  release];
  [self->mailListHeader   release];
  [self->mailListEntry    release];
  [self->evenRowColor     release];
  [self->oddRowColor      release];
  [self->selectedHeader   release];
  [self->sorter           release];
  [self->identifier       release];
  [self->selectedMessages release];
  [super dealloc];
}

/* actions */

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [self _ensureSyncAwake];
  [self->selectedMessages removeAllObjects];
  [self->selectedMessages addObjectsFromArray:[self markedMails]];
  return [super invokeActionForRequest:_req inContext:_ctx];
}

/* notification */

- (void)syncAwake {
  id cfg;

  [self->identifier removeAllObjects];

  cfg = [self config];

  [self setEvenRowColor:
          [cfg valueForKey:@"colors_evenRow"]];
  [self setOddRowColor:
          [cfg valueForKey:@"colors_oddRow"]];
  //  [self sortMessages];
  [super syncAwake];
}

- (void)syncSleep {
  [self->evenRowColor release]; self->evenRowColor = nil;
  [self->oddRowColor  release]; self->oddRowColor = nil;
  [super syncSleep];
}

/* response */

- (void)appendToResponse:(WOResponse *)_res inContext:(WOContext *)_context {
  [self sortMessages];  
  [super appendToResponse:_res inContext:_context];
  self->index = 0;
}

/* sorting */

- (void)setSorter:(id)_sorter {
  ASSIGN(self->sorter, _sorter);
}
- (id)sorter {
  return self->sorter;
}

- (void)setMessages:(NSArray *)_mails {
  ASSIGN(self->messages, _mails);
}
- (NSArray *)messages {
  return self->messages;
}

- (void)setMessage:(id)_mail { 
  ASSIGN(self->message, _mail);
}
- (id)message {
  return self->message;
}

- (void)setFolder:(id)_f {
  ASSIGN(self->folder, _f);
}
- (id)folder {
  return self->folder;
}

// -- mailListHeaders
- (void)setMailListHeaders:(NSArray *)_mailListHeaders {
  ASSIGN(self->mailListHeaders, _mailListHeaders);
}
- (NSArray*)mailListHeaders {
  return self->mailListHeaders;
}

- (void)setMailListHeader:(NSDictionary *)_mailListHeader {
  ASSIGN(self->mailListHeader, _mailListHeader);
}
- (NSDictionary *)mailListHeader {
  return self->mailListHeader;
}

- (void)setMailListEntry:(NSDictionary *)_mailListEntry {
  ASSIGN(self->mailListEntry, _mailListEntry);
}
- (NSDictionary *)mailListEntry {
  return self->mailListEntry;
}

- (void)setIsDescending:(BOOL)_flag {
  self->isDescending = _flag;
}
- (BOOL)isDescending {
  return self->isDescending;
}

- (void)setSelectedHeader:(NSDictionary *)_selectedHeader {
  ASSIGN(self->selectedHeader, _selectedHeader);
}
- (NSDictionary *)selectedHeader {
  return self->selectedHeader;
}

// -----------------------------------------------

- (NSString *)headerName {
  NSString *key = [self->mailListHeader valueForKey:@"key"];

  return [[self labels] valueForKey:key];
}

- (NSString *)entryString {
  NSString *key    = nil;
  NSString *relKey = nil;
  id       entry   = nil;

  key    = [self->mailListEntry valueForKey:@"key"];
  relKey = [self->mailListEntry valueForKey:@"relationKey"];
  entry  = [self->message valueForKey:key];

  if (![entry isNotNull]) {
    return ([key isEqualToString:@"subject"])
      ? [[self labels] valueForKey:@"noMailTitle"]
      : nil;
  }
  if ([entry isKindOfClass:DateClass]) {
    [entry setTimeZone:[[self session] timeZone]];

    return [entry descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"];
  }
  if ([entry isKindOfClass:StringClass]) {
    NSUserDefaults *d;
    
    d = [[self session] userDefaults];
#if DEBUG
    NSAssert(d, @"missing userdefaults ..");
#endif
    
    if ([key isEqualToString:@"subject"]) {
      if ([self _isEmptyString:entry])
        return [[self labels] valueForKey:@"noMailTitle"];
      
      return [entry shortened:[[d valueForKey:@"mail_subjectLength"] intValue]];
    }
    else if ([key isEqualToString:@"sender"] || [key isEqualToString:@"to"])
      return [entry shortened:[[d valueForKey:@"mail_senderLength"] intValue]];
  }

  return (relKey != nil)
    ? [entry valueForKey:relKey]
    : entry;
}

- (void)setEvenRowColor:(NSString *)_color {
  ASSIGN(self->evenRowColor, _color);
}
- (NSString *)evenRowColor {
  return self->evenRowColor;
}
- (void)setOddRowColor:(NSString *)_color {
  ASSIGN(self->oddRowColor, _color);
}
- (NSString *)oddRowColor {
  return self->oddRowColor;
}

- (NSString *)rowColor {
  return ((self->index % 2) == 0)
    ? self->evenRowColor
    : self->oddRowColor;
}

- (BOOL)isSelectedAttribute {
  return ([self->selectedHeader isEqual:self->mailListHeader]) ? YES : NO;
}

- (NSString *)currentOrderingString {
  return [self isSelectedAttribute]
    ? (self->isDescending ? @"upward_sorted.gif" : @"downward_sorted.gif")
    : @"non_sorted.gif";
}

- (NSString *)align {
  return ([self->mailListEntry objectForKey:@"align"]  == nil)
    ? @"left"
    : [self->mailListEntry objectForKey:@"align"];
}

// --- conditions ---------------------------------------

- (BOOL)isAction {
  return (([self->mailListEntry objectForKey:@"action"] != nil));
}

- (BOOL)isRead {
  return [self->message isRead];
}

- (BOOL)isNew {
  return (([[self->message valueForKey:@"isNew"] intValue] == 1));
}


// --- actions -------------------------------------------

- (id)moveMail {
  LSWImapMailMove *page;
  
  if ([self->selectedMessages count] == 0)
    return nil;
  
  page = [self pageWithName:@"LSWImapMailMove"];
  [page setMails:self->selectedMessages];
  [page setCopyMode:NO];
  [self->selectedMessages removeAllObjects];
  return page;
}

- (id)copyMail {
  LSWImapMailMove *page;
  
  if ([self->selectedMessages count] == 0)
    return nil;
  
  page = [self pageWithName:@"LSWImapMailMove"];
  [page setMails:self->selectedMessages];
  [page setCopyMode:YES];
  [self->selectedMessages removeAllObjects];
  return page;
}

- (id)deleteMail {
  NGImap4Folder *f;
  id tmp;
  
  if ([self->selectedMessages count] == 0)
    return nil;
  
  f = [[self->selectedMessages lastObject] folder];

  if ([f isInTrash])
    [f deleteMessages:self->selectedMessages];
  else
    [f moveMessages:self->selectedMessages toFolder:[[f context] trashFolder]];

  [[[[self session] navigation] activePage]
           postChange:@"LSWImapMailWasDeleted"
           onObject:AUTORELEASE([self->selectedMessages copy])];

  tmp = [self->messages mutableCopy];
  [tmp removeObjectsInArray:self->selectedMessages];
  [self->messages release];
  self->messages = [tmp copy];
  [tmp release];
  
  [self->selectedMessages removeAllObjects];
  return nil;
}

- (id)entryAction {
  SEL action;

  if ([self->mailListEntry valueForKey:@"action"] == nil)
    return nil;
  
  action = NSSelectorFromString([self->mailListEntry valueForKey:@"action"]);
  if ([self respondsToSelector:action]) 
    [self performSelector:action];
  return nil;
}

- (id)markRead {
  NSEnumerator *enumerator;
  id           obj;

  enumerator = [self->selectedMessages objectEnumerator];

  while ((obj = [enumerator nextObject]))
    [(NGImap4Message *)obj markRead];
  
  [[[[self session] navigation] activePage]
           postChange:@"LSWImapMailFlagsChanged"
           onObject:AUTORELEASE([self->selectedMessages copy])];
  [self->selectedMessages removeAllObjects];
  return nil;
}

- (id)markUnread {
  NSEnumerator *enumerator;
  id           obj;

  enumerator = [self->selectedMessages objectEnumerator];

  while ((obj = [enumerator nextObject]))
    [(NGImap4Message *)obj markUnread];
  
  [[[[self session] navigation] activePage]
           postChange:@"LSWImapMailFlagsChanged"
           onObject:AUTORELEASE([self->selectedMessages copy])];
  [self->selectedMessages removeAllObjects];
  return nil;
}

- (id)viewMail {
  WOComponent *page;
  BOOL wasUnread;
  
  wasUnread = ![self->message isRead];
  [self->message markRead];
  [[[[self session] navigation] activePage] 
           postChange:@"LSWImapMailFlagsChanged"
           onObject:self->message];
  // by mh for handling unread mails with disposition-notification-to header
  page = [[[self session] navigation] activateObject:self->message
                                      withVerb:@"view"];
  [page takeValue:[NSNumber numberWithBool:wasUnread]
        forKey:@"messageWasUnread"];
  return page;
}

- (id)markMessageRead {
  [self->message markRead];
  return nil;
}

- (id)markMessageUnread {
  [self->message markUnread];
  return nil;
}

- (id)markMessageFlagged {
  [self->message markFlagged];
  return nil;
}

- (id)markMessageUnflagged {
  [self->message markUnFlagged];
  return nil;
}

- (id)sort {
  self->isDescending = ![self->selectedHeader isEqual:self->mailListHeader]
    ? NO // if the selected attribute is changed, ascending order is the default
    : !self->isDescending;
  ASSIGN(self->selectedHeader, self->mailListHeader);
  {
    NSString       *key        = nil;
    NSUserDefaults *defs       = nil;
    NSString       *folderName = nil;

    if (self->folder != nil)
      folderName = [self->folder absoluteName];
    else
      folderName = @"default";
    
    key        = @"LSImapMailListSortHeader_";
    defs       = [[self session] userDefaults];
    key        = [key stringByAppendingString:folderName];
    [self runCommand:@"userDefaults::write",
          @"key",      key,
          @"value",    [self->selectedHeader valueForKey:@"key"],
          @"userDefaults", defs, nil];

    key = @"LSImapMailListSortHeaderOrder_";
    key = [key stringByAppendingString:folderName];
    [self runCommand:@"userDefaults::write",
          @"key",      key,
          @"value",    [NSNumber numberWithBool:self->isDescending],
          @"userDefaults", defs, nil];
  }
  return nil;
}

- (NSString *)selectAllCheckboxesScript {
  return [NSString stringWithFormat:self->selectAllCheckboxesScript,
                     [self->messages count]];
}
- (NSString *)checkBoxName {
  return [NSString stringWithFormat:@"a%d", [self index]];
}

- (NSString *)shiftClick {
  return [NSString stringWithFormat:@"shiftClick(%d)", [self index]];
}

- (NSString *)uniqueIdentifier {
  return [self uidForMail:self->message];
}

- (NSString *)identifierForCheckBox {
  return [self uidForMail:self->message];
}
- (void)setIdentifierForCheckBox:(NSString *)_id {
  [self->identifier addObject:_id];
}

- (void)setIsChecked:(BOOL)_bool {
}
- (BOOL)isChecked {
  return [self->selectedMessages containsObject:self->message];
}

- (NSArray *)markedMails {
  NSEnumerator   *enumerator = nil;
  id             obj         = nil;
  NSMutableArray *array      = nil;

  array = [NSMutableArray arrayWithCapacity:64];

  enumerator = [self->messages objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    BOOL check = [self->identifier containsObject:[self uidForMail:obj]];
#if 0
     [obj takeValue:[NSNumber numberWithBool:check]
          forKey:self->isCheckedKey];
#endif
    if (check)
      [array addObject:obj];
  }
  return array;
}

- (NSString *)uidForMail:(NGImap4Message *)_msg {
  return [NSString stringWithFormat:@"%08X_%d",
                     [_msg folder], [_msg uid]];
}

- (BOOL)_isEmptyString:(NSString *)_str {
  NSArray *strList = [_str componentsSeparatedByString:@" "];

  if (([_str length] == 0))
    return YES;
  {
    
    NSEnumerator *strEnum = [strList objectEnumerator];
    NSString     *str;

    while ((str = [strEnum nextObject])) {
      if ([str length] > 0)
        return NO;
    }
  }
  return YES;
}

- (NSDictionary *)_getSelectedHeader {
  NSString        *key        = nil;
  NSEnumerator    *enumerator = nil;
  NSDictionary    *header     = nil;
  NSString        *folderName = nil;
  NSUserDefaults  *defs       = nil;

  defs       = [[self session] userDefaults];

  if (self->folder != nil) 
    folderName = [self->folder absoluteName];
  else
    folderName = @"default";

  self->isDescending = [[defs objectForKey:[@"LSImapMailListSortHeaderOrder_"
                                             stringByAppendingString:
                                             folderName]] boolValue];
    
  key = [defs objectForKey:[@"LSImapMailListSortHeader_"
                             stringByAppendingString:folderName]];
  if (key != nil) {
    enumerator = [self->mailListHeaders objectEnumerator];
    while ((header = [enumerator nextObject])) {
      if ([key isEqual:[header objectForKey:@"key"]]) {
        break;
      }
    }
    return header;
  }
  return [self->mailListHeaders objectAtIndex:0];
}
  
    
#if 0  
  NSEnumerator *headerEnum = [self->mailListHeaders objectEnumerator];
  NSDictionary *myHeader   = nil;

  while ((myHeader = [headerEnum nextObject])) {
    if ([[myHeader valueForKey:@"isSorted"] boolValue])
      return myHeader;
  }
  return [self->mailListHeaders objectAtIndex:0];
#endif

- (void)setIndex:(int)_idx {
  self->index = _idx;
}
- (int)index {
  return self->index;
}

- (void)sortMessages {
  id tmp = nil;

  [self setSelectedHeader:[self _getSelectedHeader]];
  tmp            = self->messages;
  self->messages = (id)[self->sorter sortArray:self->messages
                            key:[self->selectedHeader objectForKey:@"key"]
                            isDescending:self->isDescending];
  RETAIN(self->messages);
  RELEASE(tmp); tmp = nil;
}

- (NSString *)longSubject {
  return [NSString stringWithFormat:@"\"%@\" - %@",
                   [self->message valueForKey:@"subject"],
                   [self->message valueForKey:@"sender"]];
}

- (id)messageStatusLabel {
  NSArray *flags    = [self->message flags];
  id      l         = nil;
  BOOL    replied   = NO;
  BOOL    forwarded = NO;

  l         = [self labels];
  
  if ([[self->message valueForKey:@"isNew"] boolValue])
    return [l valueForKey:@"newStatus"];
  
  replied   = [self->message isAnswered];
  forwarded = [flags containsObject:@"forwarded"];

  if (replied && forwarded)
    return [l valueForKey:@"repliedAndForwardedStatus"];
  if (replied)
    return [l valueForKey:@"repliedStatus"];
  if (forwarded)
    return [l valueForKey:@"forwardedStatus"];

  if ([self->message isRead])
    return [l valueForKey:@"readStatus"];
  
  return [l valueForKey:@"unreadStatus"];
}

@end /* LSWImapMailList */

@implementation LSWImapMailList(BelongsToLSWImapMails)

// TODO: explain that category!

- (BOOL)isShowAll {
  return self->isShowAll;
}
- (void)setIsShowAll:(BOOL)_bool {
  self->isShowAll = _bool;
}

- (BOOL)isShowUnread {
  return !self->isShowAll;
}

- (id)showAll {
  return [self performParentAction:@"showAll"];
}

- (id)showUnread {
  return [self performParentAction:@"showUnread"];
}

@end /* LSWImapMailList(BelongsToLSWImapMails) */
