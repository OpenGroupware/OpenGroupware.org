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
// $Id: SxSetCacheManager.h 1 2004-08-20 11:17:52Z znek $

#ifndef __Backend_SxSetCacheManager_H__
#define __Backend_SxSetCacheManager_H__

#import <Foundation/NSObject.h>

/*
  SxSetCacheManager
  
  This class is used to manager a cache for a folder-set. It tracks the
  folder versions and can store caches for a specific folder version.
*/

@class NSString, NSFileManager;

@interface SxSetCacheManager : NSObject
{
  NSFileManager *fm;
  NSString      *path;
  id setId;
  id manager; /* non-retained ! */
  
  NSString *lastCSV;
  int      lastCSVVersion;
}

- (id)initWithPath:(NSString *)_path setId:(id)_sid manager:(id)_manager;

/* accessors */

- (NSString *)path;

/* generation file */

- (int)generationOfSet;

/* id/version CSV */

- (NSString *)csvForSet;

@end

#endif /* __Backend_SxSetCacheManager_H__ */
