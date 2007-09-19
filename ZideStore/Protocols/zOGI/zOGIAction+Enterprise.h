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

#ifndef __zOGIAction_Enterprise_H__
#define __zOGIAction_Enterprise_H__

#include "zOGIAction.h"

@interface zOGIAction(Enterprise)

-(NSArray *)_renderEnterprises:(NSArray *)_enterprises 
                    withDetail:(NSNumber *)_detail;

-(NSArray *)_getUnrenderedEnterprisesForKeys:(id)_arg;

-(id)_getUnrenderedEnterpriseForKey:(id)_arg;

-(id)_getEnterprisesForKeys:(id)_arg 
                 withDetail:(NSNumber *)_detail;
-(id)_getEnterpriseForKeys:(id)_pk;

-(id)_getEnterpriseForKey:(id)_pk 
                withDetail:(NSNumber *)_detail;

-(id)_getEnterpriseForKey:(id)_pk;

-(void)_addProjectsToEnterprise:(NSMutableDictionary *)_enterprise;

-(void)_addContactsToEnterprise:(NSMutableDictionary *)_enterprise;

-(NSArray *)_getFavoriteEnterprises:(NSNumber *)_detail;

-(id)_searchForEnterprises:(NSArray *)_query 
                withDetail:(NSNumber *)_detail
                 withFlags:(NSDictionary *)_flags;

-(id)_deleteEnterprise:(NSString *)_objectId 
             withFlags:(NSArray *)_flags;

-(NSString *)_translateEnterpriseKey:(NSString *)_key;

-(id)_createEnterprise:(NSDictionary *)_enterprise 
             withFlags:(NSArray *)_flags;

-(id)_updateEnterprise:(NSDictionary *)_enterprise
              objectId:(NSString *)_objectId
             withFlags:(NSArray *)_flags;

-(id)_writeEnterprise:(NSDictionary *)_enterprise
          withCommand:(NSString *)_command
            withFlags:(NSArray *)_flags;

-(NSException *)_savePersonsToEnterprise:(NSArray *)_assignments 
                                objectId:(id)_objectId;

-(NSException *)_saveBusinessCards:(NSArray *)_contacts
                      enterpriseId:(id)_enterpriseId
                       defaultACLs:(id)_defaultACLs;
@end

#endif /* __zOGIAction_Enterprise_H__ */
