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

#include "LSWMimePartViewer.h"

/*
  needs to show subject .. if nestingDepth > 0
*/
#define MAX_LENGTH 100

@interface SkyMessageRfc822Viewer : LSWMimePartViewer
{
  NSString *to;
  NSString *cc;
}
@end

#include "common.h"

@implementation SkyMessageRfc822Viewer

- (void)dealloc {
  [self->to release];
  [self->cc release];
  [super dealloc];
}

- (BOOL)isRootPart {
  return self->nestingDepth == 0 ? YES : NO;
}

- (NSString *)subject {
  id v;
  v = [self->part valuesOfHeaderFieldWithName:@"subject"];
  v = [v nextObject];
  return v;
}
- (NSString *)contentLength {
  id v;
  v = [self->part valuesOfHeaderFieldWithName:@"content-length"];
  v = [v nextObject];
  return v;
}
- (NSString *)from {
  id v;
  v = [self->part valuesOfHeaderFieldWithName:@"from"];
  v = [v nextObject];
  return v;
}
- (NSString *)date {
  id v;
  v = [self->part valuesOfHeaderFieldWithName:@"date"];
  v = [v nextObject];
  return v;
}

- (NSString *)organization {
  id v;
  
  v = [self->part valuesOfHeaderFieldWithName:@"organization"];
  v = [v nextObject];
  return [v stringValue];
}

/* returns a retained StringObject */

- (NSString *)_receiverForHeaderFieldWithName:(NSString *)_fieldName {
  NSMutableString *receiver;
  NSString        *str;
  NSEnumerator    *enumerator;

  receiver =  [[NSMutableString allocWithZone:[self zone]] init];
  enumerator = [self->part valuesOfHeaderFieldWithName:_fieldName];
  [receiver setString:[enumerator nextObject]];

  while ((str = [enumerator nextObject])) {
    [receiver appendString:@", "];
    [receiver appendString:str];
  }
  return receiver;
}

- (id)objectForSessionCache:(NSString *)_key {
  NSMutableDictionary *cache;

  cache = [[self session] valueForKey:@"ShowBodyHeaders"];

  if (!cache) {
    cache = [NSMutableDictionary dictionaryWithCapacity:64];
    [[self session] takeValue:cache forKey:@"ShowBodyHeaders"];
  }
  return [cache objectForKey:[[self partKey] stringByAppendingString:_key]];
}

- (void)setObject:(id)_obj forSessionCache:(NSString *)_key {
  NSMutableDictionary *cache;

  cache = [[self session] valueForKey:@"ShowBodyHeaders"];

  if (!cache) {
    cache = [NSMutableDictionary dictionaryWithCapacity:64];
    [[self session] takeValue:cache forKey:@"ShowBodyHeaders"];
  }
  [cache setObject:_obj forKey:[[self partKey] stringByAppendingString:_key]];
}

- (BOOL)isToCollapsed {
  id o;

  if ((o = [self objectForSessionCache:@"to"]))
      return [o boolValue];

  return YES;
}

- (void)setIsToCollapsed:(BOOL)_bool {
  [self setObject:[NSNumber numberWithBool:_bool] forSessionCache:@"to"];
}

- (BOOL)isCcCollapsed {
  id o;

  if ((o = [self objectForSessionCache:@"cc"]))
      return [o boolValue];

  return YES;
}

- (void)setIsCcCollapsed:(BOOL)_bool {
  [self setObject:[NSNumber numberWithBool:_bool] forSessionCache:@"cc"];
}


- (NSString *)to {
  if (self->to == nil) {
    self->to = [self _receiverForHeaderFieldWithName:@"to"];
  }
  if ([self->to length] < MAX_LENGTH) return self->to;

  if ([self isToCollapsed])
    return [[self->to substringToIndex:MAX_LENGTH]
                      stringByAppendingString:@".."];
  else
    return self->to;
}

- (NSString *)cc {
  if (self->cc == nil) {
    self->cc = [self _receiverForHeaderFieldWithName:@"cc"];
  }
  if ([self->cc length] < MAX_LENGTH) return self->cc;

  if ([self isCcCollapsed])
    return [[self->cc substringToIndex:MAX_LENGTH]
                      stringByAppendingString:@".."];
  else
    return self->cc;
}

- (BOOL)showToCollapser {
  if ([[self to] length] < MAX_LENGTH) return NO;
  
  return ![self isToCollapsed];
}
- (BOOL)showToExpander {
  if ([[self to] length] < MAX_LENGTH) return NO;
  
  return [self isToCollapsed];
}

- (BOOL)showCcCollapser {
  if ([[self cc] length] < MAX_LENGTH) return NO;
  
  return ![self isCcCollapsed];
}
- (BOOL)showCcExpander {
  if ([[self cc] length] < MAX_LENGTH) return NO;
  
  return [self isCcCollapsed];
}

- (id)expandTo {
  [self setIsToCollapsed:NO];
  return nil;
}
- (id)collapseTo {
  [self setIsToCollapsed:YES];
  return nil;
}
- (id)expandCc {
  [self setIsCcCollapsed:NO];
  return nil;
}
- (id)collapseCc {
  [self setIsCcCollapsed:YES];
  return nil;
}

- (BOOL)isEoType {
  NGMimeType *contentType;
  
  contentType = [self->part contentType];
  
  return ([[contentType type] isEqualToString:@"eo-pkey"]) ? YES : NO;
}

- (BOOL)isRfcType {
  static NGMimeType *rfc822 = nil;
  NGMimeType *contentType;

  if (rfc822 == nil)
    rfc822 = [[NGMimeType mimeType:@"message/rfc822"] retain];
  
  contentType = [self->part contentType];
  
  return [contentType hasSameType:rfc822] ? YES : NO;
}

- (BOOL)isApp {
  return [[[self->part contentType] stringValue] hasPrefix:@"application"];
}

- (BOOL)isMultipart {
  return [[[[self->part contentType] stringValue] lowercaseString]
                        hasPrefix:@"multipart"];
}


- (BOOL)hasCC {
  return [[self cc] length] > 0 ? YES : NO;
}

- (BOOL)hasOrganization {
  return [[self organization] length] > 0 ? YES : NO;
}

- (BOOL)isProjectApplicationAvailable {
  // TODO: should check whether the project app is installed
  return YES;
}

- (BOOL)bodyPartIsComposite {
  return [[self->part contentType] isCompositeType];
}

- (BOOL)hasContentLength {
  return [[self contentLength] intValue]?YES:NO;
}
@end /* SkyMessageRfc822Viewer */
