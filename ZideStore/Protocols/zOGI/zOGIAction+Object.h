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

#ifndef __zOGIAction_Object_H__
#define __zOGIAction_Object_H__

#include "zOGIAction.h"
#include "zOGIAction+Property.h"

@interface zOGIAction(Object)

-(NSDictionary *)_getObjectByObjectId:(id)_objectId 
                           withDetail:(NSNumber *)_detail;
-(void)_addObjectDetails:(NSMutableDictionary *)_object 
              withDetail:(NSNumber *)_detail;
-(NSException *)_addACLsToObject:(NSMutableDictionary *)_object;
-(NSException *)_saveACLs:(NSArray *)_acls 
                forObject:(id)_objectId
               entityName:(id)_entityName;
-(void)_addLinksToObject:(NSMutableDictionary *)_object;
-(void)_addLogsToObject:(NSMutableDictionary *)_object;
-(id)_translateObjectLink:(NSDictionary *)_link 
               fromObject:(id)_objectId;
-(NSException *)_saveObjectLinks:(NSArray *)_links 
                       forObject:(NSString *)_objectId;
-(NSDictionary *)_makeUnknownObject:(id)_objectId;
-(void)_unfavoriteObject:(id)_objectId defaultKey:(NSString *)_key;
-(void)_favoriteObject:(id)_objectId defaultKey:(NSString *)_key;

@end /* End zOGIAction(Object) */

#endif /* __zOGIAction_Object_H__ */
