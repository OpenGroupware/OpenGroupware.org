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

#include "LSWPartBodyViewer.h"
#include "common.h"

@interface NSString(LSWTextPlainBodyViewer)

- (NSString *)stringByWrappingWithWrapLen:(int)_wrapLen
  wrapLongLines:(BOOL)wrapLongLines;

- (NSArray *)findContainedLinks;

@end

@implementation LSWTextPlainBodyViewer

static int UseFoundationStringEncodingForMimeText = -1;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  UseFoundationStringEncodingForMimeText =
    [ud boolForKey:@"UseFoundationStringEncodingForMimeText"] ? 1 : 0;
}

- (void)dealloc {
  [self->item release];
  [super dealloc];
}

/* accessors */

- (BOOL)isDownloadable {
  return YES;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

/* notifications */

- (void)sleep {
  [self setItem:nil];
  [super sleep];
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  return [[self session] userDefaults];
}

- (BOOL)defShouldWrapLongLines {
  return [[self userDefaults] boolForKey:@"mail_wrapLongLines"];
}

- (BOOL)defShouldUseInternalMailer {
  return [[[self userDefaults] stringForKey:@"mail_editor_type"]
                 isEqualToString:@"internal"];
}

/* content */

- (NSString *)bodyAsString {
  NSString *s;

  s = nil;
  
  if ([self->body isKindOfClass:[NSString class]]) {
    s = self->body;
  }
  else {
    NSData   *data;
    NSString *en;
    
    if ([self->body isKindOfClass:[NSURL class]]) {
      NSString *part;

      part = [[[self->body query] componentsSeparatedByString:@"="] lastObject];
      data = [self->source contentsOfPart:part];
    }
    else if ([self->body isKindOfClass:[NSData class]]) {
      data = self->body;
    }
    if ((en = [[self encoding] lowercaseString])) {
      if ([en isEqualToString:@"quoted-printable"]) {
        data = [data dataByDecodingQuotedPrintable];
      }
      else if ([en isEqualToString:@"base64"]) {
        data = [data dataByDecodingBase64];
      }
    }
    if (!UseFoundationStringEncodingForMimeText) {
      NSString *charset;

      charset = [[[self partOfBody] contentType] valueOfParameter:@"charset"];

      if (![charset length])
        charset = @"us-ascii";
      
      s = [NSString stringWithData:data usingEncodingNamed:charset];
    }
    if (s == nil) {
      s = [[[NSString alloc] initWithData:data
                             encoding:NSISOLatin1StringEncoding] autorelease];
    }
  }
  if (s == nil)
    s = [self->body stringValue];

  return s;
}

- (NSDictionary *)printInfoWithTextValue:(NSString *)_value {
  return [NSDictionary dictionaryWithObjectsAndKeys:
                         _value, @"value", @"text", @"kind", nil];
}

- (NSArray *)contentString {
  NSString *s;
  int wrapLength;
  
  s = [self bodyAsString];
  
#warning TODO: check textWrapWidth configuration (use a default?)
  wrapLength = [[[self config] valueForKey:@"textWrapWidth"] intValue];

  s = [s stringByWrappingWithWrapLen:wrapLength
         wrapLongLines:[self defShouldWrapLongLines]];
  
  return [self printMode]
    ? [NSArray arrayWithObject:[self printInfoWithTextValue:s]]
    : [s findContainedLinks];
}

- (BOOL)isActionLink {
  if (![[self->item objectForKey:@"urlKind"] isEqualToString:@"mailto:"])
    return NO;
  if (![self defShouldUseInternalMailer])
    return NO;
  
  return YES;
}

- (id)sendMail {
  id mailEditor; // TODO: add value
  id val;
  
  mailEditor = (id)[[self application] pageWithName:@"LSWImapMailEditor"];
  if (mailEditor == nil)
    return nil;
  
  val = [self->item objectForKey:@"value"];

  /* remove mailto: */    
  if ([val length] > 7)
      val = [val substringFromIndex:7];
  
  [mailEditor addReceiver:val type:@"to"];
  [mailEditor setContentWithoutSign:@""];
  [[[self session] navigation] enterPage:(id<OGoContentPage>)mailEditor];
  return nil; // TODO: can't we just return the new page?
}

@end /* LSWTextPlainBodyViewer */
