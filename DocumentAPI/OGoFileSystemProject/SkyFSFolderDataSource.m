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


#include "common.h"
#include "SkyFSFolderDataSource.h"
#include "SkyFSFileManager.h"
#include "SkyFSFileManager+Internals.h"
#include "SkyFSDocument.h"


@implementation SkyFSFolderDataSource

- (id)initWithPath:(NSString *)_path
  fileManager:(SkyFSFileManager *)_fm
{
  if ((self = [super init])) {
    ASSIGN(self->fm, _fm);
    ASSIGN(self->path, _path);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->path);
  RELEASE(self->fm);
  RELEASE(self->fetchSpecification);
  [super dealloc];
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fs {
  [self postDataSourceChangedNotification];
  ASSIGN(self->fetchSpecification, _fs);
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fetchSpecification;
}

- (NSArray *)fetchObjects {
  NSEnumerator   *enumerator;
  NSMutableArray *marray, *result;
  NSString       *p;
  EOQualifier    *qual;
  BOOL           fileSubject;

  enumerator  = [[self->fm subpathsAtPath:self->path] objectEnumerator];
  marray      = [[NSMutableArray alloc] initWithCapacity:64];
  qual        = [self->fetchSpecification qualifier];
  fileSubject = [[qual allQualifierKeys] containsObject:@"NSFileSubject"];

  while ((p = [enumerator nextObject])) {
    NSEnumerator *pEnum;
    NSString     *pcomp;
    NSString     *lastComponent;
    BOOL         ignore;

    ignore        = NO;
    lastComponent = nil;

    pEnum = [[p pathComponents] objectEnumerator];

    while ((pcomp = [pEnum nextObject])) {
      lastComponent = pcomp;
      if ([pcomp isEqualToString:[self->fm attributesPath]]) {
        ignore = YES;
        break;
      }
    }
    if (ignore || !lastComponent)
      continue;
    {
      NSDictionary *dict;

      
      if (fileSubject) {
        dict = [self->fm fileAttributesAtPath:p traverseLink:NO];
      }
      else {
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                             lastComponent, @"NSFileName",
                             nil];
      }

      if ([(id<EOQualifierEvaluation>)qual evaluateWithObject:dict])
        [marray addObject:p];
    }
  }
  enumerator = [marray objectEnumerator];
  result     = [NSMutableArray arrayWithCapacity:[marray count]];
  
  while ((p = [enumerator nextObject])) {
    id obj;
    if ((obj = [self->fm documentAtPath:p]))
      [result addObject:obj];
  }
  RELEASE(marray); marray = nil;
  return result;
}

@end /* SkyFSFolderDataSource */

