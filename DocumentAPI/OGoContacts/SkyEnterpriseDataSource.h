/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#ifndef __OGoContacts_SkyEnterpriseDataSource_H__
#define __OGoContacts_SkyEnterpriseDataSource_H__

/*

  EOKeyValueQualifier:

         attr             = "searchString" ->  "enterprise::get"

         person           =  person        ->  "person::get-enterprises"
         
         fullSearchString = "searchString" ->  "enterprise::full-search"
         
  EOOrQualifier, EOAndQualifier:

         -> "enterprise::extended-search"

         birthday
         comment
         degree
         description
         firstname
         keywords
         login
         middlename
         name
         number
         password
         salutation
         sex
         url
         
         address.city
         address.street
         address.zip

         phone.number
         phone.type

   hints:
      fetchIds = "YES" | "NO", default = "NO"

*/

#include <OGoContacts/SkyCompanyDataSource.h>

#define SkyDeletedEnterpriseNotification @"SkyDeletedEnterpriseNotification"
#define SkyUpdatedEnterpriseNotification @"SkyUpdatedEnterpriseNotification"
#define SkyNewEnterpriseNotification     @"SkyNewEnterpriseNotification"

@class NSArray;
@class EOQualifier, EOFetchSpecification;

@interface SkyEnterpriseDataSource : SkyCompanyDataSource
@end

#include <OGoDocuments/SkyDocumentManager.h>

@interface SkyEnterpriseDocumentGlobalIDResolver : NSObject
  <SkyDocumentGlobalIDResolver>
@end

#endif /* __OGoContacts_SkyEnterpriseDataSource_H__ */
