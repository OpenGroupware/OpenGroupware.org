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

#ifndef __SkyPalmAddressDocument_H__
#define __SkyPalmAddressDocument_H__

#include <OGoPalm/SkyPalmDocument.h>

@interface SkyPalmAddressDocument : SkyPalmDocument
{
  // phone values
  NSString *workPhone;
  NSString *homePhone;
  NSString *faxPhone;
  NSString *otherPhone;
  NSString *emailPhone;
  NSString *mainPhone;
  NSString *pagerPhone;
  NSString *mobilePhone;

  // record values
  NSString *address;           // address fields
  NSString *city;
  NSString *company;
  NSString *country;
  int      displayPhone;
  NSString *firstname;
  NSString *lastname;
  NSString *note;
  NSString *phone0;            // phone fields
  NSString *phone1;
  NSString *phone2;
  NSString *phone3;
  NSString *phone4;
  int phoneLabelId0;
  int phoneLabelId1;
  int phoneLabelId2;
  int phoneLabelId3;
  int phoneLabelId4;
  NSString *state;
  NSString *title;
  NSString *zipcode;
  NSString *custom1;          // custom fields
  NSString *custom2;
  NSString *custom3;
  NSString *custom4;

  // skyrix sync
  NSString *skyrixType;       // person or enterprise
}

- (void)setAddress:(NSString *)_address;
- (NSString *)address;           // address fields

- (void)setCity:(NSString *)_city;
- (NSString *)city;

- (void)setCompany:(NSString *)_company;
- (NSString *)company;

- (void)setCountry:(NSString *)_country;
- (NSString *)country;

- (int)displayPhone;

- (void)setFirstname:(NSString *)_firstname;
- (NSString *)firstname;

- (void)setLastname:(NSString *)_lastname;
- (NSString *)lastname;

- (NSString *)note;
- (NSString *)phone0;            // phone fields
- (NSString *)phone1;
- (NSString *)phone2;
- (NSString *)phone3;
- (NSString *)phone4;
- (int)phoneLabelId0;
- (int)phoneLabelId1;
- (int)phoneLabelId2;
- (int)phoneLabelId3;
- (int)phoneLabelId4;

- (void)setState:(NSString *)_state;
- (NSString *)state;

- (void)setTitle:(NSString *)_title;
- (NSString *)title;

- (void)setZipcode:(NSString *)_code;
- (NSString *)zipcode;

- (NSString *)custom1;          // custom fields
- (NSString *)custom2;
- (NSString *)custom3;
- (NSString *)custom4;

- (void)setSkyrixType:(NSString *)_type;
- (NSString *)skyrixType;

// assigned fields
- (NSString *)work;
- (NSString *)other;
- (NSString *)fax;
- (NSString *)email;
- (NSString *)home;

@end /* SkyPalmAddressDocument */

@interface SkyPalmAddressDocumentSelection: SkyPalmDocumentSelection
{}
@end /* SkyPalmAddressDocumentSelection */


#endif /* __SkyPalmAddressDocument_H__ */
