/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include <LSWFoundation/OGoSession.h>
#include <LSWFoundation/OGoComponent.h>
#include <NGObjWeb/OWViewRequestHandler.h>
#import <EOControl/EOControl.h>
#import <Foundation/Foundation.h>

#if WITH_JAVASCRIPT
#  include <NGJavaScript/NGJavaScript.h>

@interface SkyJSComponent : OGoComponent
{
  NSString *scriptPath;
  id       jsObject;
}
@end

@implementation SkyJSComponent

+ (BOOL)isScriptedComponent {
  return YES;
}

- (id)initWithName:(NSString *)_name {
  if ((self = [super init])) {
    id ctx;
    
    [self setName:_name];
    
    self->scriptPath = [_name stringByAppendingPathExtension:@"js"];
    self->scriptPath = [[self path] stringByAppendingPathComponent:self->scriptPath];
    self->scriptPath = [self->scriptPath copy];
    
    ctx = [[self application] jsContext];
    self->jsObject =
      [[NGJavaScriptObjectHandler alloc] initWithJSContext:ctx handler:self];
    
    [self evalJSScript];
  }
  return self;
}

+ (id)scriptedComponentWithName:(NSString *)_name {
  return AUTORELEASE([[self alloc] initWithName:_name]);
}

- (void)dealloc {
#if 0
  [self logWithFormat:@"DEALLOC 0x%08X", self];
#endif
  RELEASE(self->jsObject);
  RELEASE(self->scriptPath);
  [super dealloc];
}

- (NGJavaScriptContext *)jsContext {
  return [(id)[self application] jsContext];
}

- (void)evalJSScript {
  NSString *script;
  
  script = [NSString stringWithContentsOfFile:scriptPath];
  [jsObject evaluateScript:script];
}

- (BOOL)isContentPage {
  return [self->jsObject hasPropertyNamed:@"isContentPage"]
    ? [[self valueForKey:@"isContentPage"] boolValue]
    : NO;
}

- (void)awake {
  [super awake];
  //[self evalJSScript];

  if ([self->jsObject hasPropertyNamed:@"awake"])
    [self->jsObject callFunctionNamed:@"awake", nil];
}

- (void)sleep {
  if ([self->jsObject hasPropertyNamed:@"sleep"])
    [self->jsObject callFunctionNamed:@"sleep", nil];
  
  [super sleep];
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  if ([self->jsObject hasPropertyNamed:@"noteChange"])
    [self->jsObject callFunctionNamed:@"noteChange", _cn, _object, nil];
}

/* RC */

- (BOOL)isJSCombinedObject {
  return YES;
}
- (void *)jsObjectHandle {
  return [self->jsObject handle];
}

- (oneway void)release {
  NSAssert(self->jsObject, @"missing JS object ..");
  if (self->jsObject == NULL)
    [super release];
  [self->jsObject releaseCombinedObject:self];
}
- (id)retain {
  return [self->jsObject retainCombinedObject:self];
}

- (unsigned)retainCount {
  return [self->jsObject retainCountOfCombinedObject:self];
}

/* key-value coding */

- (void)setObject:(id)_obj forKey:(NSString *)_key {
  [self->jsObject setValue:_obj ofPropertyNamed:_key];
}
- (id)objectForKey:(NSString *)_key {
  return [self->jsObject valueOfPropertyNamed:_key];
}

- (void)takeValue:(id)_value forJSPropertyNamed:(NSString *)_key {
  //[self handleTakeValue:_value forUnboundKey:_key];
  //NSLog(@"DID NOT: takeValue:forJSPropertyNamed:'%@'", _key);
}
- (id)valueForJSPropertyNamed:(NSString *)_key {
  return nil;
}

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([self->jsObject hasPropertyNamed:_key]) {
    //NSLog(@"JS has property %@", _key);
    [self->jsObject setValue:_value ofPropertyNamed:_key];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([self->jsObject hasPropertyNamed:_key]) {
    id value;
    
    value = [self->jsObject valueOfPropertyNamed:_key];
    
    if ([value isJavaScriptFunction])
      value = [self->jsObject callFunctionNamed:_key, nil];
    
    return value;
  }
  
  return [super valueForKey:_key];
}

@end

#include <NGExtensions/NGExtensions.h>
#include <NGMime/NGMime.h>
#include <LSFoundation/LSFoundation.h>
#include <OGoFoundation/OGoFoundation.h>

@implementation OGoComponent(JSSupport)

- (id)_jsprop_defaults {
  return [(OGoSession *)[self session] userDefaults];
}
- (id)_jsprop_labels {
  return [self labels];
}

- (id)_jsfunc_isComponentAvailable:(NSArray *)_args {
  NGBundleManager *bm;
  
  bm = [NGBundleManager defaultBundleManager];

  return [bm bundleProvidingResource:[_args objectAtIndex:0]
             ofType:@"WOComponents"];
}

- (id)_jsfunc_pageForVerbAndType:(NSArray *)_args {
  OGoSession  *sn;
  WOComponent *ct;

  sn = (id)[self session];
  ct = [sn instantiateComponentForCommand:[_args objectAtIndex:0]
           type:[NGMimeType mimeType:[[_args objectAtIndex:1] stringValue]]];
  return ct;
}

/* commands */

- (id)_run:(NSArray *)_args returnType:(int)_retType {
  unsigned count;
  NSString *cmdName;

  cmdName = [[_args objectAtIndex:0] stringValue];

  if ((count = [_args count]) > 1) {
    NSMutableDictionary *args;
    NSEnumerator *e;
    NSString     *key;

    e = [_args objectEnumerator];
    [e nextObject]; // consume command name

    args = [NSMutableDictionary dictionaryWithCapacity:(count / 2) + 1];
    
    if (_retType >= 0)
      [args setObject:intObj(_retType) forKey:@"returnType"];
    
    while ((key = [[e nextObject] stringValue])) {
      id value;
      
      value = [e nextObject];
      [args setObject:value forKey:key];
    }

    //[self debugWithFormat:@"running '%@' with %@", cmdName, args];
    return [self runCommand:cmdName arguments:args];
  }
  else {
    //[self debugWithFormat:@"running '%@'", cmdName];
    NSDictionary *args = nil;

    if (_retType >= 0) {
      args = [NSDictionary dictionaryWithObject:intObj(_retType)
                           forKey:@"returnType"];
    }
    
    return [self runCommand:cmdName arguments:args];
  }
}

- (id)_jsfunc_run1:(NSArray *)_args {
  return [self _run:_args returnType:LSDBReturnType_OneObject];
}
- (id)_jsfunc_runN:(NSArray *)_args {
  return [self _run:_args returnType:LSDBReturnType_ManyObjects];
}
- (id)_jsfunc_run:(NSArray *)_args {
  return [self _run:_args returnType:-1];
}

@end /* OGoComponent(JSSupport) */

#endif
