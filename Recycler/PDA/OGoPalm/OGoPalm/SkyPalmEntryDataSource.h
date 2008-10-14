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

#ifndef __SkyPalmEntryDataSource_H_
#define __SkyPalmEntryDataSource_H_

#include <LSFoundation/LSCommandContext.h>
#include <OGoPalm/SkyPalmDocumentDataSource.h>

@class EOFetchSpecification, NSNumber;

/*
 * implements plenty functions of SkyPalmDocumentDataSource
 *
 * uses Skyrix DataSource
 *
 * - insertObject
 * - updateSource
 * - deleteObject
 * - companyId
 * etc.
 *
 */

@interface SkyPalmEntryDataSource : SkyPalmDocumentDataSource
{
  SkyAdaptorDataSource *ds;
  id                   categoryDataSource;  // ds for categories

  id                   context;
  NSArray              *sortOrderings;

  NSMutableDictionary *devicesForUser;
}

+ (SkyPalmEntryDataSource *)dataSourceWithContext:(LSCommandContext *)_ctx
                                        forPalmDb:(NSString *)_palmDb;

// overwrite these methods: 
- (NSString *)entityName;  // palm_address, palm_date, palm_memo, palm_todo
// til here

- (NSString *)primaryKey;
- (void)setFetchSpecification:(EOFetchSpecification *)_spec;
- (EOFetchSpecification *)fetchSpecification;


- (id)context;
- (EOFetchSpecification *)fetchSpecForIds:(NSArray *)_ids;

// ogo sync
/*
  returns all available skyrix ids (primary key values) of ogo entries
  that are assigned to palm entries of this datasource
*/
- (NSArray *)assignedSkyrixIdsForDeviceId:(NSString *)_deviceId;

/* skyrix enries mapped for skyrix_id */
- (NSDictionary *)_bulkFetchSkyrixRecords:(NSArray *)_palmRecords;

@end

#include <OGoDocuments/SkyDocumentManager.h>

@interface SkyPalmDocumentGlobalIDResolver : NSObject
  <SkyDocumentGlobalIDResolver>
/* overwrite these methods in a subclass and u can use it as a globalID
 * resolver for your skyrix palm GlobalIDs
 */
- (NSString *)entityName;
- (NSString *)palmDb;
@end /* SkyPalmDocumentGlobalIDResolver */

#endif /* __SkyPalmEntryDataSource_H_ */
