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

#include "SkyPubSKYOBJ.h"
#include "SkyPubResourceManager.h"
#include "common.h"
#include <DOM/EDOM.h>

@implementation SkyPubSKYOBJNodeRenderer(MicroNav)

- (void)_appendMicronavigationNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *title;
  int levels;
  
  levels = [[self stringFor:@"levels" node:_node ctx:_ctx] intValue];
  title  = [self stringFor:@"micronavigation" node:_node ctx:_ctx];
  
  [_response appendContentString:@"[micronavigation not yet supported]"];
}

@end /* SkyPubSKYOBJNodeRenderer(IncludeText) */

