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

#ifndef __NGLocalFileDataSource_h__
#define __NGLocalFileDataSource_h__

#import <EOControl/EOControl.h>

@class NSString;
@class EOGlobalID;

/**
 * @class NGLocalFileDataSource
 * @brief EODataSource for fetching local file documents.
 *
 * Provides an EODataSource interface over the local
 * filesystem via NGLocalFileManager. Fetches
 * NGLocalFileDocument objects for a given directory path,
 * supporting fetch specifications for filtering and
 * sorting.
 *
 * @see NGLocalFileManager
 * @see NGLocalFileDocument
 */
@interface NGLocalFileDataSource : EODataSource
{
  EOFetchSpecification *fetchSpecification;
  NSString             *path;
  id                   fm;
  NSTimeInterval       duration;
}

- (id)initWithPath:(NSString *)_path fileManager:(id)_fm;

/* operations */

- (NSArray *)fetchObjectsAtPath:(NSString *)_path;

/* accessors */

- (NSTimeInterval)duration;

@end /* NLocalGFileDataSource */

#endif /* __NGLocalFileDataSource_h__ */
