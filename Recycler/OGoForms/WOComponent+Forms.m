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

#include <OGoForms/WOComponent+Forms.h>
#include <OGoForms/SkyComponentDefinition.h>
#include <OGoForms/SkyFormComponent.h>
#include "common.h"

@implementation WOComponent(Forms)

- (id)formWithName:(NSString *)_fname
  componentClass:(Class)_class
  content:(NSString *)_content
{
  NSAutoreleasePool      *pool;
  id                     form;
  WOResourceManager      *rm;
  NSArray                *languages;
  SkyComponentDefinition *cdef;
  
  pool = [[NSAutoreleasePool alloc] init];
  form = nil;
  
  rm = [[self application] resourceManager];
  
  languages = [[self context] hasSession]
    ? [[self session] languages]
    : [[[self context] request] browserLanguages];
  
  if ((_class == nil) && (_fname != nil))
    _class = NGClassFromString(_fname);
  
  if ((_fname == nil) && (_class != nil))
    _fname = NSStringFromClass(_class);
  
  if (_class == Nil) {
    [self logWithFormat:@"cannot find class for form '%@'", _fname];
    return nil;
  }
  
  cdef = [[[SkyComponentDefinition alloc] init] autorelease];
  
  [cdef setComponentClass:_class];
  [cdef setComponentName:_fname];
  
  if (cdef == nil) {
    [self logWithFormat:
            @"couldn't instantiate component definition for form '%@'",
            _fname];
    return nil;
  }
  
  if (![cdef loadFromSource:_content]) {
    [self logWithFormat:@"couldn't load template of form '%@'.", _fname];
    return nil;
  }
  
  form = [[cdef instantiateWithResourceManager:rm languages:languages] retain];
  [pool release];
  return [form autorelease];
}

- (id)formWithName:(NSString *)_fname content:(NSString *)_content {
  return [self formWithName:_fname
               componentClass:[SkyFormComponent class]
               content:_content];
}

- (id)formWithName:(NSString *)_fname url:(NSURL *)_url {
  NSURLHandle *handle;
  NSData      *data;
  NSString    *ctype;
  NSString    *contentString;

  if (_fname == nil)
    _fname = [_url absoluteString];
  
  if ((handle = [_url URLHandleUsingCache:YES]) == nil)
    return nil;
  
  ctype = [handle propertyForKey:@"content-type"];
  data  = [handle resourceData];
  
  contentString =
    [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
  contentString = [contentString autorelease];
  
  return [self formWithName:_fname content:contentString];
}

@end /* WOComponent(Forms) */
