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

#ifndef __zOGIAction_Contact_H__
#define __zOGIAction_Contact_H__

#include "zOGIAction.h"

@interface zOGIAction(Contact)

-(NSArray *)_renderContacts:(NSArray *)_contacts 
                 withDetail:(NSNumber *)_detail;
-(NSArray *)_getUnrenderedContactsForKeys:(id)_arg;
-(id)_getUnrenderedContactForKey:(id)_arg;
-(id)_getContactsForKeys:(id)_arg withDetail:(NSNumber *)_detail;
-(id)_getContactsForKeys:(id)_arg;
-(id)_getContactForKey:(id)_pk withDetail:(NSNumber *)_detail;
-(id)_getContactForKey:(id)_pk;
-(NSException *)_addEnterprisesToPerson:(NSMutableDictionary *)_contact;
-(NSException *)_addProjectsToPerson:(NSMutableDictionary *)_contact;
-(NSException *)_addMembershipToPerson:(NSMutableDictionary *)_contact;
-(NSArray *)_getFavoriteContacts:(NSNumber *)_detail;
-(id)_searchForContacts:(NSArray *)_query 
             withDetail:(NSNumber *)_detail
              withFlags:(NSDictionary *)_flags;
-(NSString *)_translateContactKey:(NSString *)_key;
-(id)_deleteContact:(NSString *)_objectId
          withFlags:(NSArray *)_flags;
-(id)_createContact:(NSDictionary *)_contact
               withFlags:(NSArray *)_flags;
-(id)_updateContact:(NSDictionary *)_contact
           objectId:(NSString *)_objectId
          withFlags:(NSArray *)_flags;

-(id)_writeContact:(NSDictionary *)_contact
       withCommand:(NSString *)_command
         withFlags:(NSArray *)_flags;

-(NSException *)_saveEnterprisesToPerson:(NSArray *)_assignments 
                                objectId:(id)_objectId;
@end

#endif /* __zOGIAction_Contact_H__ */
