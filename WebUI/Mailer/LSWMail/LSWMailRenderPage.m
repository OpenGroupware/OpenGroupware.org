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

#include "LSWMailRenderPage.h"
#import "common.h"

@interface LSWMailRenderPage(Private)
- (void)initSender;
@end

@implementation LSWMailRenderPage

- (id)init {
  if ((self = [super init])) {
    [self initSender];
    self->inlineLink = YES;
    self->escapeHTML = YES;
  }
  return self;
}

- (void)dealloc {
  [self->attachments release];
  [self->content     release];
  [self->subject     release];
  [self->sender      release];
  [self->date        release];
  self->attachment = nil;
  [super dealloc];
}

- (void)initSender {
  if (self->sender == nil) {
    id       account;
    NSString *email1, *n, *firstName;

    account = [[self session] activeAccount];

    if ((email1 = [account valueForKey:@"email1"]) == nil)
      email1 = @"";
    if ((n = [account valueForKey:@"name"]) == nil)
      n = @"";
    if ((firstName = [account valueForKey:@"firstname"]) == nil)
      firstName = @"";

    self->sender = [[NSString alloc] initWithFormat:@"%@ %@ <%@>", firstName,
                                     n, email1];
  }
}

- (void)setAttachments:(NSArray *)_att {
  ASSIGN(self->attachments, _att);
}

- (id)attachments {
  return self->attachments;
}

- (BOOL)attachCond {
  NSNumber *b;

  b = [self->attachment objectForKey:@"sendObject"];
  if (b == nil)
    return YES;
  return [b boolValue];
}


- (id)attachment {
  return self->attachment;
}
- (void)setAttachment:(id)_attachment {
  self->attachment = _attachment;
}

- (NSString *)subject {
  return self->subject;
}
- (void)setSubject:(NSString *)_subject {
  ASSIGNCOPY(self->subject, _subject);
}

- (void)setContent:(NSString *)_content {
  ASSIGNCOPY(self->content, _content);
}
- (NSString *)content {
  return self->content;
}

- (void)setDate:(NSCalendarDate *)_date {
  ASSIGN(self->date, _date);
}
- (NSString *)dateString{
  if (self->date == nil)
    self->date = [[NSCalendarDate date] retain];
  
  return [self->date descriptionWithCalendarFormat:
                       [[self config]
                              valueForKey:@"calendarFormat"]];
};

- (NSString *)sender {
  return self->sender;
}

- (id)currentAttachmentComponent {
  [self logWithFormat:
	  @"ERROR(%s): this method should be overridden by a subclass!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (void)setInlineLink:(BOOL)_lnk {
  self->inlineLink = _lnk;
}
- (BOOL)inlineLink {
  return self->inlineLink;
}

- (void)setEscapeHtml:(BOOL)_b {
  self->escapeHTML = _b;
}
- (BOOL)escapeHTML {
  return self->escapeHTML;
}

@end


@implementation LSWMailHtmlRenderPage

- (id)currentAttachmentComponent {
  id viewer;

  viewer = [[self session] instantiateComponentForCommand:@"htmlMail"
                           type:[self->attachment objectForKey:@"mimeType"]];
  if (viewer == nil)
    viewer = [[self application] pageWithName:@"LSWObjectHtmlMailPage"];

  [viewer setObject:[self->attachment objectForKey:@"object"]];
  [viewer setInlineLink:self->inlineLink];

  if (![[self->attachment objectForKey:@"attachData"] boolValue]) {
    [viewer setShowDirectActionLink:YES];
  }

  return viewer;
}

@end

@implementation LSWMailTextRenderPage

- (id)currentAttachmentComponent {
  id viewer;

  viewer = [[self session] instantiateComponentForCommand:@"textMail"
                           type:[self->attachment objectForKey:@"mimeType"]];
  if (viewer == nil)
    viewer = [[self application] pageWithName:@"LSWObjectTextMailPage"];

  [viewer setObject:[self->attachment objectForKey:@"object"]];

  if (![[self->attachment objectForKey:@"attachData"] boolValue]) {
    [viewer setShowDirectActionLink:YES];
  }

  return viewer;
}

@end
