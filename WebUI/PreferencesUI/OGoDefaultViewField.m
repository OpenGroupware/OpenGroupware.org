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


/*
 componentLabels - the label manager of the current bundle
 defaults        - the userdefaults ([defaults synchronize] must be called
                   during save)
 formatter       - a formatter for displaying values
 localizeValue   - display the value as it is or use
 key             - the default key
*/

#include "common.h"

@interface OGoDefaultViewField : WOComponent
{
  id componentLabels;
  id key;
  id defaults;
  id formatter;
  id localizeValue;

  NSString *useFormatter;
}
@end /* OGoDefaultViewField */

@implementation OGoDefaultViewField

- (void)dealloc {
  [self->componentLabels release];
  [self->key             release];
  [self->defaults        release];
  [self->formatter       release];
  [self->localizeValue   release];
  [self->useFormatter    release];
  [super dealloc];
}

- (id)componentLabels {
  return self->componentLabels;
}
- (void)setComponentLabels:(id)_obj {
  ASSIGN(self->componentLabels, _obj);
}
- (id)key {
  return self->key;
}
- (void)setKey:(id)_obj {
  ASSIGN(self->key, _obj);
}
- (id)defaults {
  return self->defaults;
}
- (void)setDefaults:(id)_obj {
  ASSIGN(self->defaults, _obj);
}
- (id)formatter {
  return self->formatter;
}

- (void)setFormatter:(id)_obj {
  ASSIGN(self->formatter, _obj);
}
- (id)localizeValue {
  return self->localizeValue;
}
- (void)setLocalizeValue:(id)_obj {
  ASSIGN(self->localizeValue, _obj);
}

- (void)setUseFormatter:(NSString *)_s {
  ASSIGN(self->useFormatter, _s);
}
- (NSString *)useFormatter {
  return self->useFormatter;
}



@end /* OGoDefaultViewField */
