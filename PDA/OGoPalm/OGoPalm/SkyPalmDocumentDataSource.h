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
// $Id: SkyPalmDocumentDataSource.h 1 2004-08-20 11:17:52Z znek $

#ifndef __SkyPalmDocumentDataSource_H__
#define __SkyPalmDocumentDataSource_H__

// ONLY USE Superclasses !!!

#import <Foundation/Foundation.h>
#include <EOControl/EODataSource.h>
#include <OGoPalm/SkyPalmDocument.h>
#include <OGoRawDatabase/SkyAdaptorDataSource.h>

@interface SkyPalmDocumentDataSource : EODataSource
{
  NSString *defaultDevice; /* default palm device (for new records) */
}

/* overwrite these methods in subclasses if needed */
- (NSString *)palmDb;      // AddressDB, DatebookDB, MemoDB, ToDoDB
- (SkyPalmDocument *)allocDocument;
- (void)insertObject:(SkyPalmDocument *)_doc;
- (void)updateObject:(SkyPalmDocument *)_doc;
- (void)deleteObject:(SkyPalmDocument *)_doc;

- (void)setDefaultDevice:(NSString *)_dev;
- (NSString *)defaultDevice;
- (NSArray *)devices;     // possible palm devices

// possible categories for device
- (NSArray *)categoriesForDevice:(NSString *)_dev;
- (NSNumber *)companyId;  // current user's company id
- (NSString *)primaryKey; // primaryKey of database
- (id)currentAccount;     // current user

- (id)fetchDictionaryForDocument:(SkyPalmDocument *)_doc;

- (SkyPalmDocument *)documentForObject:(id)_obj;
- (SkyPalmDocument *)newDocument;
- (void)dotLog;

/* categories */
- (NSArray *)categoriesForDevice:(NSString *)_dev;
- (NSArray *)saveCategories:(NSArray *)_cats    // returns saved records
  forDevice:(NSString *)_dev;

@end

#endif /* __SkyPalmDocumentDataSource_H__ */
