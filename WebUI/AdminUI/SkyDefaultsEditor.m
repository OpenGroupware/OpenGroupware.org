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

#include "SkyDefaultsEditor.h"
#include "common.h"
#include "SkyDefaultsDomain.h"
#include "SkyDefaultsElement.h"

@implementation SkyDefaultsEditor

- (void)dealloc {
  [self->domain release];
  [self->currentElement release];
  [super dealloc];
}

/* accessors */

- (void)setDomain:(SkyDefaultsDomain *)_domain {
  ASSIGN(self->domain, _domain);
}
- (SkyDefaultsDomain *)domain {
  return self->domain;
}

- (void)setCurrentElement:(SkyDefaultsElement *)_element {
  ASSIGN(self->currentElement, _element);
}
- (SkyDefaultsElement *)currentElement {
  return self->currentElement;
}

- (BOOL)hasPredefinedValues {
  return ([[self currentElement] predefinedValues] != nil);
}

- (void)setCurrentSelection:(id)_selection {
  [[self currentElement] setValue:_selection];
}
- (NSArray *)currentSelection {
  return [[self currentElement] value];
}

/* actions */

- (id)save {
  id d;

  d = [self domain];
  
  if (![d saveAllElements]) {
    NSString *eString;

    eString = [[self labels] valueForKey:[d errorString]];
    [self setErrorString:eString];
  }
  else {
    [[[self session] navigation] leavePage];
  }
  return nil;
}

- (id)cancel {
  [[[self session] navigation] leavePage];
  return nil;
}

- (BOOL)isPassword {
  return [[self->currentElement valueForKey:@"isPassword"] boolValue];
}

- (BOOL)isTextArea {
  return [self->currentElement isTextArea];
}

- (BOOL)isTextField {
  return (![self isPassword] && ![self isTextArea]);
}
- (NSString *)textValue {
  NSString *sep;
  NSString *v;

  v = [self->currentElement value];

  if ([(sep = [self->currentElement valueSeperator]) length] > 0) {
    v = [[v componentsSeparatedByString:sep] componentsJoinedByString:@"\n"];
  }
  return v;
}

- (NSString *)_escapeTextValue:(NSString *)_str seperator:(NSString *)sep {
  NSEnumerator    *enumerator;
  NSMutableString *str;
  id              s;

  str = [NSMutableString stringWithCapacity:[_str length]];
  enumerator = [[_str componentsSeparatedByString:@"\n"] objectEnumerator];
  while ((s = [[enumerator nextObject] stringByTrimmingSpaces])) {
    if ([s length] == 0)
      continue;
    
    if ([str length] > 0)
      [str appendString:sep];
    
    [str appendString:s];
  }
  return [[str copy] autorelease];
}
- (void)setTextValue:(NSString *)_str {
  NSString *sep;
  
  if ([(sep = [self->currentElement valueSeperator]) length] > 0)
    _str = [self _escapeTextValue:_str seperator:sep];
  
  [self->currentElement setValue:_str];
}

      
@end /* SkyDefaultsEditor */
