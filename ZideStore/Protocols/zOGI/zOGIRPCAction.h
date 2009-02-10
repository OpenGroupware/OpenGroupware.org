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

#ifndef __zOGIRPCAction_H__
#define __zOGIRPCAction_H__

/*
  OGI Schedular Action
*/

@interface zOGIRPCAction : zOGIAction
{
}

/* methods */
-(id)getTypeOfObjectAction;
-(id)getFavoritesByTypeAction;
-(id)flagFavoritesAction;
-(id)unflagFavoritesAction;
-(id)getObjectsByObjectIdAction;
-(id)getObjectByObjectIdAction;
-(id)getObjectVersionsByObjectIdAction;
-(id)putObjectAction;
-(id)deleteObjectAction;
-(id)searchForObjectsAction;
-(id)getNotificationsAction;
-(id)_createObject:(id)_dictionary
          withFlags:(NSArray *)_flags;
-(id)_updateObject:(id)_dictionary 
          objectId:(NSString *)_objectId
         withFlags:(NSArray *)_flags;
-(id)_searchForTimeZones:(id)_criteria
              withDetail:(id)_detail
               withFlags:(id)_flags;
-(id)_getServerTime;
-(id)getAuditEntriesAction;
@end

#endif /* __zOGIRPCAction_H__ */

