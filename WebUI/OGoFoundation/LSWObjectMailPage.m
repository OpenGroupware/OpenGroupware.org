/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "LSWObjectMailPage.h"
#include "common.h"
#include "LSWContentPage.h"
#include "WOSession+LSO.h"
#include "LSWSession.h"
#include "WOComponent+Commands.h"
#include "OGoNavigation.h"

@interface NSObject(LSWObjectMailPage_PRIVATE)
- (id)lsoServer;
@end

@implementation LSWObjectMailPage

static NSData     *emptyData    = nil;
static NGMimeType *appOctetType = nil;

+ (void)initialize {
  // TODO: should check superclass version!
  if (emptyData == nil) emptyData = [[NSData alloc] init];
  if (appOctetType == nil) {
    appOctetType = 
      [[NGMimeType mimeType:@"application" subType:@"octet-stream"] retain]; 
  }
}

+ (int)version {
  return 2;
}

- (id)init {
  if ((self = [super init])) {
    self->inlineLink = YES;
  }
  return self;
}

- (void)dealloc {
  [self->object     release];
  [self->body       release];
  [self->partOfBody release];
  [super dealloc];
}

/* accessors */

- (void)setGlobalID:(EOGlobalID *)_gid {
  id obj;
  
  obj = [[self runCommand:[self getCmdName], @"gid", _gid, nil] lastObject];
  [self setObject:obj];
}

- (void)setObject:(id)_obj {
  ASSIGN(self->object, _obj);
}

- (NSString *)entityName {
  [self logWithFormat:@"ERROR(%s): subclass needs to override this method!",
  	  __PRETTY_FUNCTION__];
  return nil;
}

- (NSString *)getCmdName {
  [self logWithFormat:@"ERROR(%s): subclass needs to override this method!",
  	  __PRETTY_FUNCTION__];
  return nil;
}

/* object processing */

- (NSData *)objectData {
  return emptyData;
}

- (NGMimeType *)objectDataType {
  return appOctetType;
}

- (NGMimeContentDispositionHeaderField *)objectDataContentDisposition {
  NGMimeContentDispositionHeaderField *cdField = nil;
  
  cdField = [[NGMimeContentDispositionHeaderField alloc] initWithString:
                                     NGMimeContentDispositionInlineType];
  return [cdField autorelease];
}

- (id)object {
  NGMimeType *type   = nil;
  NSString   *pkName = nil;
  NSNumber   *objId  = nil;
  EOEntity   *entity = nil;
  id         obj     = nil;

  if (self->object)
    return self->object;

  if ((self->body == nil) || (self->partOfBody == nil))
    return nil;
  
  type = [[self->partOfBody valuesOfHeaderFieldWithName:@"content-type"]
                            nextObject];
  if (type == nil) {
    [self logWithFormat:@"ERROR: missing content type of part: %@", 
            self->partOfBody];
    return nil;
  }
  
  objId  = [NSNumber numberWithInt:atoi([self->body bytes])];
  entity = [[[(id)[[self session] application] lsoServer] model]
                         entityNamed:[self entityName]];
  
  if ((pkName = [[entity primaryKeyAttributeNames] lastObject]) == nil) {
    [self logWithFormat:@"ERROR: missing primary key of entity: %@ (part=%@)",
            entity, self->partOfBody];
    return nil;
  }
  
  obj = [self runCommand:[self getCmdName], pkName, objId, nil];
  if ([obj count] == 0)
    self->object = nil;
  else if ([obj count] == 1) {
    obj = [obj objectAtIndex:0];
    [self setObject:obj];
  }
  else {
    [self logWithFormat:@"WARNING: more than one object for a primary key"];
    obj = [obj objectAtIndex:0];
    [self setObject:obj];
  }
  return self->object;
}

- (NSString *)objectName {
  id obj;

  if ((obj = [self object]) == nil)
    return nil;
  
  if ([obj respondsToSelector:@selector(entity)])
    return [[[self object] entity] name];
  
  // TODO: this occures if you reply to a HTML message
  return nil;
}

- (NSString *)objectUrlKey {
  [self logWithFormat:@"ERROR(%s): subclass needs to override this method!",
  	  __PRETTY_FUNCTION__];
  return nil;
}

- (NSString *)objectUrl {
  NSMutableString *ms;
  NSString  *urlPrefix;
  NSString  *url, *key;
  
  urlPrefix = [[self context] urlSessionPrefix];
  url       = [[[self context] serverURL] stringValue];
  
  if ([url hasSuffix:@"/"] && [urlPrefix hasPrefix:@"/"])
    url = [url substringToIndex:([url length] - 1)];
  
  ms = [NSMutableString stringWithCapacity:256];
  
  if ([url length] > 0) {
    [ms appendString:url];
    [ms appendString:urlPrefix];
  }
  else {
    [self logWithFormat:
            @"WARNING: missing serverURL in context "
            @"(may generate invalid URLs)!"];
    
    [ms appendString:@"http://"];
    [ms appendString:[[[self context] request] headerForKey:@"host"]];
    [ms appendString:urlPrefix];
  }

  key = [self objectUrlKey];
  if (![ms hasSuffix:@"/"] && ![key hasPrefix:@"/"])
    [ms appendString:@"/"];
  [ms appendString:key];

  return ms;
}

/* actions */

- (id)viewObject {
  return [self activateObject:[self object] withVerb:@"view"];
}

/* accessors */

- (void)setBody:(id)_body {
  ASSIGN(self->body, _body);
}
- (void)setPartOfBody:(id)_part {
  ASSIGN(self->partOfBody, _part);    
}

- (void)setInlineLink:(BOOL)_lnk {
  self->inlineLink = _lnk;
}
- (BOOL)inlineLink {
  return self->inlineLink;
}

- (void)setShowDirectActionLink:(BOOL)_lnk {
  self->showDirectActionLink = _lnk;
}
- (BOOL)showDirectActionLink {
  return self->showDirectActionLink;
}

- (void)setIsInForm:(BOOL)_form {
  self->isInForm = _form;
}
- (BOOL)isInForm {
  return self->isInForm;
}

- (void)setAttachData:(BOOL)_data {
  self->attachData = _data;
}
- (BOOL)attachData {
  return self->attachData;
}

@end /* LSWObjectMailPage */
