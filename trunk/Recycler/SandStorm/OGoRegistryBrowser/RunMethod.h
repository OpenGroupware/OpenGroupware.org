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

#ifndef __SandStorm_RunMethod_H__
#define __SandStorm_RunMethod_H__

#include <NGObjWeb/WOComponent.h>

@class NSString, NSArray;
@class SxComponentInvocation;
@class SxXmlRpcComponent;
@class SxComponentRegistry;

@interface RunMethod : WOComponent
{
  NSString              *methodName;
  SxComponentInvocation *invocation;
  SxComponentInvocation *item;
  SxComponentRegistry   *registry;
  SxXmlRpcComponent     *component;
  NSArray               *signatures;
  NSArray               *invocations;
  NSArray               *defaultValues;
  BOOL                  hasResult;
  int                   index;
  id lastResult;
}

/* accessors */

- (void)setIndex:(int)_idx;
- (int)index;

- (void)setDefaultValues:(NSArray *)_defaultValues;

- (void)setComponent:(SxXmlRpcComponent *)_component;
- (SxXmlRpcComponent *)component;

- (void)setItem:(SxComponentInvocation *)_item;
- (SxComponentInvocation *)item;

- (void)setMethodName:(NSString *)_name;
- (NSString *)methodName;

- (void)setInvocation:(SxComponentInvocation *)_invocation;
- (SxComponentInvocation *)invocation;

- (void)setCurrentElement:(id)_element;
- (id)currentElement;

- (NSArray *)invocations;
- (NSString *)help;
- (int)count;
- (NSString *)currentType;

- (void)setResult:(id)_result;
- (id)result;
- (BOOL)hasResult;

/* actions */

- (id)run;
- (id)selectInvocation;

- (id)backToMain;

@end /* RunMethod */

#endif /* __SandStorm_RunMethod_H__ */
