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

#import "common.h"

@interface NSCalendarDate(RFC822Dates)
+ (NSCalendarDate *)calendarDateWithRfc822DateString:(NSString *)_str;
@end /* NSString(RFC822Dates) */

@implementation NGImap4Message(KVC)

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if (([_key isEqualToString:@"subject"]) ||
      ([_key isEqualToString:@"sender"]) ||
      ([_key isEqualToString:@"date"]) ||
      ([_key isEqualToString:@"sendDate"]) ||
      ([_key isEqualToString:@"contentLen"]) ||
      ([_key isEqualToString:@"size"]) ||
      ([_key isEqualToString:@"isRead"]) ||
      ([_key isEqualToString:@"isNew"])) {
    /* was 'return NO' ?? */
    [self handleTakeValue:_value forUnboundKey:_key];
  }
  if ([_value isKindOfClass:[NSNumber class]]) {
    if ([_value boolValue])
      [self addFlag:_key];
    else
      [self removeFlag:_key];
    
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  NGHashMap *h;
  
  h = [self headers];
  
  if ([_key isEqualToString:@"subject"])
    return [[h objectEnumeratorForKey:@"subject"] nextObject];
  else if ([_key isEqualToString:@"sender"])
    return [[h objectEnumeratorForKey:@"from"] nextObject];
  else if ([_key isEqualToString:@"from"])
    return [[h objectEnumeratorForKey:@"from"] nextObject];
  else if ([_key isEqualToString:@"reply-to"])
    return [[h objectEnumeratorForKey:@"reply-to"] nextObject];
  else if ([_key isEqualToString:@"to"])
    return [[h objectEnumeratorForKey:@"to"] nextObject];
  else if ([_key isEqualToString:@"uid"])
    return [NSNumber numberWithInt:[self uid]];
  else if ([_key isEqualToString:@"organization"])
      return [[h objectEnumeratorForKey:@"organization"] nextObject];
  else if ([_key isEqualToString:@"messageId"])
      return [[h objectEnumeratorForKey:@"message-id"] nextObject];
  else if ([_key isEqualToString:@"contentType"])
    return [[h objectEnumeratorForKey:@"content-type"] nextObject];
  else if ([_key isEqualToString:@"date"])
    return [[h objectEnumeratorForKey:@"date"] nextObject];
  else if ([_key isEqualToString:@"sendDate"]) {
    NSCalendarDate *date;
    
    date = [[h objectEnumeratorForKey:@"date"] nextObject];
    
    if (![date isKindOfClass:[NSCalendarDate class]]) {
      date = [NSCalendarDate calendarDateWithRfc822DateString:
                               [date stringValue]];
    }
    
    return (date != nil) ? date : (NSCalendarDate *)[NSNull null];
  }
  if ([_key isEqualToString:@"contentLen"])
    return [NSNumber numberWithInt:[self size]];
  if ([_key isEqualToString:@"size"])
    return [NSNumber numberWithInt:[self size]];
  if ([_key isEqualToString:@"isRead"])
    return [NSNumber numberWithBool:[self isRead]];
  if ([_key isEqualToString:@"isNew"])
    return [NSNumber numberWithBool:[[self flags] containsObject:@"recent"]];
  if ([_key isEqualToString:@"emailFolder"])
    return [self folder];
  if ([_key isEqualToString:@"emailFolderName"])
    return [[self folder] name];

  if ([[self flags] containsObject:_key])
    return [NSNumber numberWithBool:YES];
  
  return [NSNumber numberWithBool:NO];
}

@end /* NGImap4Message(KVC) */

@implementation NGImap4Folder(KVC)

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"name"])
    [self handleTakeValue:_value forUnboundKey:_key];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"name"])
    return [self name];
  
  return [super valueForKey:_key];
}
 
@end /* NGImap4Folder(KVC) */
