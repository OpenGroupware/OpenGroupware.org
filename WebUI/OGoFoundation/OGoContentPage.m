/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include "OGoContentPage.h"
#include "WOComponent+config.h"
#include "WOSession+LSO.h"
#include "LSWConfigHandler.h"
#include "OGoNavigation.h"
#include "OGoViewerPage.h"
#include "LSWMimeContent.h"
#include "WOComponent+Commands.h"
#include "common.h"

@interface WOSession(ChangeNotificationSystem)

- (void)addObserver:_observer selector:(SEL)_sel
  name:(NSString*)_notificationName object:(id)_object;
- (void)removeObserver:(id)_observer name:(NSString*)_notiName object:_obj;
- (void)removeObserver:(id)_observer;

@end

@interface OGoContentPage(PrivateMethods)
- (id)downloadAttachmentForType:(NSString *)_type pkey:(id)_pkey
  inContext:(WOContext *)_ctx;
@end

@implementation OGoContentPage

+ (int)version {
  return [super version] + 1 /* v3 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->errorString     release];
  [self->warningOkAction release];
  [self->warningPhrase   release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self setErrorString:nil];
  [super sleep];
}

- (void)noteChange:(NSString *)_changeName onObject:(id)_object {
}

- (void)postChange:(NSString *)_changeName onObject:(id)_object {
  NSEnumerator   *mp;
  OGoContentPage *p;
  
  mp = [[[self navigation] pageStack] reverseObjectEnumerator];
  while ((p = [mp nextObject]) != nil) {
    if ([p respondsToSelector:@selector(noteChange:onObject:)])
      [p noteChange:_changeName onObject:_object];
  }
  
  [[self session] postChange:_changeName onObject:_object];
}

- (void)postChange:(NSString *)_changeName {
  [self postChange:_changeName onObject:nil];
}

- (void)notificationBroker:(NSNotification *)_notification {
  [self noteChange:[_notification name] onObject:[_notification object]];
}

- (void)registerForNotificationNamed:(NSString *)_notificationName
  object:(id)_object
{
  // TODO: why is this commented out? Its used in e.g. LSWStaff.
#if 0
  [[self session] addObserver:self
                  selector:@selector(notificationBroker:)
                  name:_notificationName
                  object:_object];
#endif
}
- (void)registerForNotificationNamed:(NSString *)_notificationName {
  [self registerForNotificationNamed:_notificationName object:nil];
}
- (void)unregisterAsObserver {
#if 0
  [[self session] removeObserver:self];
#endif
}

/* accessors */

- (BOOL)isContentPage {
  return YES;
}

- (OGoNavigation *)navigation {
  return [[self session] navigation];
}

- (id)master {
  [self warnWithFormat:@"-master was called, returning self"];
  return self;
}

- (NSString *)label {
  NSString *label;
  
  if ((label = [[self labels] valueForKey:[self name]]) != nil)
    return label;
  
  return [self name];
}

- (void)setIsInWarningMode:(BOOL)_isInWarningMode {
  self->isInWarningMode = _isInWarningMode;
}
- (BOOL)isInWarningMode {
  return self->isInWarningMode;
}

- (void)setWarningPhrase:(NSString *)_phrase {
  ASSIGN(self->warningPhrase, _phrase);
}
- (NSString *)warningPhrase {
  return self->warningPhrase;
}

- (void)setWarningOkAction:(NSString *)_warningOkAction {
  ASSIGN(self->warningOkAction, _warningOkAction);
}
- (NSString *)warningOkAction {
  return self->warningOkAction;
}

// component activation

- (BOOL)executePasteboardCommand:(NSString *)_command {
  [[self navigation]
         activateObject:[[self session] getTransferObject]
         withVerb:_command];
  return YES;
}

/* page navigation */

- (BOOL)rollbackForPage:(id<OGoContentPage>)_page {
  return YES;
}

/* errors */

- (void)setErrorString:(NSString *)_error {
  ASSIGNCOPY(self->errorString, _error);
}
- (NSString *)errorString {
  return self->errorString;
}
- (void)resetErrorString {
  [self setErrorString:nil];
}

- (BOOL)hasErrorString {
  return [self->errorString length] > 0 ? YES : NO;
}

@end /* OGoContentPage */

@implementation OGoContentPage(MasterPageStuff)

- (id)showClipboardContent {
  return [self activateObject:[[self session] objectInClipboard]
               withVerb:@"view"];
}

// direct actions

- (id)downloadAttachmentForType:(NSString *)_type pkey:(id)_pkey
  inContext:(WOContext *)_ctx
{
  NSString     *cmd       = nil;
  NSString     *keyAttr   = nil;
  id           obj        = nil;
  NSData       *data      = nil;
  NSString     *mType     = nil;
  NGMimeType   *mt        = nil;
  NSArray      *result    = nil;
  NSDictionary *mimeTypes = nil;
  
  mimeTypes = [[[self session] userDefaults] dictionaryForKey:@"LSMimeTypes"];

  if ([_type isEqualToString:@"doc"]) {
    cmd     = @"doc::get";
    keyAttr = @"documentId";
  }
  else if ([_type isEqualToString:@"documentversion"]) {
    cmd     = @"documentversion::get";
    keyAttr = @"documentVersionId";
  }
  else if ([_type isEqualToString:@"documentediting"]) {
    cmd     = @"documentediting::get";
    keyAttr = @"documentEditingId";
  }
  
  result = [self runCommand:cmd, keyAttr, _pkey, nil];

  if ([result count] == 1) {
    obj = [result lastObject];
    //NSLog(@"one document matched direct action query.");
  }
  else if ([result count] == 0) {
    NSLog(@"no document matched direct action query.");
    [self setErrorString:@"No entry matched URL query."];
  }
  else {
    NSLog(@"multiple documents matched direct action query.");
    obj = [result objectAtIndex:0];
  }

  if (obj != nil) {
    NSString *ext   = [obj valueForKey:@"fileType"];
    
    [self runCommand:[_type stringByAppendingString:@"::get-attachment-name"],
            @"object", obj, nil];
    
    data  = [NSData dataWithContentsOfFile:[obj valueForKey:@"attachmentName"]];
    mType = [mimeTypes valueForKey:ext];
  }

  if (data == nil) {
    NSString *s = @"no permission to get document!";
    
    data  = [s dataUsingEncoding:NSASCIIStringEncoding];
    mType = @"text/plain";
  }
  
  if (mType == nil) 
    mType = @"application/octet-stream";

  mt = [NGMimeType mimeType:mType];

  //NSLog(@"data is %i bytes (file=%@).",
  //      [data length], [obj valueForKey:@"attachmentName"]);

  return [LSWMimeContent mimeContent:data ofType:mt inContext:_ctx];
}

@end /* OGoContentPage(MasterPageStuff) */

@implementation NSObject(ContentPageTyping)

- (BOOL)isContentPage {
  return NO;
}

@end /* NSObject(ContentPageTyping) */

// hh(2024-09-25): I think setting those makes sense, if unset.
// OGo pages should *never* be cached, right?
// And while it may work w/ gstep-base, the HTTP parser used to have issues
// w/ keepalive?
// mod_ngobjweb used to deal with such things.
@implementation OGoContentPage(HTTPHeaders)
- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [super appendToResponse:_response inContext:_ctx];
  if ([_response headerForKey:@"Connection"] == nil) {
    [_response setHeader:@"Close" forKey:@"Connection"];
  }
  // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
  if ([_response headerForKey:@"Cache-Control"] == nil) {
    [_response setHeader:@"The no-store" forKey:@"Cache-Control"];
  }
}
@end

/* for compatibility, to be removed */
@implementation LSWContentPage
- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [super appendToResponse:_response inContext:_ctx];
  if ([_response headerForKey:@"Connection"] == nil) {
    [_response setHeader:@"Close" forKey:@"Connection"];
  }
  // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
  if ([_response headerForKey:@"Cache-Control"] == nil) {
    [_response setHeader:@"The no-store" forKey:@"Cache-Control"];
  }
}
@end /* LSWContentPage */
