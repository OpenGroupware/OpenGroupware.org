/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#import "common.h"
#import <Foundation/NSFormatter.h>
#import "LSWImapMailMove.h"
#import "SkyImapMailListState.h"
#import "SkyImapMailDataSource.h"
#import "LSWImapMails.h"

@interface LSWImapMails(Private) 
- (void)setToDeletedMails:(NSArray *)_mails;
@end /* LSWImapMails(Private)  */

@interface SkyImapMailStringShortenizer : NSFormatter
{
@protected
  unsigned length;
  NSString *nilString;
}
- (void)setLength:(unsigned int)_length;
- (void)setNilString:(NSString *)_nilString;
@end

@interface SkyImapMailList : OGoContentPage
{
@protected
  EODataSource                 *dataSource;
  SkyImapMailListState         *state;
  SkyImapMailStringShortenizer *senderFormatter;
  SkyImapMailStringShortenizer *subjectFormatter;
  NSMutableArray               *selections;
  id                           message;
  BOOL                         dataSourceDidChange;
  int                          mailCount;
  int                          index;
}
- (void)_showAll;
- (void)_showUnread;
- (void)_showFlagged;
- (id)showAll;
- (id)showUnread;
- (id)showFlagged;

@end

#include "common.h"

@implementation SkyImapMailList

- (id)init {
  if ((self = [super init])) {
    NSZone *z;

    z = [self zone];
    self->senderFormatter  = [[SkyImapMailStringShortenizer alloc] init];
    self->subjectFormatter = [[SkyImapMailStringShortenizer alloc] init];

    [self->subjectFormatter
         setNilString:[[self labels] valueForKey:@"noMailTitle"]];
    self->selections = [[NSMutableArray allocWithZone:z] init];

    [[NSNotificationCenter defaultCenter]
                           addObserver:self
                           selector:@selector(clearSelections)
                           name:@"LSWImapMailsShouldClearSelections"
                           object:nil];

    self->dataSourceDidChange = YES;
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->state            release];
  [self->senderFormatter  release];
  [self->subjectFormatter release];
  [self->message          release];
  [self->selections       release];
  [super dealloc];
}


- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  EOSortOrdering *so;
  SEL            sel;
  NSArray        *soArray;

  sel     = ([self->state isDescending])
          ? EOCompareDescending : EOCompareAscending;
  so      = [EOSortOrdering sortOrderingWithKey:[self->state sortedKey]
                            selector:sel];
  soArray = [NSArray arrayWithObject:so];
  
  if ([(SkyImapMailDataSource *)self->dataSource
                                useSSSortingForSOArray:soArray]) {
    if ([self->state sortedKey]) {
      EOFetchSpecification *fetchSpec;

      if ((fetchSpec = [self->dataSource fetchSpecification]) == nil) {
        fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                          qualifier:nil
                                          sortOrderings:
                                          [NSArray arrayWithObject:so]];
        [self->dataSource setFetchSpecification:fetchSpec];
      }
      else {
        NSArray *sos;

        sos = [NSArray arrayWithObject:so];
      
        if (![[fetchSpec sortOrderings] isEqual:sos]) {
          [fetchSpec setSortOrderings:[NSArray arrayWithObject:so]];
          [self->dataSource setFetchSpecification:fetchSpec];
        }
      }
    }  
    [(SkyImapMailDataSource *)self->dataSource
                                preFetchMessagesInRange:
                                NSMakeRange([self->state blockSize]
                                            * ([self->state currentBatch]-1),
                                            [self->state blockSize])];
  }
  [super appendToResponse:_response inContext:_ctx];
}

- (void)clearSelections {
  [self->selections removeAllObjects];
}

- (void)dataSourceDidChange {
  self->dataSourceDidChange = YES;
}


- (void)syncAwake {
  [super syncAwake];
  
  [self->subjectFormatter setLength:[self->state subjectLength]];
  [self->senderFormatter  setLength:[self->state senderLength]];

  if (self->dataSourceDidChange && [self->state isShowFilterButtons]) {
    if ([self->state showAllMessages] == -1)
      [self _showUnread];
    else if ([self->state showAllMessages] == 1)
      [self _showAll];
    else if ([[self->state showMessages] isEqualToString:@"all"])
      [self showAll];
    else if ([[self->state showMessages] isEqualToString:@"flagged"])
      [self showFlagged];
    else
      [self showUnread];
    self->dataSourceDidChange = NO;
  }
}

- (void)syncSleep {
  [self->state synchronize]; // write userDefaults
  [super syncSleep];
}

// -- accsessors

- (void)setDataSource:(EODataSource *)_dataSource {
  if (self->dataSource != _dataSource) {
    NSNotificationCenter *nc;

    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self
        name:EODataSourceDidChangeNotification
        object:self->dataSource];

    ASSIGN(self->dataSource, _dataSource);

    [nc addObserver:self
        selector:@selector(dataSourceDidChange)
        name:EODataSourceDidChangeNotification
        object:self->dataSource];
  }
}
- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setSelections:(NSArray *)_selections {
  ASSIGN(self->selections, selections);
}
- (NSArray *)selections {
  return self->selections;
}

- (id)message {
  return self->message;
}
- (void)setMessage:(id)_message {
  ASSIGN(self->message, _message);
}

- (NSFormatter *)senderFormatter {
  return self->senderFormatter;
}
- (NSFormatter *)subjectFormatter {
  return self->subjectFormatter;
}

- (void)setState:(SkyImapMailListState *)_state {
  ASSIGN(self->state, _state);
}
- (SkyImapMailListState *)state {
  return self->state;
}

// ------------------------------------------------------------------------

- (NSString *)longSubject {
  return [NSString stringWithFormat:@"\"%@\" - %@",
                   [self->message valueForKey:@"subject"],
                   [self->message valueForKey:@"sender"]];
}

- (NSString *)messageIdentifier {
  return [NSString stringWithFormat:@"%08X_%d",
                     [self->message folder], [self->message uid]];
}

- (NSCalendarDate *)sendDate {
  NSCalendarDate *result;

  result = [self->message valueForKey:@"sendDate"];
  if ([result respondsToSelector:@selector(setTimeZone:)])
    [result setTimeZone:[[self session] timeZone]];
  return result;
}

// --- conditions ---------------------------------------------

- (BOOL)isRead {
  return [self->message isRead];
}

- (BOOL)isAnswered {
  return [self->message isAnswered];
}

- (BOOL)isNew {
  return (([[self->message valueForKey:@"isNew"] intValue] == 1));
}

- (BOOL)isUnread {
  return (![self isRead] && ![self isNew]);
}

- (BOOL)scrollOnClientSide {
  int treshold;
  
  if (![self->state doClientSideScroll])
    return NO;
  
  treshold = [self->state clientSideScrollTreshold];

  return ([[self valueForKey:@"mailCount"] intValue] < treshold) ? YES : NO;
}

/* posting notifications */

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

- (void)_postMailWasDeleted {
  [[self notificationCenter] postNotificationName:@"LSWImapMailWasDeleted"
                             object:nil];
}
- (void)_postMailFlagsChanged:(NGImap4Message *)_msg {
  [[self notificationCenter] postNotificationName:@"LSWImapMailFlagsChanged"
                             object:_msg];
}

/* actions */

- (void)_showAll {
  EOFetchSpecification *fetchSpec;

  fetchSpec = [self->dataSource fetchSpecification];
  [fetchSpec setQualifier:nil];
  
  [self->dataSource setFetchSpecification:fetchSpec];
}

- (void)_showUnread {
  EOFetchSpecification *fetchSpec;
  EOQualifier          *q;

  q = [EOQualifier qualifierWithQualifierFormat:@"flags = \"unseen\""];
  
  fetchSpec = [self->dataSource fetchSpecification];
  [fetchSpec setQualifier:q];

  [self->dataSource setFetchSpecification:fetchSpec];
}

- (void)_showFlagged {
  EOFetchSpecification *fetchSpec;
  EOQualifier          *q;
  
  q = [EOQualifier qualifierWithQualifierFormat:@"flags = \"flagged\""];
  fetchSpec = [self->dataSource fetchSpecification];
  [fetchSpec setQualifier:q];

  [self->dataSource setFetchSpecification:fetchSpec];
}

- (id)showAll {
  [self->state setShowAllMessages:0];
  [self _showAll];
  [self->state setShowMessages:@"all"];

  return nil;
}

- (id)showUnread {
  [self->state setShowAllMessages:0];
  [self _showUnread];
  [self->state setShowMessages:@"unread"];

  return nil;
}

- (id)showFlagged {
  [self->state setShowAllMessages:0];  
  [self _showFlagged];
  [self->state setShowMessages:@"flagged"];

  return nil;
}

- (id)viewMail {
  NSNotificationCenter *nc;
  BOOL                 wasUnread;
  id                   page;

  nc        = [NSNotificationCenter defaultCenter];
  wasUnread = ![self->message isRead];

  if (![self->message isRead]) {
    [self->message markRead];
    [self _postMailFlagsChanged:self->message];
  }
  page = [[[self session] navigation] activateObject:self->message
                                      withVerb:@"view"];
  [page takeValue:[NSNumber numberWithBool:wasUnread]
        forKey:@"messageWasUnread"];
  [page takeValue:self->dataSource forKey:@"mailDS"];
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

- (id)markMessageNotAnswered {
  [self->message markNotAnswered];
  [self _postMailFlagsChanged:self->message];
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

- (id)markRead {
  NSEnumerator *enumerator;
  id           obj;

  enumerator = [self->selections objectEnumerator];

  while ((obj = [enumerator nextObject]))
    [(NGImap4Message *)obj markRead];
  
  [self _postMailFlagsChanged:nil];
  [self->selections removeAllObjects];
  return nil;
}

- (id)markUnread {
  NSEnumerator *enumerator;
  id           obj;

  enumerator = [self->selections objectEnumerator];

  while ((obj = [enumerator nextObject]))
    [(NGImap4Message *)obj markUnread];
  
  [self _postMailFlagsChanged:nil /* a set changed */];
  [self->selections removeAllObjects];
  return nil;
}

- (id)markFlagged {
  NSEnumerator *enumerator;
  id           obj;

  enumerator = [self->selections objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    [(NGImap4Message *)obj markFlagged];
  }
  [self _postMailFlagsChanged:nil];
  [self->selections removeAllObjects];
  return nil;
}

- (id)markUnFlagged {
  NSEnumerator *enumerator;
  id           obj;
  
  enumerator = [self->selections objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    [(NGImap4Message *)obj markUnFlagged];
  }
  [self _postMailFlagsChanged:nil];
  [self->selections removeAllObjects];
  return nil;
}

- (id)moveMail {
  if (([self->selections count] > 0)) {
    LSWImapMailMove *page;

    page = [self pageWithName:@"LSWImapMailMove"];
    [page setMails:AUTORELEASE([self->selections copy])];
    [page setCopyMode:NO];
    [self->selections removeAllObjects];
    
    return page;
  }
  return nil;
}

- (id)copyMail {
  if (([self->selections count] > 0)) {
    LSWImapMailMove *page;

    page = [self pageWithName:@"LSWImapMailMove"];
    [page setMails:AUTORELEASE([self->selections copy])];
    [page setCopyMode:YES];
    [self->selections removeAllObjects];
    
    return page;
  }
  return nil;
}

- (id)deleteMail {
  NGImap4Folder *f;
  
  if ([self->selections count] == 0)
    return nil;

  f  = [[self->selections lastObject] folder];
    
  if ([f isInTrash])
      [f deleteMessages:self->selections];
  else {
      if (![f moveMessages:self->selections
              toFolder:[[f context] trashFolder]]) {
        NSException *exc;
        id          p;

        p = [[[self session] navigation] activePage];

        exc = [f lastException];

        [p setWarningOkAction:@"reallyDeleteMails"];
        {
          NSString *wp, *reason;
          id       l;

          l  = [self labels];
          wp = [l valueForKey:@"MoveMailToTrashFailedWithReason"];
          if ((reason = [exc reason])) {
            reason = [l valueForKey:reason];
          }
          wp = [NSString stringWithFormat:@"%@: '%@'. %@", wp, reason,
                         [l valueForKey:@"DeleteMailsAnyway"]];
          [p setWarningPhrase:wp];
        }
        [p setIsInWarningMode:YES];
        [p setToDeletedMails:self->selections];
        
        return nil;
      }
  }
  [self _postMailWasDeleted];
  [self->selections removeAllObjects];
  if ([self scrollOnClientSide])
    [self->state setCurrentBatch:1];
  
  return nil;
}

- (int)mailCount {
  return self->mailCount;
}
- (void)setMailCount:(int)_cnt {
  self->mailCount = _cnt;
}

- (int)index {
  return self->index;
}
- (void)setIndex:(int)_cnt {
  self->index = _cnt;
}

@end

@implementation SkyImapMailStringShortenizer

- (id)init {
  if ((self = [super init])) {
    self->length    = 20;
    self->nilString = nil;
  }
  return self;
}

- (void)dealloc {
  [self->nilString release];
  [super dealloc];
}

- (void)setLength:(unsigned int)_length {
  self->length = _length;
}

- (void)setNilString:(NSString *)_nilString {
  ASSIGN(self->nilString, _nilString);
}

// object => string

- (NSString *)stringForObjectValue:(id)_object {
  if (![_object isNotNull] || [_object length] == 0)
    return (self->nilString) ? self->nilString :  @"";

  if (([_object length] <= self->length) || ([_object length] <= 4))
    return [_object stringValue];
  else {
    NSString *result = [_object substringToIndex:self->length-2];
    
    return [result stringByAppendingString:@".."];
  }
}

- (NSString *)editingStringForObjectValue:(id)_object {
  return (![_object isNotNull])
    ? (NSString *)@""
    : [_object stringValue];
}

// string => object

- (BOOL)getObjectValue:(id *)_object
  forString:(NSString *)_string
  errorDescription:(NSString **)_error
{
  *_object = ([_string length] == 0) ? [EONull null] : (id)_string;

  return YES;
}

@end /* SkyImapMailStringShortenizer */
