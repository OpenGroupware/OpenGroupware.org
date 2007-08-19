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

#ifndef __zOGIAction_Company_H__
#define __zOGIAction_Company_H__

#include "zOGIAction.h"

@interface zOGIAction(Company)
-(NSMutableArray *)_renderCompanyFlags:(EOGenericRecord *)_company
                            entityName:(NSString *)_entityName;

-(NSException *)_addAddressesToCompany:(NSMutableDictionary *)_company;

-(NSException *)_addPhonesToCompany:(NSMutableDictionary *)_company;

-(NSException *)_addCompanyValuesToCompany:(NSMutableDictionary *)_company;

-(NSMutableDictionary *)_translateAddress:(NSDictionary *)_address 
                               forCompany:(id)_objectId;

-(NSException *)_saveAddresses:(NSArray *)_addresses 
                    forCompany:(id)_objectId;

-(NSMutableDictionary *)_translatePhone:(NSDictionary *)_phone 
                             forCompany:(id)_objectId;

-(NSException *)_savePhones:(NSArray *)_phones 
                 forCompany:(id)_objectId;

-(id)_writeCompany:(NSDictionary *)_company
       withCommand:(NSString *)_command
         withFlags:(NSArray *)_flags 
        forEntity:(NSString *)_entity;
@end

#endif /* __zOGIAction_Company_H__ */
