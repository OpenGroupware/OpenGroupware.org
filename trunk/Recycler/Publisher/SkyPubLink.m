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

#include "SkyPubLink.h"
#include "SkyDocument+Pub.h"
#include "SkyPubFileManager.h"
#include "common.h"
#include <DOM/EDOM.h>
#include <NGObjDOM/ODNamespaces.h>

@interface NSString(MiscP)
- (BOOL)isAbsoluteURL;
@end

@implementation SkyPubLink

- (id)initWithNode:(id)_node manager:(SkyPubLinkManager *)_manager {
  self->node    = RETAIN(_node);
  self->manager = _manager;
  return self;
}
+ (id)linkWithNode:(id)_node manager:(SkyPubLinkManager *)_manager {
  if (_node == nil)
    return nil;
  
  return [[[self alloc] initWithNode:_node manager:_manager] autorelease];
}

- (void)dealloc {
  RELEASE(self->node);
  [super dealloc];
}

- (void)_resetManager {
  self->manager = nil;
}

/* accessors */

- (SkyPubFileManager *)fileManager {
  return [self->manager fileManager];
}

- (NSString *)linkAttribute {
  return nil;
}
- (NSString *)linkAttributeNamespace {
  return nil;
}

- (NSString *)linkValue {
  return [self->node
              attribute:[self linkAttribute]
              namespaceURI:[self linkAttributeNamespace]];
}

- (BOOL)isValid {
  return [[self->manager document] pubIsValidLink:[self linkValue]];
}
- (BOOL)isAbsoluteURL {
  return [[self linkValue] isAbsoluteURL];
}
- (BOOL)isAbsolutePath {
  return [[self linkValue] isAbsolutePath];
}

- (NSString *)linkType {
  return nil;
}
- (NSString *)linkTitle {
  return nil;
}

- (NSString *)relativeTargetPath {
  return [[self->manager document]
                         pubRelativeTargetPathForLink:[self linkValue]];
}
- (NSString *)absoluteTargetPath {
  return [[self->manager document]
                         pubAbsoluteTargetPathForLink:[self linkValue]];
}

- (EOGlobalID *)targetObjectIdentifier {
  NSString *value;
  
  if ((value = [self absoluteTargetPath]) == nil)
    return nil;
  
  return [[self fileManager] globalIDForPath:value];
}
- (SkyDocument *)targetDocument {
  NSString *path;
  id doc;
  
  path = [self absoluteTargetPath];
  
  if ((doc = [[self fileManager] documentAtPath:path]) == nil)
    return nil;

  return doc;
}

- (NSString *)targetTitle {
  return [[self targetDocument] valueForKey:@"NSFileSubject"];
}

- (NSString *)targetReleaseState {
  return nil;
}

/* equality */

- (unsigned)hash {
  return (unsigned)self->node;
}

- (BOOL)isEqualToLink:(SkyPubLink *)_other {
  if (_other->manager != self->manager) return NO;
  if (_other->node    != self->node)    return NO;
  return YES;
}

- (BOOL)isEqual:(id)_other {
  if (_other == self) return YES;
  if ([_other isKindOfClass:[SkyPubLink class]])
    return [self isEqualToLink:_other];
  return NO;
}

@end /* SkyPubLink */

@implementation SkyPubAnkerLink

- (NSString *)linkType {
  return @"document anker";
}

- (NSString *)linkAttribute {
  return @"href";
}
- (NSString *)linkAttributeNamespace {
  return XMLNS_XHTML;
}

@end /* SkyPubAnkerLink */

@implementation SkyPubInputLink

- (NSString *)linkType {
  return @"image submit button";
}

- (NSString *)linkAttribute {
  return @"src";
}
- (NSString *)linkAttributeNamespace {
  return XMLNS_XHTML;
}

@end /* SkyPubAnkerLink */

@implementation SkyPubLinkLink

- (NSString *)linkType {
  return @"document link";
}

- (NSString *)linkAttribute {
  return @"href";
}
- (NSString *)linkAttributeNamespace {
  return XMLNS_XHTML;
}

@end /* SkyPubLinkLink */

@implementation SkyPubImgLink

- (NSString *)linkType {
  return @"document image";
}

- (NSString *)linkAttribute {
  return @"src";
}
- (NSString *)linkAttributeNamespace {
  return XMLNS_XHTML;
}

@end /* SkyPubImgLink */

@implementation SkyPubScriptLink

- (NSString *)linkType {
  return @"document script";
}

- (NSString *)linkAttribute {
  return @"src";
}
- (NSString *)linkAttributeNamespace {
  return XMLNS_XHTML;
}

@end /* SkyPubScriptLink */

@implementation SkyPubBGImgLink

- (NSString *)linkType {
  return @"background image";
}

- (NSString *)linkAttribute {
  return @"background";
}
- (NSString *)linkAttributeNamespace {
  return XMLNS_XHTML;
}

@end /* SkyPubBGImgLink */

@implementation SkyPubFormLink

- (NSString *)linkType {
  return @"form action";
}

- (NSString *)linkAttribute {
  return @"action";
}
- (NSString *)linkAttributeNamespace {
  return XMLNS_XHTML;
}

@end /* SkyPubFormLink */

@implementation SkyPubXLink

- (NSString *)linkType {
  return [NSString stringWithFormat:@"document %@ XLink",
                     [self->node attribute:@"type" namespaceURI:XMLNS_XLINK]];
}

- (NSString *)linkTitle {
  return [self->node attribute:@"title" namespaceURI:XMLNS_XLINK];
}

- (NSString *)linkAttribute {
  return @"href";
}
- (NSString *)linkAttributeNamespace {
  return XMLNS_XLINK;
}

@end /* SkyPubXLink */
