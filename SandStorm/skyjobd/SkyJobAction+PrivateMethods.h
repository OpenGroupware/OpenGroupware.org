/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#ifndef __SkyJobAction_PrivateMethods_H__
#define __SkyJobAction_PrivateMethods_H__

#include "SkyJobAction.h"

@class NSNumber, NSString, NSArray, NSDictionary, NSCalendarDate;
@class SkyJobQualifier;

@interface SkyJobAction(PrivateMethods)
- (NSNumber *)_setJobStatus:(NSString *)_status
  forJobId:(NSString *)_id
  withComment:(NSString *)_comment;
- (NSArray *)_getJobsWithQualifier:(SkyJobQualifier *)_qual;
- (BOOL)_executantIsTeam:(NSString *)_executantId;
- (NSDictionary *)_buildDictionaryForAttributes:(NSString *)_query
  :(NSString *)_personURL:(NSString *)_teamId
  :(NSString *)_sel:(NSString *)_key:(NSNumber *)_ordering:(NSNumber *)_groups;

/* valid dictionary elements */

- (id)_validStartDate:(NSDate *)_date;
- (id)_validEndDate:(NSDate *)_date;
- (NSString *)_validExecutantId:(NSString *)_executantId;
- (NSNumber *)_validPriority:(NSNumber *)_priority;

@end /* SkyJobAction(PrivateMethods) */

#endif /* __SkyJobAction_PrivateMethods_H__ */
