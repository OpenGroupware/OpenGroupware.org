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

#ifndef __Backend_SxTaskManager_H__
#define __Backend_SxTaskManager_H__

#include <ZSBackend/SxBackendManager.h>

/*
  SxTaskManager
  
  Manages task records (jobs in SKYRiX).
*/

@class NSString, NSEnumerator, NSNumber, NSException, NSArray;

@interface SxTaskManager : SxBackendManager
{
}

/* list queries, returns: jobId, title */

- (NSEnumerator *)listTasksOfGroup:(id)_group type:(NSString *)_type;
- (int)countTasksOfGroup:(id)_group type:(NSString *)_type;

/* evo searches, returns: .. */

- (NSEnumerator *)evoTasksOfGroup:(id)_group type:(NSString *)_type;

/* modifications */

- (id)eoForPrimaryKey:(NSNumber *)_key;
- (NSException *)deleteRecordWithPrimaryKey:(NSNumber *)_key;

- (NSArray *)fetchTasksOfGroup:(id)_group type:(NSString *)_type;

@end

#endif /* __Backend_SxTaskManager_H__ */
