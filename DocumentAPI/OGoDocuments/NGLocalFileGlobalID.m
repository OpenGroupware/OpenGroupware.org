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

#include <Foundation/Foundation.h>
#include "NGLocalFileGlobalID.h"
#include "common.h"

@implementation NGLocalFileGlobalID

- (id)initWithPath:(NSString *)_path rootPath:(NSString *)_root {
  if ((self = [super init])) {
    self->path     = RETAIN(_path);
    self->rootPath = RETAIN(_root);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->path);
  RELEASE(self->rootPath);
  [super dealloc];
}

- (BOOL)isEqual:(id)_other {
  return [_other isKindOfClass:[self class]] &&
         [[_other path] isEqualToString:[self path]] &&
         [[_other rootPath] isEqualToString:[self rootPath]];
}

- (NSString *)path {
  return self->path;
}
- (NSString *)rootPath {
  return self->rootPath;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<NGLocalFileGlobalID '%@' '%@'>",
                   self->rootPath, self->path];
}

@end /* NGlocalFileGlobalID */
