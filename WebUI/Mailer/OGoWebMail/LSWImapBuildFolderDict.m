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

#include "LSWImapBuildFolderDict.h"
#include "common.h"

@implementation LSWImapBuildFolderDict

+ (void)buildFolderDictionary:(NSMutableDictionary *)_dict
  folder:(NSArray *)_folders
  prefix:(NSString *)_prefix
{
  NSEnumerator  *folderEnum;
  NGImap4Folder *fold;

  folderEnum = [_folders objectEnumerator];

  while ((fold = [folderEnum nextObject])) {
    NSString *prefix;
    NSArray  *f;
        
    prefix = _prefix;
    f      = [fold subFolders];
    
    prefix = [prefix stringByAppendingString:[fold name]];
    [_dict setObject:fold forKey:prefix];
    if ([f count] > 0) {
      [self buildFolderDictionary:_dict folder:f 
	    prefix:[prefix stringByAppendingString:@"@ @"]];
    }
  }
}

@end /* LSWImapBuildFolderDict */
