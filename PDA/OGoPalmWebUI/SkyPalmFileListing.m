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

#include "SkyPalmSelectableListing.h"

/*
  additional bindings
    > mustBeReadable     - YES | NO  if file must be readable  for select
    > mustBeWriteable    - YES | NO  if file must be writeable for select
*/
  
@interface SkyPalmFileListing : SkyPalmSelectableListing
{
}

@end /* SkyPalmFileListing */

#import <Foundation/Foundation.h>

@interface NSObject(ProjectDoc)
- (BOOL)isReadable;
- (BOOL)isWriteable;
@end

@implementation SkyPalmFileListing

- (NSArray *)files {
  return [self list];
}

- (void)setFile:(id)_f {
  [self setItem:_f];
}
- (id)file {
  return [self item];
}

- (BOOL)canSelectMultiple {
  return [self selections] != nil ? YES : NO;
}

// conditionals
- (BOOL)canChooseFile {
  id tmp;
  if (((tmp = [self valueForBinding:@"mustBeReadable"]) != nil) &&
      ([tmp boolValue]) &&
      (![[self item] isReadable]))
    return NO;
  if (((tmp = [self valueForBinding:@"mustBeWriteable"]) != nil) &&
      ([tmp boolValue]) &&
      (![[self item] isWriteable]))
    return NO;
  return YES;
}

// actions
- (id)chooseFile {
  return [self selectItem];
}
- (id)chooseFiles {
  return [self selectItems];
}

@end /* SkyPalmFileListing */
