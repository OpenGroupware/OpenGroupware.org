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
// $Id$

#import <EOControl/EODataSource.h>

@class LSCommandContext, NSMutableArray;

@interface SkySchedulerConflictDataSource : EODataSource
{
  /* execution context */
  LSCommandContext *lso;
  
  /* appointment to check for conflicts */
  id      appointment;

  /* additional datasource to look for conflicts */
  NSMutableArray *dataSources;
  
  /* result cache */
  NSArray *conflicts;
}

- (void)setAppointment:(id)_apt;
- (id)appointment;
- (void)setContext:(id)_ctx;
- (id)context;

// add a datasource to look for conflicting entries
// _ds should handle SkyAppointmentQualifier
- (void)addDataSource:(EODataSource *)_ds;

- (BOOL)hasConflicts;

@end
