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

#include "LSWPartBodyViewer.h"
#include "common.h"

@interface NSObject(Private)
- (id)viewerComponentForPart:(id)_id;
- (void)addReceiver:(id)_id type:(NSString *)_type;
- (void)setContentWithoutSign:(NSString *)_content;
- (void)setMimeType:(id)_t;
@end

@implementation LSWPartBodyViewer

- (void)dealloc {
  [self->body       release];
  [self->partOfBody release];
  [self->source     release];
  [super dealloc];
}


- (void)sleep {
  [super sleep];
  ASSIGN(self->body,       nil);
  ASSIGN(self->partOfBody, nil);
  ASSIGN(self->source,     nil);
}

/* activation */

- (BOOL)isDownloadable {
  return NO;
}

- (id)activateObject:(id)_obj verb:(NSString *)_verb type:(NGMimeType *)_type {
  if ([self respondsToSelector:@selector(setMimeType:)])
    [(id)self setMimeType:_type];
  
  [self setBody:_obj];
  self->printMode = NO;
  return self;
}

/* accessors */

- (void)setNestingDepth:(int)_depth {
  self->nestingDepth = _depth;
}
- (int)nestingDepth {
  return self->nestingDepth;
}
- (int)nextNestingDepth {
  return (self->nestingDepth + 1);
}

- (void)setBody:(id)_body {
  ASSIGN(self->body, _body);
}
- (id)body {
  return self->body;
}

- (BOOL)printMode {
  return self->printMode;
}
- (void)setPrintMode:(BOOL)_print {
  self->printMode = _print;
}

- (void)setPartOfBody:(id)_part {
  id tmp = self->partOfBody;
  self->partOfBody = RETAIN(_part);
  RELEASE(tmp);
}
- (id)partOfBody {
  return self->partOfBody;
}

- (void)setSource:(id)_source {
  ASSIGN(self->source, _source);
}
- (id)source {
  return self->source;
}


- (BOOL)hasUrl {
  return [self->body isKindOfClass:[NSURL class]];
}

- (id)downloadPartActionName {
  NSString *name;

  if ((name = [[[partOfBody contentType] parametersAsDictionary]
                            objectForKey:@"name"])) {
    return [NSString stringWithFormat:@"get/%@", name];
  }
  else {
    int static CreateMailDownloadFileNamesDisable = -1;

    if (CreateMailDownloadFileNamesDisable == -1) {
      CreateMailDownloadFileNamesDisable =
        [[NSUserDefaults standardUserDefaults]
                         boolForKey:@"CreateMailDownloadFileNamesDisable"]?1:0;
    }
    if (CreateMailDownloadFileNamesDisable)
      return @"get";
    else
      return [NSString stringWithFormat:@"get/download.%@",
                       [[partOfBody contentType] subType]];
  }
}
- (NSString *)url {
  return [self->body absoluteString];
}
- (NSString *)mimeTypeString {
  return [[self->partOfBody contentType] stringValue];
}

- (NSString *)encoding {
  return [[self->partOfBody encoding] stringValue];
}

- (NSString *)partUrl {
  return [self->body query];
}

- (NSDictionary *)bodyDescription {
  NSString *name, *bodyKey;
  

  name = [[[self->partOfBody contentType] parametersAsDictionary]
                       objectForKey:@"name"];


  bodyKey = ([self hasUrl]) ? @"url" : @"data";

  return [NSDictionary dictionaryWithObjectsAndKeys:
                       [self body], bodyKey,
                       [self mimeTypeString], @"mimeType",
                       [self encoding], @"encoding",
                       name, @"name", nil];
}


@end /* LSWPartBodyViewer */

@implementation LSWAppOctetBodyViewer
- (BOOL)isDownloadable {
  return YES;
}
@end /* LSWAppOctetBodyViewer */

@implementation LSWMultipartBodyViewer

- (void)dealloc {
  [self->currentPart release];
  [super dealloc];
}

// notifications

// accessors

- (NSArray *)parts {
  if ([self->body isKindOfClass:[NSURL class]]) {
    NGMimeBodyPart   *p;
    NGMutableHashMap *map;

    map = [[[NGMutableHashMap alloc] init] autorelease];
    [map setObject:@"text/plain" forKey:@"content-type"];
    p = [NGMimeBodyPart bodyPartWithHeader:map];
    [p setBody:self->body];
    return [NSArray arrayWithObject:p];
  }
  return [self->body parts];
}

- (void)setCurrentPart:(id)_part {
  ASSIGN(self->currentPart, _part);
}
- (id)currentPart {
  return self->currentPart;
}

- (WOComponent *)currentPartViewerComponent {
  id p;

  p = [self pageWithName:
            [[self session] viewerComponentForPart:[self currentPart]]];

  [p setSource:[self source]];
  
  return p;
}

@end /* LSWMultipartBodyViewer */

@implementation LSWMultipartMixedBodyViewer
@end /* LSWMultipartMixedBodyViewer */


@implementation LSWEnterpriseObjectBodyViewer
@end /* LSWEnterpriseObjectBodyViewer */
