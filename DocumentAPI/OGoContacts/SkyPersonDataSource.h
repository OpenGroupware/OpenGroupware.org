/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#ifndef __Skyrix_SkyrixApps_Libraries_SkyPersons_SkyPersonDataSource_H__
#define __Skyrix_SkyrixApps_Libraries_SkyPersons_SkyPersonDataSource_H__

/*
  EOKeyValueQualifier:

         attr             = "searchString" ->  "person::get"

         fullSearchString = "searchString" ->  "person::full-search"
         
  EOOrQualifier, EOAndQualifier:

         -> "person::extended-search"

         birthday
         comment
         degree
         firstname
         keywords
         lastname
         login
         middlename
         nickname
         number
         password
         salutation
         gender
         url

         address.name1
         address.name2
         address.name3
         address.city
         address.country
         address.street
         address.state
         address.type
         address.zip

         phone.number
         phone.type

   hints:
      fetchIds = "YES" | "NO", default = "NO"

*/

#include <OGoContacts/SkyCompanyDataSource.h>

#define SkyDeletedPersonNotification @"SkyDeletedPersonNotification"
#define SkyUpdatedPersonNotification @"SkyUpdatedPersonNotification"
#define SkyNewPersonNotification     @"SkyNewPersonNotification"

#import <EOControl/EODataSource.h>

@class NSArray;
@class EOQualifier, EOFetchSpecification;

@interface SkyPersonDataSource : SkyCompanyDataSource
@end

#include <OGoDocuments/SkyDocumentManager.h>

@interface SkyPersonDocumentGlobalIDResolver : NSObject
  <SkyDocumentGlobalIDResolver>
@end

#endif /* __Skyrix_SkyrixApps_Libraries_SkyPersons_SkyPersonDataSource_H__ */
