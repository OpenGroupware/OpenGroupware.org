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
// $Id$

#if 1

#warning not implemented, needs update for OGo (MD5 code)

#else

#include "common.h"
#include <NGExtensions/NGMD5Generator.h>

@implementation SkyProjectFileManager(MD5)

- (NSDictionary *)md5ValuesAtPath:(NSString *)_path
  deep:(BOOL)_deep
{
  NSArray             *files        = nil;
  NSEnumerator        *fileEnum     = nil;
  id                  file          = nil;
  NSMutableDictionary *filesAndMD5s = nil;

  files = [self searchChildsForFolder:_path deep:_deep qualifier:nil];

  filesAndMD5s = [NSMutableDictionary dictionaryWithCapacity:[files count]];
  
  fileEnum = [files objectEnumerator];

  while ((file = [fileEnum nextObject])) {
    NSMutableDictionary *element;
    NSString            *path;
    NGMD5Generator      *generator;

    path = [file objectForKey:@"NSFilePath"];

    element = [NSMutableDictionary dictionaryWithCapacity:2];
    [element takeValue:path forKey:@"path"];

    generator = [[NGMD5Generator alloc] init];
    [generator encodeData:[self contentsAtPath:path]];

    [element takeValue:[generator digestAsString] forKey:@"md5"];

    [filesAndMD5s setObject:element forKey:path];

    [generator release];
  }
  return filesAndMD5s;
}

@end /* SkyProjectFileManager(MD5) */

#endif
