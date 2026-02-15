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

#ifndef __SkyAppointmentDataSource_H__
#define __SkyAppointmentDataSource_H__

#include <EOControl/EODataSource.h>

#define SkyUpdatedAppointmentNotification @"SkyUpdatedAppointmentNotification"
#define SkyDeletedAppointmentNotification @"SkyDeletedAppointmentNotification"
#define SkyNewAppointmentNotification     @"SkyNewAppointmentNotification"

@class LSCommandContext, EOFetchSpecification;

/**
 * @class SkyAppointmentDataSource
 * @brief EODataSource for appointment documents with
 *        document-level operations.
 *
 * A datasource that fetches appointments and always
 * returns SkyAppointmentDocument instances. Supports
 * create, insert, update, and delete operations.
 *
 * Input via EOFetchSpecification:
 *   - qualifier: SkyAppointmentQualifier
 *   - hints: 
 *     - attributes (NSArray), 
 *     - fetchGIDs (NSArray),
 *     - timeZone (NSTimeZone, qualifier can override),
 *     - fetchGlobalIDs (BOOL, default NO)
 *
 * Output: Array of SkyAppointmentDocument objects.
 *
 * Posts SkyNewAppointmentNotification,
 * SkyUpdatedAppointmentNotification, and
 * SkyDeletedAppointmentNotification on changes.
 *
 * @see SkyAppointmentDocument
 * @see SkyAppointmentQualifier
 * @see SkyAptDataSource
 */
@interface SkyAppointmentDataSource : EODataSource
{
  LSCommandContext     *context;
  EOFetchSpecification *fetchSpecification;
}

- (id)initWithContext:(LSCommandContext *)_ctx;


- (LSCommandContext *)context;

@end

/**
 * @class SkyAppointmentDocumentGlobalIDResolver
 * @brief Resolves Date global IDs to
 *        SkyAppointmentDocuments.
 *
 * Implements the SkyDocumentGlobalIDResolver protocol
 * to resolve EOKeyGlobalIDs with entity name "Date"
 * into SkyAppointmentDocument instances.
 */

#include <OGoDocuments/SkyDocumentManager.h>

@interface SkyAppointmentDocumentGlobalIDResolver : NSObject
  <SkyDocumentGlobalIDResolver>
@end

#endif /* __SkyAppointmentDataSource_H__ */
