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

#include "OGoViewerPage.h"
#include "WOSession+LSO.h"
#include "WOComponent+config.h"
#include "WOComponent+Commands.h"
#include "LSWMailEditorComponent.h"
#include "common.h"
#import <EOControl/EOGlobalID.h>

@interface NSObject(GlobalID)
- (EOGlobalID *)globalID;
@end

@implementation OGoViewerPage

+ (int)version {
  return [super version] - 1;
}
+ (void)initialize {
  NSAssert2([super version] == 3,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->activationCommand release];
  [self->object            release];
  [super dealloc];
}

- (void)clearViewer {
  [self->object            release]; self->object            = nil;
  [self->activationCommand release]; self->activationCommand = nil;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(id)_cfg
{
  [self clearViewer];
  self->activationCommand = [_command copy];
  
  if ((self->object = [[[self session] getTransferObject] retain]) == nil) {
    [self setErrorString:@"No object in transfer pasteboard !"];
    return NO;
  }
  return YES;
}

/* object */

- (void)setObject:(id)_object {
  ASSIGN(self->object, _object);  
}
- (id)object {
  return self->object;
}

- (NSString *)objectLabel {
  NSString *s;
  id obj;
  
  obj = [self object];
  if (![obj isNotNull]) {
    [self debugWithFormat:@"Note: missing object for viewer!"];
    return nil;
  }
  s = [[self existingSession] labelForObject:obj];
  if ([s length] == 0) {
    [self debugWithFormat:@"Note: got no label for object: %@(%@)",
            obj, NSStringFromClass([obj class])];
    return nil;
  }
  return s;
}

/* content page */

- (NSString *)label {
  // TODO: should be implemented as a formatter? See SkyNavigation.m.
  NSString *label, *olabel;
  
  label  = [super label];
  olabel = [self objectLabel];
  if ([olabel length] == 0) {
    [self debugWithFormat:@"Note: viewer page has no object label!"];
    return label;
  }
  
  return [label stringByAppendingFormat:@" (%@)", olabel];
}

- (BOOL)isViewerForSameObject:(id)_object {
  if ([self object] == _object)
    return YES;

  if ([[self object] respondsToSelector:@selector(globalID)]) {
    if ([[[self object] globalID] isEqual:_object])
      return YES;
  }
  
  return NO;
}

/* common actions */

- (id)placeInClipboard {
  id favorite;

  favorite = nil;
#if 0
  if ([[self object] respondsToSelector:@selector(globalID)])
    favorite = [[self object] globalID];
#endif
  if (favorite == nil)
    favorite = [self object];

  if (favorite == nil) {
    [self setErrorString:@"No object to place in clipboard !"];
    return nil;
  }
  
  [[self session] addFavorite:favorite];
  return nil;
}

- (id)edit {
  return [self activateObject:[self object] withVerb:@"edit"];
}
- (id)mail {
  return [self activateObject:[self object] withVerb:@"mail"];
}

/* mail */
// TODO: all that mail stuff does not really belong into this object,
//       should be an own object (something like 'ObjectMailerAction')

- (BOOL)isExternalMailer {
  NSString *type = [[[self session] userDefaults]
                           objectForKey:@"mail_editor_type"];
  return (type == nil)
    ? YES
    : [type isEqualToString:@"external"];
}

- (void)modifyMailEditor:(id)_mailEditor {
}

- (NSString *)mailSignature {
  return [[[self session] userDefaults] objectForKey:@"signature"];
}

- (id)missingEntityOfObjectPage:(id)_obj {
  /* TODO: localize */
  NSString *fmt;
  
  fmt = [NSString stringWithFormat:
                      @"ERROR (please report): couldn't get entity of object "
                      @"0x%08X<%@>: %@",
                      _obj, NSStringFromClass([_obj class]),
                      _obj];
  [self setErrorString:fmt];
  return nil;
}

- (id)mailObject {
  /* TODO: split up this big method .. */
  static Class docClass = Nil;
  id<LSWMailEditorComponent> mailEditor;
  id         obj;
  NSString   *str  = nil;
  NGMimeType *type = nil;
  id         mail  = nil;
  id         entity;
  NSString   *sign;
  
  mailEditor = (id)[[self application] pageWithName:@"LSWImapMailEditor"];
  if (mailEditor == nil) {
    [self logWithFormat:@"ERROR: missing LSWImapMailEditor component !"];
    [self setErrorString:@"missing mail-editor component !"];
    return nil;
  }
  if ((obj = [self object]) == nil) {
    [self logWithFormat:@"ERROR: missing object in viewer component !"];
    [self setErrorString:@"missing object in viewer component !"];
    return nil;
  }
  
  /* check if the object is a document and turn it into an EO if possible */
  
  if (docClass == Nil)
    docClass = NSClassFromString(@"SkyDocument");
  if ([obj isKindOfClass:docClass]) {
    EOGlobalID   *gid;
    id           tmp;
    
    gid = [obj valueForKey:@"globalID"];
    
    if ([gid isNotNull]) {
      tmp = [[self runCommand:@"object::get-by-globalid", @"gid", gid, nil]
                   lastObject];
      
      if (tmp != nil) {
        obj = tmp;
      }
      else
        [self logWithFormat:@"WARNING: could not get object for gid: %@",gid];
    }
    else
      [self logWithFormat:@"WARNING: document has no globalID: %@!", obj];
  }
  
  if ((mail = [[self config] valueForKey:@"mail"])) {
    if ([(str = [mail valueForKey:@"subject"]) isNotNull])
      [mailEditor setSubject:str];
    
    if ([(str = [mail valueForKey:@"content"]) isNotNull])
      str = [str stringValue];
    else
      str = @"";
  }
  else {
    str = @"";
  }

  /* add signature if available */
  
  if ((sign = [self mailSignature])) {
    str = [[str stringByAppendingString:@"\n-- \n"] 
                stringByAppendingString:sign];
  }

  /* set content in mail editor */
  [mailEditor setContent:str];

  /* attach object */
  
  entity = [obj respondsToSelector:@selector(entity)]
    ? [obj entity]
    : [obj valueForKey:@"entity"];
  
  if (entity == nil)
    return [self missingEntityOfObjectPage:obj];
  
  type = [NGMimeType mimeType:@"eo" 
		     subType:[[(EOEntity *)entity name] lowercaseString]];
  [mailEditor addAttachment:obj type:type];

  /* apply final patches to editor */
  [self modifyMailEditor:mailEditor];
  
  return mailEditor;
}

- (NSString *)objectUrlKey {
  [self logWithFormat:@"WARNING(%s): subclass should override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (NSString *)objectUrl {
  WOContext *ctx       = [self context];
  NSString  *urlPrefix = nil;
  NSString  *url       = nil;
  
  urlPrefix = [ctx urlSessionPrefix];
  url       = [[ctx request] headerForKey:@"x-webobjects-server-url"];
  
  if ([url length] > 0) {
    urlPrefix = [NSString stringWithFormat:@"mailto:?body=%@%@/%@",
                            url, urlPrefix,
                            [self objectUrlKey]];
  }
  else {
#if DEBUG
    NSAssert([urlPrefix length] > 0, @"invalid url prefix !");
#endif
    urlPrefix = [NSString stringWithFormat:@"mailto:?body=http://%@%@/%@",
                            [[ctx request] headerForKey:@"host"],
                            urlPrefix,
                            [self objectUrlKey]];
  }
  return urlPrefix;
}

@end /* OGoViewerPage */

@implementation OGoContentPage(Viewing)

- (BOOL)isViewerForSameObject:(id)_object {
  return NO;
}

@end /* OGoContentPage(Viewing) */

/* for compatibility, to be removed */
@implementation LSWViewerPage
@end /* LSWViewerPage */
