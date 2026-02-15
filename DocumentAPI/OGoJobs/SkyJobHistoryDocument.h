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

#ifndef __SkyrixOS_Libraries_SkyJobs_SkyJobHistoryDocument_H_
#define __SkyrixOS_Libraries_SkyJobs_SkyJobHistoryDocument_H_

#include <OGoDocuments/SkyDocument.h>

@class EODataSource, EOGlobalID, NSString, NSCalendarDate, SkyDocument;

/**
 * @class SkyJobHistoryDocument
 * @brief Document representing a single history entry of
 *        an OGo job.
 *
 * Wraps a job history record as a SkyDocument. Each entry
 * contains a comment describing a state change of the
 * parent job. Supports save, delete, and reload operations
 * through its data source, and tracks editing state and
 * validity. Registers for global ID deletion
 * notifications.
 *
 * @see SkyJobHistoryDataSource
 * @see SkyJobDocument
 */
@interface SkyJobHistoryDocument : SkyDocument
{
  EODataSource      *dataSource;
  EOGlobalID        *globalID;

  NSString          *comment;
  
  struct {
    BOOL isEdited;
    BOOL isValid;
    BOOL isComplete;
  } status;
}

- (id)initWithEO:(id)_job dataSource:(EODataSource *)_ds;
- (id)initWithJobHistory:(id)_job
                globalID:(EOGlobalID *)_gid
              dataSource:(EODataSource *)_ds;

- (void)invalidate;
- (BOOL)isValid;

// attributes

- (BOOL)isNew;
- (BOOL)isEdited;
- (BOOL)isComplete;

/* operations */

- (BOOL)save;
- (BOOL)delete;
- (BOOL)reload;


/* --------- */

- (id)context;

/* attributes */

- (void)setComment:(NSString *)_comment;
- (NSString *)comment;

@end

#endif /* __SkyrixOS_Libraries_SkyJobs_SkyJobHistoryDocument_H_ */
