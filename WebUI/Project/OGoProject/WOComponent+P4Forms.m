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

#include "WOComponent+P4Forms.h"
#include "common.h"
#include <OGoForms/WOComponent+Forms.h>

@interface WOComponent(FileManager_Additions)
- (id)fileManager;
@end /* WOComponent(FileManager_Additions) */

@implementation WOComponent(P4Forms)

- (id)formForDocument:(id)_doc className:(NSString *)_className {
  Class formClazz;
  id form;
  
  if (_doc == nil)
    return nil;
  
  if ((formClazz = NSClassFromString(_className)) == Nil)
    return nil;
  
  form = [self formWithName:[_doc valueForKey:@"NSFilePath"]
               componentClass:formClazz
               content:[_doc contentAsString]];
  
  [form takeValue:_doc forKey:@"formDocument"];

  if ([self respondsToSelector:@selector(fileManager)])
    [form takeValue:[self fileManager] forKey:@"fileManager"];
  
  return form;
}

- (id)formForDocument:(id)_doc {
  return [self formForDocument:_doc className:@"SkyP4ViewerFormComponent"];
}

@end /* WOComponent(P4Forms) */
