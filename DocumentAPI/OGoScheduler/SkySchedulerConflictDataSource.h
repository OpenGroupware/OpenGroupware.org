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

/*
  SkySchedulerConflictDataSource

  TODO: document

  Used by:
    OGoSchedulerViews/SkyInlineAptDataSourceView.m
    OGoScheduler/SkySchedulerConflictPage.m
    LSWScheduler/LSWAppointmentMove.m
    LSWScheduler/LSWAppointmentEditor.m
*/

@class NSArray, NSMutableArray;
@class LSCommandContext;

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

- (void)setAppointment:(id)_apt;
- (id)appointment;
- (void)setContext:(LSCommandContext *)_ctx;
- (LSCommandContext *)context;

// add a datasource to look for conflicting entries
// _ds should handle SkyAppointmentQualifier
- (void)addDataSource:(EODataSource *)_ds;

@end

#endif /* __SkySchedulerConflictDataSource_H__ */
