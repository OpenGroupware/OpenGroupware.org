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

#include <OGoFoundation/OGoComponent.h>

@interface OGoHelpViewer : OGoComponent
{
}

@end

#include "common.h"

@implementation OGoHelpViewer

- (void)dealloc {
  [super dealloc];
}

/* notifications */

- (void)sleep {
  // reset transient variables in sleep!
  [super sleep];
}

/* URLs */

- (NSString *)urlForResourceNamed:(NSString *)_name {
  NSString *url;
  NSArray  *langs;

  langs = [self hasSession]
    ? [[self session] languages]
    : [[[self context] request] browserLanguages];
  
  url = [[[self application] resourceManager]
                urlForResourceNamed:_name
                inFramework:nil
                languages:langs
                request:[[self context] request]];
  return url;
}

- (NSString *)shortcutLink {
  return [NSString stringWithFormat:
                     @"<link rel=\"shortcut icon\" href=\"%@\" />",
                     [self urlForResourceNamed:@"favicon.ico"]];
}
- (NSString *)stylesheetURL {
  return [self urlForResourceNamed:@"OGo.css"];
}

/* resources */

- (WOResourceManager *)resourceManager {
  return [[WOApplication application] resourceManager];
}

/* accessors */

#if 0
- (void)setItem:(id)_value {
  ASSIGN(self->item, _value);
}
- (id)item {
  return self->item;
}
#endif

/* actions */

- (id)showHelpAction {
  [self logWithFormat:@"path: %@", [[self context] pathInfo]];
  return self;
}

@end /* OGoHelpViewer */
