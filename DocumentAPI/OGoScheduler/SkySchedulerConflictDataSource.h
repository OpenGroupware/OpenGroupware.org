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

#ifndef __SkySchedulerConflictDataSource_H__
#define __SkySchedulerConflictDataSource_H__

#import <EOControl/EODataSource.h>

@class NSArray, NSMutableArray;
@class LSCommandContext;

/**
 * @class SkySchedulerConflictDataSource
 * @brief Datasource that detects scheduling conflicts for
 *        an appointment.
 *
 * Given an appointment (with participants, resources, and
 * time range), fetches all conflicting appointments using
 * the "appointment::conflicts" command. Handles recurring
 * appointments by expanding cycle dates before checking
 * each slot for conflicts.
 *
 * Supports additional child datasources (e.g. PalmDS) to
 * check for conflicts from external calendar sources.
 * Results are cached and sorted by start date.
 *
 * Used by:
 * - OGoSchedulerViews/SkyInlineAptDataSourceView.m
 * - OGoScheduler/SkySchedulerConflictPage.m
 * - LSWScheduler/LSWAppointmentMove.m
 * - LSWScheduler/LSWAppointmentEditor.m
 *
 * @see SkyAppointmentQualifier
 * @see SkyAptDataSource
 */
@interface SkySchedulerConflictDataSource : EODataSource
{
  /* execution context */
  LSCommandContext *lso;
  
  /* appointment to check for conflicts */
  id      appointment;

  /* additional datasource to look for conflicts */
  NSMutableArray *dataSources;
  
  /* result cache */ // TODO: do not cache! (use EOCacheDataSource for that!)
  NSArray *conflicts;
}

- (id)initWithContext:(LSCommandContext *)_ctx;

- (void)setAppointment:(id)_apt;
- (id)appointment;
- (LSCommandContext *)context;

// add a datasource to look for conflicting entries
// _ds should handle SkyAppointmentQualifier
- (void)addDataSource:(EODataSource *)_ds;

@end

#endif /* __SkySchedulerConflictDataSource_H__ */
