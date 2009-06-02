/*
  Copyright (C) 2006-2007 Whitemice Consulting

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

#ifndef __zOGIAction_H__
#define __zOGIAction_H__

#include <ZSFrontend/SxFolder.h>
#include <ZSFrontend/SxObject.h>
#include <zOGIDetailLevels.h>
#include <NSObject+zOGI.h>
#include "common.h"

@interface zOGIAction : WODirectAction
{
  id                   arg1, arg2, arg3, arg4;
  int                  debugging;
  LSCommandContext    *ctx;
  NSMutableDictionary *eoCache;
}

/* accessors */

- (BOOL)isDebug;
- (BOOL)isProfile;
- (BOOL)allowTaskDelete;
- (BOOL)sendMailNotifications;
- (void)setArg1:(id)_arg;
- (void)setArg2:(id)_arg;
- (void)setArg3:(id)_arg;
- (void)setArg4:(id)_arg;
- (id)arg1;
- (id)arg2;
- (id)arg3;
- (id)arg4;
- (id)defaultAction;
- (LSCommandContext *)getCTX;
- (id)_getGlobalId;
- (NSNumber *)_getCompanyId;
- (NSTimeZone *)_getTimeZone;

/* methods */

- (id)NIL:(id)_arg;
- (NSNumber *)ZERO:(id)_arg;
- (EOGlobalID *)_getEOForPKey:(id)_arg;
- (NSArray *)_getEOsForPKeys:(id)_arg;
- (NSString *)_getEntityNameForPKey:(id)_arg;
- (NSString *)_izeEntityName:(NSString *)_arg;
- (id)_checkEntity:(id)_pkey entityName:(id)_name;
- (NSString *)_getPKeyForEO:(EOKeyGlobalID *)_arg;
- (NSCalendarDate *)_makeCalendarDate:(id)_date;
- (NSCalendarDate *)_makeCalendarDate:(id)_date withZone:(id)_timeZone;
- (void)_stripInternalKeys:(NSMutableDictionary *)_dictionary;


@end /* zOGIAction */

#endif /* __zOGIAction_H__ */
