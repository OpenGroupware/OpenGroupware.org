/*
  Copyright (C) 2004 SKYRIX Software AG

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

#ifndef __OGoConfigDatabase_H__
#define __OGoConfigDatabase_H__

#import <Foundation/NSObject.h>

@class NSString, NSArray, NSFileManager;
@class EODataSource, EOGlobalID;

@interface OGoConfigDatabase : NSObject
{
  NSFileManager *fileManager;
  NSString      *path;
}

- (id)initWithSystemPath:(NSString *)_path;
- (id)initWithPath:(NSString *)_path fileManager:(NSFileManager *)_fm;

/* accessors */

- (NSFileManager *)fileManager;
- (NSString *)path;

/* operating on the content */

- (NSArray *)fetchEntryNames;
- (id)fetchEntryWithName:(NSString *)_name;

/* common API */

- (EODataSource *)configDataSource;
- (id)fetchEntryForGlobalID:(EOGlobalID *)_gid;

@end

#endif /* __OGoConfigDatabase_H__ */
