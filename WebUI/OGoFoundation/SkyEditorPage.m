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

#include <OGoFoundation/SkyEditorPage.h>
#include <OGoFoundation/WOSession+LSO.h>
#include <OGoFoundation/WOComponent+Commands.h>
#include <OGoFoundation/SkyWizard.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/SkyEditorComponent.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoDocuments/SkyDocument.h>
#import "common.h"

#define SkySubEditors @"SkyEditor_SubEditors"

@interface SkyEditorPage(PrivateMethods)
- (BOOL)_performSubEditorSel:(SEL)_selector;
- (NSNumber *)objectVersion;
@end

@implementation SkyEditorPage

static NSArray *objVersionName = nil;

+ (int)version {
  return [super version] /* v3 */;
}
+ (void)initialize {
  NSAssert2([super version] == 3,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);

  if (objVersionName == nil)
    objVersionName = [[NSArray alloc] initWithObjects:@"objectVersion",nil];
}

- (void)dealloc {
  [self->document    release];
  [self->windowTitle release];
  [self->subEditors  release];
  [super dealloc];
}

/* operations */

- (void)clearEditor {
  [self->document release]; self->document = nil;
  [self setIsInWarningMode:NO];
}

- (BOOL)prepareForNewCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  //[self logWithFormat:@"%@ ..", NSStringFromSelector(_cmd)];
  return YES;
}
- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  //[self logWithFormat:@"%@ ..", NSStringFromSelector(_cmd)];
  return YES;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cfg
{
  [self clearEditor];
  
  if ((self->isInNewMode = [_command hasPrefix:@"new"])) {
    SkyDocument *doc;
    LSCommandContext *ctx;
    
    ctx = [(OGoSession *)[self session] commandContext];
    // TODO: fix typing
    doc = [(SkyAccessManager *)[NSClassFromString([_type subType]) alloc] 
			       initWithContext:ctx];
    [self setObject:doc];
    [doc release]; doc = nil;
    return [self prepareForNewCommand:_command
		 type:_type
		 configuration:nil];
  }
  
  if ((self->document = [[[self session] getTransferObject] retain])) {
    return [self prepareForEditCommand:_command type:_type
		 configuration:nil];
  }
  
  [self setErrorString:@"No object in transfer pasteboard !"];
  return NO;
}

/* object */

- (void)setIsInNewMode:(BOOL)_status {
  self->isInNewMode = _status;
}

- (BOOL)isInNewMode {
  return self->isInNewMode;
}

- (void)setObject:(id)_object {
  ASSIGN(self->document, _object);
}
- (id)object {
  return self->document;
}

- (NSString *)objectLabel {
  NSString *l;
  id obj;

  if ((obj = [self object]))
    return [[self session] labelForObject:obj];
  if (!self->isInNewMode)
    return nil;
  
  l = [[self labels] valueForKey:@"new"];
  return (l != nil) ? l : @"new";
}

/* content page */

- (NSString *)label {
  NSString *label = [super label];
  return [NSString stringWithFormat:@"%@ (%@)", label, [self objectLabel]];
}

- (BOOL)isDeleteDisabled {
  return self->isInNewMode ? YES : NO;
}

/* constraints */

- (BOOL)checkConstraintsForSave {
  NSNumber   *objVers = nil;
  EOGlobalID *gid     = nil;
  NSNumber *newVers;
  NSString *str;
  id       labels;
  
  if (![self _performSubEditorSel:@selector(checkConstraintsForSave)])
    return NO;
  
  if ([self->document respondsToSelector:@selector(objectVersion)]) {
    objVers = [(id)self->document objectVersion];
    gid     = [self->document globalID];
  }
  
  if (!(objVers != nil && gid != nil)) // document is new
    return YES;
  
  /* document is not new */
  
  newVers = [[[self runCommand:@"object::get-by-globalid",
                    @"gid", gid,
                    @"attributes", objVersionName,
                    nil] lastObject] valueForKey:@"objectVersion"];

  if (newVers == nil) {
    [self logWithFormat:@"WARNING(%s): Cannot check objectVersion", 
	  __PRETTY_FUNCTION__];
    return YES;
  }
  if ([newVers isEqual:objVers])
    return YES;
  
  /* TODO: simplify the following section? */
  labels = [self labels];
  
  str = [labels valueForKey:@"version_changed"];
  str = [str stringByAppendingString:[objVers stringValue]];
  str = [str stringByAppendingString:
                   [labels valueForKey:@"version_current"]];
  str = [str stringByAppendingString:[newVers stringValue]];
  str = [str stringByAppendingString:@"\n"];
  str = [str stringByAppendingString:
                   [labels valueForKey:@"version_save_anyway"]];
  [self takeValue:str                forKey:@"confirmString"];
  [self takeValue:@"reallyOverwrite" forKey:@"confirmAction"];
      
  return NO;
}
- (BOOL)checkConstraintsForDelete {
  return [self _performSubEditorSel:@selector(checkConstraintsForDelete)];
}
- (BOOL)checkConstraintsForCancel {
  return [self _performSubEditorSel:@selector(checkConstraintsForCancel)];
}

/* actions */

- (id)_saveDocumentAndGoBackWithCount:(int)_backCount {
  if (![self->document save]) {
    [self setErrorString:@"Unknown error. Could not save document!"];
    return nil;
  }

  if ([self->document reload])
    return [self backWithCount:_backCount];
  
  return nil;
}

- (id)reallyOverwrite {
  [self takeValue:@"" forKey:@"confirmString"];
  [self takeValue:@"" forKey:@"confirmAction"];
  return [self _saveDocumentAndGoBackWithCount:1];
}

- (id)saveAndGoBackWithCount:(int)_backCount {
  if (![self checkConstraintsForSave]) {
    [self debugWithFormat:@"save constraint check failed !"];
    return nil;
  }
  
  if (![self _performSubEditorSel:@selector(save)]) {
    [self debugWithFormat:@"could not save in subeditors!"];
    return nil;
  }

  return [self _saveDocumentAndGoBackWithCount:_backCount];
}

- (id)deleteAndGoBackWithCount:(int)_backCount {
  [self setIsInWarningMode:NO];
  
  if (![self checkConstraintsForDelete])
    return nil;
  
  if (self->isInNewMode) {
    [self setErrorString:@"Cannot delete in new mode !"];
    return nil;
  }

  if (![self _performSubEditorSel:@selector(delete)]) {
    [self debugWithFormat:@"could not save in subeditors!"];
    return nil;
  }
  
  if ([self->document delete])
    return [self backWithCount:_backCount];
  else
    [self setErrorString:
          @"Cannot delete this object!\n"
          @"(Maybe it's still assigned to other objects)"];

  [self debugWithFormat:@"couldn't delete object... "];
  return nil;
}

- (id)cancel {
  if (![self checkConstraintsForCancel]) {
    return nil;
  }

  if (![self _performSubEditorSel:@selector(cancel)]) {
    [self debugWithFormat:@"could not cancel in subeditors!"];
    return nil;
  }
  
  if ([self->document reload])
    return [self back];

  [self debugWithFormat:@"couldn't cancel editor... "];
  return nil;
}

- (id)cancelDelete {
  [self setIsInWarningMode:NO];
  return nil;
}

- (id)save {
  return [self saveAndGoBackWithCount:1];
}

- (id)delete {
  [self setWarningOkAction:@"reallyDelete"];
  [self setWarningPhrase:@"Really Delete"];
  [self setIsInWarningMode:YES];
  
  return nil;
}

- (id)reallyDelete {
  return [self deleteAndGoBackWithCount:2];
}

/* page actions */

- (id)placeInClipboard {
  [[self session] placeInClipboard:[self object]];
  return nil;
}

- (id)view {
  return [self activateObject:[self object] withVerb:@"view"];
}

- (NSString *)windowTitle {
  return self->windowTitle;
}
- (void)setWindowTitle:(NSString *)_title {
  ASSIGN(self->windowTitle, _title);
}

- (NSString *)windowTitleLabel {
  NSString *label = nil;
  NSString *title = nil;

  if ((title = [self windowTitle]) == nil)
    title = @"-- no windowtitle --";
  
  label = [[self labels] valueForKey:title];
  return (label != nil) ? label : title;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [_ctx setObject:[NSMutableArray arrayWithCapacity:8] forKey:SkySubEditors];
        
  [super appendToResponse:_response inContext:_ctx];
  [self->subEditors release]; self->subEditors = nil;
  self->subEditors = [[_ctx objectForKey:SkySubEditors] retain];
  [_ctx removeObjectForKey:SkySubEditors];
}

@end /* SkyEditorPage */

@implementation SkyEditorPage(PrivateMethodes)

- (BOOL)_performSubEditorSel:(SEL)_selector {
  NSEnumerator       *subEnum = [self->subEditors objectEnumerator];
  BOOL               status   = YES;
  SkyEditorComponent *sub;

  while ((sub = [subEnum nextObject])) {
    if ([sub respondsToSelector:_selector])
      status = status && [sub performSelector:_selector];
  }
  return status;
}

@end /* SkyEditorPage(PrivateMethodes) */

@implementation NSObject(SkyEditorPageTyping)

- (BOOL)isEditorPage {
  return NO;
}

@end /* NSObject(SkyEditorPageTyping) */

@implementation SkyEditorPage(SkyEditorPageTyping)

- (BOOL)isEditorPage {
  return YES;
}

@end /* SkyEditorPage(SkyEditorPageTyping) */
