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

#ifndef __SkySimpleProjectFolderDataSource_H__
#define __SkySimpleProjectFolderDataSource_H__

#include <EOControl/EODataSource.h>

/*
  SkySimpleProjectFolderDataSource
  
  TODO: explain what this is used for.
*/

@class EOFetchSpecification;
@class SkyProjectFolderDataSource;

@interface SkySimpleProjectFolderDataSource : EODataSource
{
@protected
  SkyProjectFolderDataSource *source;
  EOFetchSpecification       *fetchSpecification;
}

- (id)initWithFolderDataSource:(SkyProjectFolderDataSource *)_ds;

@end

#endif /* __SkySimpleProjectFolderDataSource_H__ */
