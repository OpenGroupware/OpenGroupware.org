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

#include "SOGoMailBodyPart.h"
#include "SOGoMailObject.h"
#include "SOGoMailManager.h"
#include "common.h"

@implementation SOGoMailBodyPart

static BOOL debugOn = NO;

- (void)dealloc {
  [self->partInfo   release];
  [self->identifier release];
  [self->pathToPart release];
  [super dealloc];
}

/* hierarchy */

- (SOGoMailObject *)mailObject {
  return [[self container] mailObject];
}

/* IMAP4 */

- (NSString *)bodyPartName {
  NSString *s;
  NSRange  r;

  s = [self nameInContainer];
  r = [s rangeOfString:@"."]; /* strip extensions */
  if (r.length == 0)
    return s;
  return [s substringToIndex:r.location];
}

- (NSArray *)bodyPartPath {
  NSMutableArray *p;
  id obj;
  
  if (self->pathToPart != nil)
    return [self->pathToPart isNotNull] ? self->pathToPart : nil;
  
  p = [[NSMutableArray alloc] initWithCapacity:8];
  for (obj = self; [obj isKindOfClass:[SOGoMailBodyPart class]]; 
       obj = [obj container]) {
    [p insertObject:[obj bodyPartName] atIndex:0];
  }
  
  self->pathToPart = [p copy];
  [p release];
  return self->pathToPart;
}

- (NSString *)bodyPartIdentifier {
  if (self->identifier != nil)
    return [self->identifier isNotNull] ? self->identifier : nil;
  
  self->identifier =
    [[[self bodyPartPath] componentsJoinedByString:@"."] copy];
  return self->identifier;
}

- (NSURL *)imap4URL {
  /* reuse URL of message */
  return [[self mailObject] imap4URL];
}

/* part info */

- (id)partInfo {
  if (self->partInfo != nil)
    return [self->partInfo isNotNull] ? self->partInfo : nil;

  self->partInfo =
    [[[self mailObject] lookupInfoForBodyPart:[self bodyPartPath]] retain];
  return self->partInfo;
}

/* name lookup */

- (id)lookupImap4BodyPartKey:(NSString *)_key inContext:(id)_ctx {
  // TODO: we might want to check for existence prior controller creation
  Class clazz;
  
  clazz = [SOGoMailBodyPart bodyPartClassForKey:_key inContext:_ctx];
  return [[[clazz alloc] initWithName:_key inContainer:self] autorelease];
}

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  id obj;
  
  /* first check attributes directly bound to the application */
  if ((obj = [super lookupName:_key inContext:_ctx acquire:NO]) != nil)
    return obj;
  
  /* lookup body part */
  
  if ([self isBodyPartKey:_key inContext:_ctx]) {
    if ((obj = [self lookupImap4BodyPartKey:_key inContext:_ctx]) != nil)
      return obj;
  }
  
  /* 
     Treat other keys which have a path-extension as 'virtual' noops to allow
     addition of path names to the attachment path, eg:
       http://.../login@server/INBOX/1/2/3/MyDocument.pdf
  */
  if ([[_key pathExtension] length] > 0)
    return self;
  
  /* return 404 to stop acquisition */
  return [NSException exceptionWithHTTPStatus:404 /* Not Found */];
}

/* fetch */

- (NSData *)fetchBLOB {
  // HEADER, HEADER.FIELDS, HEADER.FIELDS.NOT, MIME, TEXT
  NSString *enc;
  NSData *data;
  
  data = [[self mailManager] fetchContentOfBodyPart:[self bodyPartIdentifier]
			     atURL:[self imap4URL]
			     password:[self imap4Password]];
  if (data == nil) return nil;

  /* check for content encodings */
  
  if ((enc = [[self partInfo] valueForKey:@"encoding"]) != nil) {
    enc = [enc uppercaseString];
    
    if ([enc isEqualToString:@"BASE64"])
      data = [data dataByDecodingBase64];
    else if ([enc isEqualToString:@"7BIT"])
      ; /* keep data as is */ // TODO: do we need to change encodings?
    else
      [self errorWithFormat:@"unsupported encoding: %@", enc];
  }
  
  return data;
}

/* WebDAV */

- (NSString *)contentTypeForBodyPartInfo:(id)_info {
  NSMutableString *type;
  NSString     *mt, *st;
  NSDictionary *parameters;
  NSEnumerator *ke;
  NSString     *pn;
    
  if (![_info isNotNull])
    return nil;
  
  mt = [_info valueForKey:@"type"];    if (![mt isNotNull]) return nil;
  st = [_info valueForKey:@"subtype"]; if (![st isNotNull]) return nil;
  
  type = [NSMutableString stringWithCapacity:16];
  [type appendString:[mt lowercaseString]];
  [type appendString:@"/"];
  [type appendString:[st lowercaseString]];
  
  parameters = [_info valueForKey:@"parameterList"];
  ke = [parameters keyEnumerator];
  while ((pn = [ke nextObject]) != nil) {
    [type appendString:@"; "];
    [type appendString:pn];
    [type appendString:@"=\""];
    [type appendString:[[parameters objectForKey:pn] stringValue]];
    [type appendString:@"\""];
  }
  return type;
}

- (NSString *)contentTypeForPathExtension:(NSString *)pe {
  if ([pe length] == 0)
    return @"application/octet-stream";
  
  /* TODO: add some map */
  if ([pe isEqualToString:@"gif"]) return @"image/gif";
  if ([pe isEqualToString:@"png"]) return @"image/png";
  if ([pe isEqualToString:@"jpg"]) return @"image/jpeg";
  if ([pe isEqualToString:@"txt"]) return @"text/plain";
  
  return @"application/octet-stream";
}

- (NSString *)davContentType {
  // TODO: what about the content-type and other headers?
  //       => we could pass them in as the extension? (eg generate 1.gif!)
  NSString *pe;
  
  /* try type from body structure info */
  
  if ((pe = [self contentTypeForBodyPartInfo:[self partInfo]]) != nil)
    return pe;
  
  /* construct type */
  
  pe = [[self nameInContainer] pathExtension];
  return [self contentTypeForPathExtension:pe];
}

/* actions */

- (id)GETAction:(WOContext *)_ctx {
  WOResponse *r;
  NSData     *data;
  
  [self debugWithFormat:@"should fetch body part: %@", 
	  [self bodyPartIdentifier]];
  
  if ((data = [self fetchBLOB]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"did not find body part"];
  }
  
  [self debugWithFormat:@"  fetched %d bytes: %@", [data length],
	[self partInfo]];
  
  // TODO: wrong, could be encoded
  r = [_ctx response];
  [r setHeader:[self davContentType] forKey:@"content-type"];
  [r setHeader:[NSString stringWithFormat:@"%d", [data length]]
     forKey:@"content-length"];
  [r setContent:data];
  return r;
}

/* factory */

+ (Class)bodyPartClassForKey:(NSString *)_key inContext:(id)_ctx {
  NSString *pe;
  
  pe = [_key pathExtension];
  if (![pe isNotNull] || [pe length] == 0)
    return self;
  
  /* hard coded for now */
  
  switch ([pe length]) {
  case 3:
    if ([pe isEqualToString:@"gif"] ||
	[pe isEqualToString:@"png"] ||
	[pe isEqualToString:@"jpg"])
      return NSClassFromString(@"SOGoImageMailBodyPart");
  case 4:
    if ([pe isEqualToString:@"mail"])
      return NSClassFromString(@"SOGoMessageMailBodyPart");
  default:
    return self;
  }
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* SOGoMailBodyPart */
