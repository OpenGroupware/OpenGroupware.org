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

#include "SOGoMailObject.h"
#include "SOGoMailManager.h"
#include "SOGoMailBodyPart.h"
#include <NGImap4/NGImap4Envelope.h>
#include <NGImap4/NGImap4EnvelopeAddress.h>
#include "common.h"

@implementation SOGoMailObject

static NSArray *coreInfoKeys = nil;
static BOOL heavyDebug = NO;
static BOOL debugOn = NO;
static BOOL debugBodyStructure = NO;

+ (void)initialize {
  /* Note: see SOGoMailManager.m for allowed IMAP4 keys */
  /* Note: "BODY" actually returns the structure! */
  coreInfoKeys = [[NSArray alloc] initWithObjects:
				    @"FLAGS", @"ENVELOPE", @"BODY",
				    @"RFC822.SIZE",
				    // not yet supported: @"INTERNALDATE",
				  nil];
}

- (void)dealloc {
  [self->coreInfos release];
  [super dealloc];
}

/* IMAP4 */

- (NSString *)relativeImap4Name {
  return [[self nameInContainer] stringByDeletingPathExtension];
}

/* hierarchy */

- (SOGoMailObject *)mailObject {
  return self;
}

/* part hierarchy */

- (NSString *)keyExtensionForPart:(id)_partInfo {
  NSString *mt, *st;
  
  if (_partInfo == nil)
    return nil;
  
  mt = [_partInfo valueForKey:@"type"];
  st = [[_partInfo valueForKey:@"subtype"] lowercaseString];
  if ([mt isEqualToString:@"text"]) {
    if ([st isEqualToString:@"plain"])
      return @".txt";
    if ([st isEqualToString:@"html"])
      return @".html";
  }
  else if ([mt isEqualToString:@"image"])
    return [@"." stringByAppendingString:st];
  
  return nil;
}

- (NSArray *)relationshipKeysWithParts:(BOOL)_withParts {
  /* should return non-multipart children */
  NSMutableArray *ma;
  NSArray *parts;
  unsigned i, count;
  
  parts = [[self bodyStructure] valueForKey:@"parts"];
  if (![parts isNotNull]) 
    return nil;
  if ((count = [parts count]) == 0)
    return nil;
  
  for (i = 0, ma = nil; i < count; i++) {
    NSString *key, *ext;
    id   part;
    BOOL hasParts;
    
    part     = [parts objectAtIndex:i];
    hasParts = [part valueForKey:@"parts"] != nil ? YES:NO;
    if ((hasParts && !_withParts) || (_withParts && !hasParts))
      continue;

    if (ma == nil)
      ma = [NSMutableArray arrayWithCapacity:count - i];
    
    ext = [self keyExtensionForPart:part];
    key = [[NSString alloc] initWithFormat:@"%d%@", i + 1, ext?ext:@""];
    [ma addObject:key];
    [key release];
  }
  return ma;
}

- (NSArray *)toOneRelationshipKeys {
  return [self relationshipKeysWithParts:NO];
}
- (NSArray *)toManyRelationshipKeys {
  return [self relationshipKeysWithParts:YES];
}

/* message */

- (id)fetchParts:(NSArray *)_parts {
  return [[self mailManager] fetchURL:[self imap4URL] parts:_parts
			     password:[self imap4Password]];
}

/* core infos */

- (id)fetchCoreInfos {
  id msgs;
  
  if (self->coreInfos != nil)
    return [self->coreInfos isNotNull] ? self->coreInfos : nil;

  msgs = [[self clientObject] fetchParts:coreInfoKeys]; // returns dict
  if (heavyDebug) [self logWithFormat:@"M: %@", msgs];
  msgs = [msgs valueForKey:@"fetch"];
  if ([msgs count] == 0)
    return nil;
  
  self->coreInfos = [[msgs objectAtIndex:0] retain];
  return self->coreInfos;
}

- (id)bodyStructure {
  id body;

  body = [[self fetchCoreInfos] valueForKey:@"body"];
  if (debugBodyStructure)
    [self logWithFormat:@"BODY: %@", body];
  return body;
}

- (NGImap4Envelope *)envelope {
  return [[self fetchCoreInfos] valueForKey:@"envelope"];
}
- (NSString *)subject {
  return [[self envelope] subject];
}
- (NSCalendarDate *)date {
  return [[self envelope] date];
}
- (NSArray *)fromEnvelopeAddresses {
  return [[self envelope] from];
}
- (NSArray *)toEnvelopeAddresses {
  return [[self envelope] to];
}
- (NSArray *)ccEnvelopeAddresses {
  return [[self envelope] cc];
}

- (id)lookupInfoForBodyPart:(id)_path {
  NSEnumerator *pe;
  NSString *p;
  id info;

  if (![_path isNotNull])
    return nil;
  
  if ((info = [self bodyStructure]) == nil) {
    [self errorWithFormat:@"got no body part structure!"];
    return nil;
  }

  /* ensure array argument */
  
  if ([_path isKindOfClass:[NSString class]]) {
    if ([_path length] == 0)
      return info;
    
    _path = [_path componentsSeparatedByString:@"."];
  }
  
  /* 
     For each path component, eg 1,1,3 
     
     Remember that we need special processing for message/rfc822 which maps the
     namespace of multiparts directly into the main namespace.
  */
  pe = [_path objectEnumerator];
  while ((p = [pe nextObject]) != nil && [info isNotNull]) {
    unsigned idx;
    NSArray  *parts;
    NSString *mt;
    
    [self debugWithFormat:@"check PATH: %@", p];
    idx = [p intValue] - 1;

    parts = [info valueForKey:@"parts"];
    mt = [[info valueForKey:@"type"] lowercaseString];
    if ([mt isEqualToString:@"message"]) {
      /* we have special behaviour for message types */
      id body;
      
      if ((body = [info valueForKey:@"body"]) != nil) {
	mt = [body valueForKey:@"type"];
	if ([mt isEqualToString:@"multipart"])
	  parts = [body valueForKey:@"parts"];
	else
	  parts = [NSArray arrayWithObject:body];
      }
    }
    
    if (idx >= [parts count]) {
      [self errorWithFormat:
	      @"body part index out of bounds(idx=%d vs count=%d): %@", 
              (idx + 1), [parts count], info];
      return nil;
    }
    info = [parts objectAtIndex:idx];
  }
  return [info isNotNull] ? info : nil;
}

/* content */

- (NSData *)content {
  NSData *content;
  id     result, fullResult;
  
  fullResult = [self fetchParts:[NSArray arrayWithObject:@"RFC822"]];
  if (fullResult == nil)
    return nil;
  
  if ([fullResult isKindOfClass:[NSException class]])
    return fullResult;
  
  /* extract fetch result */
  
  result = [fullResult valueForKey:@"fetch"];
  if (![result isKindOfClass:[NSArray class]]) {
    [self logWithFormat:
	    @"ERROR: unexpected IMAP4 result (missing 'fetch'): %@", 
	    fullResult];
    return [NSException exceptionWithHTTPStatus:500 /* server error */
			reason:@"unexpected IMAP4 result"];
  }
  if ([result count] == 0)
    return nil;
  
  result = [result objectAtIndex:0];
  
  /* extract message */
  
  if ((content = [result valueForKey:@"message"]) == nil) {
    [self logWithFormat:
	    @"ERROR: unexpected IMAP4 result (missing 'message'): %@", 
	    result];
    return [NSException exceptionWithHTTPStatus:500 /* server error */
			reason:@"unexpected IMAP4 result"];
  }
  
  return [[content copy] autorelease];
}

- (NSString *)contentAsString {
  NSString *s;
  NSData *content;
  
  if ((content = [self content]) == nil)
    return nil;
  if ([content isKindOfClass:[NSException class]])
    return (id)content;
  
  s = [[NSString alloc] initWithData:content 
			encoding:NSISOLatin1StringEncoding];
  if (s == nil) {
    [self logWithFormat:
	    @"ERROR: could not convert data of length %d to string", 
	    [content length]];
    return nil;
  }
  return [s autorelease];
}

/* bulk fetching of plain/text content */

- (BOOL)shouldFetchPartOfType:(NSString *)_type subtype:(NSString *)_subtype {
  _type    = [_type    lowercaseString];
  _subtype = [_subtype lowercaseString];
  
  if ([_type isEqualToString:@"text"])
    return [_subtype isEqualToString:@"plain"];
  return NO;
}

- (void)addRequiredKeysOfStructure:(id)_info path:(NSString *)_p
  toArray:(NSMutableArray *)_keys
  recurse:(BOOL)_recurse
{
  NSArray  *parts;
  unsigned i, count;
  BOOL fetchPart;
  id body;
  
  fetchPart = [self shouldFetchPartOfType:[_info valueForKey:@"type"]
		    subtype:[_info valueForKey:@"subtype"]];
  if (fetchPart) {
    NSString *k;
    
    if ([_p length] > 0) {
      k = [[@"body[" stringByAppendingString:_p] stringByAppendingString:@"]"];
    }
    else {
      /*
	for some reason we need to add ".TEXT" for plain text stuff on root
	entities?
	TODO: check with HTML
      */
      k = @"body[text]";
    }
    [_keys addObject:k];
  }
  
  if (!_recurse)
    return;
  
  /* recurse */
  
  parts = [_info objectForKey:@"parts"];
  for (i = 0, count = [parts count]; i < count; i++) {
    NSString *sp;
    id childInfo;
    
    sp = [_p length] > 0
      ? [_p stringByAppendingFormat:@".%d", i + 1]
      : [NSString stringWithFormat:@"%d", i + 1];
    
    childInfo = [parts objectAtIndex:i];
    
    [self addRequiredKeysOfStructure:childInfo path:sp toArray:_keys
	  recurse:YES];
  }
  
  /* check body */
  
  if ((body = [_info objectForKey:@"body"]) != nil) {
    NSString *sp;

    sp = [[body valueForKey:@"type"] lowercaseString];
    if ([sp isEqualToString:@"multipart"])
      sp = _p;
    else
      sp = [_p length] > 0 ? [_p stringByAppendingString:@".1"] : @"1";
    [self addRequiredKeysOfStructure:body path:sp toArray:_keys
	  recurse:YES];
  }
}

- (NSArray *)plainTextContentFetchKeys {
  NSMutableArray *ma;
  
  ma = [NSMutableArray arrayWithCapacity:4];
  [self addRequiredKeysOfStructure:[[self clientObject] bodyStructure]
	path:@"" toArray:ma recurse:YES];
  return ma;
}

- (NSDictionary *)fetchPlainTextParts:(NSArray *)_fetchKeys {
  NSMutableDictionary *flatContents;
  unsigned i, count;
  id result;
  
  [self debugWithFormat:@"fetch keys: %@", _fetchKeys];
  
  result = [self fetchParts:_fetchKeys];
  result = [result valueForKey:@"RawResponse"]; // hackish
  result = [result objectForKey:@"fetch"]; // Note: -valueForKey: doesn't work!
  
  count        = [_fetchKeys count];
  flatContents = [NSMutableDictionary dictionaryWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString *key;
    NSData   *data;
    
    key  = [_fetchKeys objectAtIndex:i];
    data = [[result objectForKey:key] objectForKey:@"data"];
    
    if (![data isNotNull]) {
      [self debugWithFormat:@"got no data fork key: %@", key];
      continue;
    }

    if ([key isEqualToString:@"body[text]"])
      key = @""; // see key collector
    else if ([key hasPrefix:@"body["]) {
      NSRange r;
      
      key = [key substringFromIndex:5];
      r   = [key rangeOfString:@"]"];
      if (r.length > 0)
	key = [key substringToIndex:r.location];
    }
    [flatContents setObject:data forKey:key];
  }
  return flatContents;
}

- (NSDictionary *)fetchPlainTextParts {
  return [self fetchPlainTextParts:[self plainTextContentFetchKeys]];
}

/* convert parts to strings */

- (NSString *)stringForData:(NSData *)_data partInfo:(NSDictionary *)_info {
  NSString *charset;
  NSString *s;
  
  if (![_data isNotNull])
    return nil;

  s = nil;
  
  charset = [[_info valueForKey:@"parameterList"] valueForKey:@"charset"];
  if ([charset isNotNull] && [charset length] > 0)
    s = [NSString stringWithData:_data usingEncodingNamed:charset];
  
  if (s == nil) { /* no charset provided, fall back to UTF-8 */
    s = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
    s = [s autorelease];
  }
  
  return s;
}

- (NSDictionary *)stringifyTextParts:(NSDictionary *)_datas {
  NSMutableDictionary *md;
  NSEnumerator *keys;
  NSString     *key;
  
  md   = [NSMutableDictionary dictionaryWithCapacity:4];
  keys = [_datas keyEnumerator];
  while ((key = [keys nextObject]) != nil) {
    NSDictionary *info;
    NSString *s;
    
    info = [self lookupInfoForBodyPart:key];
    if ((s = [self stringForData:[_datas objectForKey:key] partInfo:info]))
      [md setObject:s forKey:key];
  }
  return md;
}
- (NSDictionary *)fetchPlainTextStrings:(NSArray *)_fetchKeys {
  /*
    The fetched parts are NSData objects, this method converts them into
    NSString objects based on the information inside the bodystructure.
    
    The fetch-keys are body fetch-keys like: body[text] or body[1.2.3].
    The keys in the result dictionary are "" for 'text' and 1.2.3 for parts.
  */
  NSDictionary *datas;
  
  if ((datas = [self fetchPlainTextParts:_fetchKeys]) == nil)
    return nil;
  if ([datas isKindOfClass:[NSException class]])
    return datas;
  
  return [self stringifyTextParts:datas];
}

/* flags */

- (NSException *)addFlags:(id)_flags {
  return [[self mailManager] addFlags:_flags toURL:[self imap4URL] 
			     password:[self imap4Password]];
}
- (NSException *)removeFlags:(id)_flags {
  return [[self mailManager] removeFlags:_flags toURL:[self imap4URL] 
			     password:[self imap4Password]];
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
  
  /* return 404 to stop acquisition */
  return [NSException exceptionWithHTTPStatus:404 /* Not Found */];
}

/* WebDAV */

- (BOOL)davIsCollection {
  /* while a mail has child objects, it should appear as a file in WebDAV */
  return NO;
}

- (id)davContentLength {
  return [[self fetchCoreInfos] valueForKey:@"size"];
}

- (NSDate *)davCreationDate {
  // TODO: use INTERNALDATE once NGImap4 supports that
  return nil;
}
- (NSDate *)davLastModified {
  return [self davCreationDate];
}

/* actions */

- (id)GETAction:(WOContext *)_ctx {
  WOResponse *r;
  NSData     *content;
  
  content = [self content];
  if ([content isKindOfClass:[NSException class]])
    return content;
  if (content == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"did not find IMAP4 message"];
  }
  
  r = [_ctx response];
  [r setHeader:@"message/rfc822" forKey:@"content-type"];
  [r setContent:content];
  return r;
}

/* operations */

- (NSException *)delete {
  // TODO: copy to Trash folder
  return [[self mailManager] markURLDeleted:[self imap4URL] 
			     password:[self imap4Password]];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* SOGoMailObject */
