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

#ifndef __SkyContactDaemon_SkyContactAction_QueryMethods_H__
#define __SkyContactDaemon_SkyContactAction_QueryMethods_H__

#include "SkyContactAction.h"

@class NSArray, NSString, NSDictionary, NSNumber;
@class EOGlobalID;

@interface SkyContactAction(QueryMethods)

- (NSArray *)getObjectsForURLs:(NSArray *)_urls
  entity:(NSString *)_entity;
- (NSDictionary *)argumentsForAdvancedSearch:(NSDictionary *)_attrs
  extendedAttributes:(NSDictionary *)_extAttrs
  maxSearchCount:(NSNumber *)_maxSearchCount
  entity:(NSString *)_entity;
- (NSString *)teamNameForTeamWithGID:(EOGlobalID *)_teamGID;

@end /* SkyContactAction(QueryMethods) */


#endif /* __SkyContactDaemon_SkyContactAction_QueryMethods_H__ */
