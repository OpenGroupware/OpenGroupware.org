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

#ifndef __OGoQuotaTabConfigFile_H__
#define __OGoQuotaTabConfigFile_H__

#include "OGoConfigFile.h"

@class NSString, NSArray, NSDictionary;

@interface OGoQuotaTabConfigFile : OGoConfigFile
{
  BOOL     ignoreExportFlag;
  BOOL     ignoreTeamsFlag;

  NSString *rawPrefix;
  NSString *rawSuffix;
}

/* accessors */

- (BOOL)ignoreExportFlag;
- (BOOL)ignoreTeamsFlag;
- (NSString *)rawPrefix;
- (NSString *)rawSuffix;

/* fetching */

- (NSDictionary *)quotaTabEntryForAccount:(id)_account inContext:(id)_ctx;
- (NSDictionary *)quotaTabEntryForTeam:(id)_team inContext:(id)_ctx;
- (NSArray *)generateQuotaTabEntriesInContext:(id)_ctx;

@end

#endif /* __OGoQuotaTabConfigFile_H__ */
