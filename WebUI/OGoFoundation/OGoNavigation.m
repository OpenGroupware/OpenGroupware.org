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

#include "OGoNavigation.h"
#include "OGoSession.h"
#include "OGoContentPage.h"
#include "OGoViewerPage.h"
#include "OWPasteboard.h"
#include "common.h"

@implementation OGoNavigation

static BOOL debugNavigation = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  debugNavigation = [ud boolForKey:@"OGoDebugNavigation"];
}

- (id)initWithSession:(OGoSession *)_sn {
  self->session = _sn;
  
  self->pages.index = 0;
  self->pages.count = 0;
  self->pages.size  = 5;
  self->pages.elements = calloc(self->pages.size, sizeof(id));
  
  return self;
}
- (id)init {
  return [self initWithSession:nil];
}

- (void)dealloc {
  int i;
  
  if (self->pages.elements) {
    for (i = 0; i < self->pages.size; i++)
      [self->pages.elements[i] release];
    
    free(self->pages.elements);
  }
  [super dealloc];
}

/* pages */

- (void)push:(OGoContentPage *)_page {
  if (_page == nil) {
    [self->session debugWithFormat:@"tried to add <nil> page !"];
    return;
  }
  
  (self->pages.index)++;
  if (self->pages.index >= self->pages.size)
    self->pages.index = 0;

  if (self->pages.elements[self->pages.index]) {
    /* a page fell out of the navigation (max capacity was exceeded) */
    [self->pages.elements[self->pages.index] release];
    self->pages.elements[self->pages.index] = nil;
  }
  else {
    (self->pages.count)++;
  }
  
  self->pages.elements[self->pages.index] = RETAIN(_page);
  
  if (debugNavigation) {
    [self debugWithFormat:@"pushed page %@ at %i (count=%i)",
	  [_page name], self->pages.index, self->pages.count];
  }
}
- (OGoContentPage *)pop {
  OGoContentPage *old;

  if ((old = self->pages.elements[self->pages.index])) {
    self->pages.elements[self->pages.index] = nil;
    self->pages.index--;
    if (self->pages.index < 0)
      self->pages.index = (self->pages.size - 1);
    self->pages.count--;
  }
  return [old autorelease];
}

- (id)activePage {
  if (debugNavigation) {
    [self->session logWithFormat:@"active page is %@",
         [self->pages.elements[self->pages.index] name]];
  }
  return self->pages.elements[self->pages.index];
}

- (NSArray *)pageStack {
  id  objects[self->pages.count + 1];
  int i, j;

  if (self->pages.count == 0)
    return [NSArray array];

  for (i = self->pages.index, j = (self->pages.count - 1); j >= 0; j--) {
    NSAssert4(self->pages.elements[i],
              @"empty element at %i (idx=%i, count=%i, j=%i)",
              i, self->pages.index, self->pages.count, j);
    
    objects[j] = self->pages.elements[i];
    
    i--;
    if (i < 0)
      i = (self->pages.size - 1);
  }
  
  return [NSArray arrayWithObjects:objects count:self->pages.count];
}
- (BOOL)containsPages {
  return self->pages.count > 0 ? YES : NO;
}

/* actions */

- (void)showMasterPage:(NSString *)_name {
  /* TODO: can be removed? */
  id newPage  = nil;
  
  [self logWithFormat:@"WARNING: calling deprecated %@ ..", 
  	  NSStringFromSelector(_cmd)];

  if (debugNavigation)
    [self->session logWithFormat:@"create and show page %@", _name];

  newPage = [[WOApplication application]
                            pageWithName:_name
                            inContext:[self->session context]];

  if (newPage) {
    [self enterPage:newPage];
    return;
  }

  [self->session debugWithFormat:@"couldn't create page %@", _name];
}

- (void)enterPage:(id)_page {
  OGoContentPage *actPage;
  
  actPage = self->pages.elements[self->pages.index];
  
  if (debugNavigation) {
    [self->session debugWithFormat:@"enter page %@ (current=%@)",
                     [(WOComponent *)_page name], [actPage name]];
  }
  
  if (_page == nil) {
    [self->session logWithFormat:@"WARNING: tried to enter <nil> page !"];
    return;
  }

  if (_page != actPage)
    [self push:_page];

  if (self->pages.count == 0)
    [self->session debugWithFormat:@"no pages in navigation .."];
}

- (id)leavePage {
  OGoContentPage *page = nil;
  
  if (self->pages.count < 2) {
    [self->session debugWithFormat:
	   @"WARNING: no page to leave (%i pages active) ..", 
	   self->pages.count];
    return nil;
  }
  
  page = [self pop];
  if (debugNavigation)
    [self->session logWithFormat:@"left page %@", [page name]];
  return page;
}

/* WOActionResults */

- (WOResponse *)generateResponse {
  return [[self activePage] generateResponse];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugNavigation;
}

@end /* OGoNavigation */

@implementation OGoNavigation(Activation)

- (BOOL)executePasteboardCommand:(NSString *)_command {
  /* TODO: split up this big method */
  OWPasteboard *pb;
  NSArray      *types;
  unsigned     i, count;
  id page;

  pb    = [self->session transferPasteboard];
  types = [pb types];
  count = [types count];
  
  if ([_command isEqualToString:@"view"]) {
    OGoContentPage *page;
    
    page = [self activePage];
    
    if ([page respondsToSelector:@selector(isViewerForSameObject:)]) {
      if ([page isViewerForSameObject:[self->session getTransferObject]])
        return YES;
    }
  }

  for (i = 0; i < count; i++) {
    NGMimeType  *type;
    WOComponent *component;
    
    type      = [types objectAtIndex:i];
    component =
      [self->session instantiateComponentForCommand:_command
           type:type object:[self->session getTransferObject]];
    
    if (component) {
      if (![component conformsToProtocol:@protocol(OGoContentPage)]) {
        [self->session logWithFormat:
             @"WARNING: command component %@ is not a content page !",
             component];
      }

      [self enterPage:(id)component];
      return YES;
    }
  }
  [self->session logWithFormat:
       @"WARNING: Could not execute command %@ for types %@",
       _command, [pb types]];

  page = [self activePage];
  if ([[page errorString] length] < 1) {
    NSString *error;
    
    error = @"Could not execute command %@ for types: %@";
    error = [NSString stringWithFormat:error, _command,
                        [[pb types] componentsJoinedByString:@", "]];
    [page setErrorString:error];
  }
  
  return NO;
}

- (id)handleActivationErrorForObject:(id)_object withVerb:(NSString *)_verb {
  NSString *error;
  id page;
    
  page = [[self->session context] page];
    
  error = [NSString stringWithFormat:@"no object available for %@ operation",
		      _verb];
  [page takeValue:error forKey:@"errorString"];
    
  [self->session logWithFormat:
         @"cannot activate 'nil' object with verb '%@' !", _verb];
  return page;
}

- (id)activateObject:(id)_object withVerb:(NSString *)_verb {
  if ([_verb length] == 0)
    _verb = @"view";
  
  if (_object == nil)
    return [self handleActivationErrorForObject:_object withVerb:_verb];
  
  [self->session transferObject:_object owner:nil];
  [self executePasteboardCommand:_verb ? _verb : @"view"];
  return [self activePage];
}

@end /* OGoNavigation(Activation) */

/* for compatibility, to be removed */
@implementation LSWNavigation
@end /* LSWNavigation */
