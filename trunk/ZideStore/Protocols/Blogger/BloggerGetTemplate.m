/*
  Copyright (C) 2004 Helge Hess

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

#include "BloggerAction.h"

@interface BloggerGetTemplate : BloggerAction
{
  NSString *templateType;
}

@end

#include "NSObject+Blogger.h"
#include "common.h"

@implementation BloggerGetTemplate

- (void)dealloc {
  [self->templateType release];
  [super dealloc];
}

/* accessors */

- (void)setTemplateType:(NSString *)_value {
  ASSIGN(self->templateType, _value);
}
- (NSString *)templateType {
  return self->templateType;
}

/* template */

- (NSString *)fetchTemplateString {
  return @"<p>my template</p>";
}

/* actions */

- (id)defaultAction {
  [self logWithFormat:@"%@ get template of blog %@ / %@: %@", 
	  [self login], [self blogID], [self templateType], 
	  [self clientObject]];
  return [self fetchTemplateString];
}

@end /* BloggerGetTemplate */
