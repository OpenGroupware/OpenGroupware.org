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

#ifndef __SkyPalmCategoryDataSource_H_
#define __SkyPalmCategoryDataSource_H_

#include <OGoRawDatabase/SkyAdaptorDataSource.h>

@class NSString;
@class LSCommandContext, SkyPalmCategoryDocument;

@interface SkyPalmCategoryDataSource : SkyAdaptorDataSource
{
  SkyAdaptorDataSource *ds;

  id                   ctx;
  NSString             *palmTable;
  NSString             *defaultDeviceId;
}

+ (SkyPalmCategoryDataSource *)dataSourceWithContext:(LSCommandContext *)_ctx
  forPalmTable:(NSString *)_palmDb;

- (NSString *)palmTable;
- (void)setDefaultDevice:(NSString *)_devId;
- (NSArray *)devices;

/* datasource */
- (void)insertObject:(SkyPalmCategoryDocument *)_doc;
- (void)updateObject:(SkyPalmCategoryDocument *)_doc;
- (void)deleteObject:(SkyPalmCategoryDocument *)_doc;

/* refetch */
- (NSDictionary *)fetchDictionaryForDocument:(SkyPalmCategoryDocument *)_doc;

/* category docs */
- (SkyPalmCategoryDocument *)documentForObject:(id)_obj;
- (SkyPalmCategoryDocument *)newDocument;
- (SkyPalmCategoryDocument *)unfiledCategory;

/* assigning */
- (void)assignCategoriesToDocuments:(NSArray *)_rec ofTable:(NSString *)_table;


@end

#endif /* __SkyPalmCategoryDataSource_H_ */
