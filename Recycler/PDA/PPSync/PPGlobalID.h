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

#ifndef __PPSync_PPGlobalID_H__
#define __PPSync_PPGlobalID_H__

#import <EOControl/EOGlobalID.h>

@interface PPGlobalID : EOGlobalID
{
  unsigned long creator;
  unsigned long type;
  NSString      *dbName;
  unsigned long uniqueID;
}

+ (id)ppGlobalIDForCreator:(unsigned long)_c type:(unsigned long)_t
  databaseName:(NSString *)_dbName uniqueID:(unsigned long)_uid;

- (NSString *)entityName;
- (unsigned long)creator;
- (unsigned long)type;
- (unsigned long)uniqueID;

@end

#endif /* __PPSync_PPGlobalID_H__ */
