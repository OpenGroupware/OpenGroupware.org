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

#include "SkyWizard.h"
#include "OGoNavigation.h"
#include "OGoSession.h"
#include "OGoEditorPage.h"
#include "common.h"

@implementation SkyWizard

+ (id)wizardWithSession:(id)_session {
  return [[(SkyWizard *)[self alloc] initWithSession:_session] autorelease];
}

- (id)initWithSession:(id)_session {
  if ((self = [super init])) {
    self->step        = 0;
    self->objects     = [[NSMutableArray alloc] initWithCapacity:64];
    self->pageCache   = [[NSMutableArray alloc] initWithCapacity:64];
    self->session     = _session;
    self->stepForward = NO;
  }
  return self;
}

- (void)dealloc {
  [self->objects         release];
  [self->pageCache       release];
  [self->choosenPageName release];
  [self->labels          release];
  self->session   = nil;
  self->parent    = nil;
  self->startPage = nil;
  [super dealloc];
}

/* accessors */

- (int)maxSteps {
  [self logWithFormat:@"ERROR(%s): subclass should override this method!",
	  __PRETTY_FUNCTION__];
  return 0;
}

/* operations */

- (id)doStep:(int)_step withObject:(id)_obj {
  [self logWithFormat:@"ERROR(%s): subclass should override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

/* actions */

- (id)start {
  self->step        = 0;
  self->stepForward = YES;
  return [self doStep:0 withObject:nil];
}

- (id)forwardCached:(BOOL)_cached {
  id obj = nil;
  self->stepForward = YES;
  
  if (self->step >= ([self maxSteps] - 1)) {
    [self logWithFormat:@"WARNING: inconsistence state -> to much steps"];
    return nil;
  }
  
  self->step++;
  if (_cached) {
    if ((int)[self->objects count] > self->step)
      obj = [self->objects objectAtIndex:self->step];

    return [self doStep:self->step withObject:obj];
  }

  return [self doStep:self->step withObject:nil];
}

- (id)forwardNotCached {
  return [self forwardCached:NO];
}

- (id)forward {
  return [self forwardCached:YES];
}

- (id)back {
  self->stepForward = NO;
  
  if (self->step > 0)
    self->step--;
  
  if ((int)[self->objects count] > self->step) {
    id obj;
    obj = [(NSDictionary *)[self->objects objectAtIndex:self->step] 
                                          objectForKey:@"object"];
    return [self doStep:self->step withObject:obj];
  }
  
  [self logWithFormat:@"WARNING: inconsistence state "];
  return nil;
}

- (id)cancel {
  if ((self->startPage != nil) && (self->parent != nil)) {
    [self logWithFormat:@"WARNING: inconsistence state "];
    [[self->session navigation] enterPage:self->startPage];
    return nil;
  }
  if (self->startPage != nil) {
    [[self->session navigation] enterPage:self->startPage];
    return nil;
  }
  if (self->parent != nil)
    return [self->parent cancel];
  
  [self logWithFormat:@"inconsistence state"];
  return nil;
}

- (id)finish {
  id page = nil;
  page = [[self->session application] pageWithName:@"SkyWizardResultList"];
  [page setWizard:self];
  [[self->session navigation] enterPage:page];
  return nil;
} 

- (BOOL)isForward {
  return (self->step < ([self maxSteps] - 1))  ? YES : NO;
}

- (BOOL)isBack {
  return (self->step > 0) ? YES : NO;
}

- (BOOL)isFinish {
  [self logWithFormat:@"ERROR(%s): subclass should override this method!",
	  __PRETTY_FUNCTION__];
  return NO;
}

- (id)save {
  return [self saveWithObject:nil];
}

- (id)saveWithObject:(id)_obj {
  int            i, cnt = 0;
  NSMutableArray *array = nil;

  array = [NSMutableArray arrayWithCapacity:64];

  if (_obj != nil) {
    [array addObject:_obj];
  }
  
  for (i = 0, cnt = [self->objects count]; i < cnt; i++) {
    BOOL         addObjAsPar;
    NSDictionary *obj;
    id           tmp = nil;


    addObjAsPar = NO;
    obj         = [self->objects objectAtIndex:i];
    if (i < (cnt - 1)) {
      NSDictionary *o2;
      
      o2 = [self->objects objectAtIndex:i+1];
      if ([o2 objectForKey:@"parent"] == [obj valueForKey:@"object"])
        addObjAsPar = YES;
      
      while (([obj objectForKey:@"parent"] != 
              [[array lastObject] valueForKey:@"snapshot"]) &&
             ([array lastObject] != nil)) {
        [array removeLastObject];
      }
    }
    if ([[obj objectForKey:@"object"] isNotNull]) {
      NGMimeType *mimeType;
      id page = nil;
      
      mimeType = [NGMimeType mimeType:@"eo"
			     subType:[obj objectForKey:@"objectType"]];
      page = [self->session instantiateComponentForCommand:@"wizard"
                  type:mimeType object:obj];
      [page setSnapshot:[obj objectForKey:@"object"]];
      if ([array count] > 0) {
	id eo;
	eo = [[array lastObject] valueForKey:@"eo-obj"];
        [page setWizardObjectParent:eo];
      }
      tmp = [page wizardSave];
    }
    if (addObjAsPar) {
      NSDictionary *d;

      d = [NSDictionary dictionaryWithObjectsAndKeys:
                          tmp, @"eo-obj",
                          [obj objectForKey:@"object"], @"snapshot",
                        nil];
      [array addObject:d]; 
    }
  }
  
  if (self->parent == nil)
    return [self cancel];

  return nil;
}

- (NSArray *)objects {
  /* HH: should that be a call to shallowCopy ? */
  return [[self->objects copy] autorelease];
}

- (void)addSnapshot:(id)_obj page:(id)_page {
  NSMutableDictionary *dict;
  int cnt = 0;
  
  cnt = [self->objects count];
  if (cnt < self->step - 1) {
    [self logWithFormat:
	    @"inconsistence state self->step %d [self->objects count]"
            @" %d", self->step, cnt];
    return;
  }

  dict = [NSMutableDictionary dictionaryWithCapacity:4];

  if ((self->objectParent != nil) || (self->step > 0)) {
    [dict setObject:self->objectParent forKey:@"parent"];
  }
  else {
    ASSIGN(self->objectParent, _obj);
  }
  [dict setObject:[_page wizardObjectType] forKey:@"objectType"];
  [dict setObject:[self wizardName] forKey:@"wizardName"];
  [dict setObject:_obj forKey:@"object"];

  if (cnt == self->step) {
    [self->objects addObject:dict];
  }
  else {
    [self->objects replaceObjectAtIndex:self->step withObject:dict];
  }
}

- (NSString *)wizardName {
  [self logWithFormat:@"ERROR(%s): subclass should override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (BOOL)pageCouldChangeForStep:(int)_step {
  [self logWithFormat:@"ERROR(%s): subclass should override this method!",
	  __PRETTY_FUNCTION__];
  return NO;
}

/* accessors */

- (id)parent {
  return self->parent;
}
- (void)setParent:(id)_parent {
  self->parent = _parent;
}

- (id)startPage {
  return self->startPage;
}
- (void)setStartPage:(id)_startPage {
  self->startPage = _startPage;
}

- (id)objectParent {
  return self->objectParent;
}
- (void)setObjectParent:(id)_parent {
  ASSIGN(self->objectParent, _parent);
}

- (id)choosenPageName {
  return self->choosenPageName;
}
- (void)setChoosenPageName:(id)_name {
  ASSIGN(self->choosenPageName, _name);
}

- (id)goToPage:(id)_page {
  if (_page == nil) {
    NSLog(@"ERROR: goToPage with nil page");
    return nil;
  }
  if ((int)[self->pageCache count] <= self->step) {
    [self->pageCache addObject:_page];
  }
  else {
    if ((int)[self->pageCache count] == self->step) {
      [self->pageCache replaceObjectAtIndex:self->step withObject:_page];
    }
  }
  [[self->session navigation] enterPage:_page];
  return nil;
}

- (id)cachedPage {
  if ((int)[self->pageCache count] > self->step)
    return [self->pageCache objectAtIndex:self->step];
  
  return nil;
}

- (NSString *)labelPage {
  [self logWithFormat:@"ERROR(%s): subclass should override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (id)labels {
  if (self->labels == nil) {
    id page = [[self->session application] pageWithName:[self labelPage]];
    self->labels = [page retain];
  }
  return [self->labels labels];
}

@end /* SkyWizard */
