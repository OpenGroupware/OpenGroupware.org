/*
  Copyright (C) 2005 SKYRIX Software AG

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

#ifndef __LSAddress_LSVCardCompanyFormatter_H__
#define __LSAddress_LSVCardCompanyFormatter_H__

#import <Foundation/NSFormatter.h>

/*
  LSVCardCompanyFormatter
  
  An abstract superclass for
    LSVCardTeamFormatter
    LSVCardPersonFormatter
    LSVCardEnterpriseFormatter

  All of the formatters expect the EO object (or something with the same KVC
  API). The latter two also need prefetched addresses in the 'addresses' key!

  Identifier generation (UID and SOURCE properties):
    - we have a source_url
      - if the value is not a URL (no ://)
        => use value as UID, create the special UID-URI prefix for SOURCE
      - if the value is a URL
        - if the URL is the special UID-URI
          => use UID from URI as UID and URI as SOURCE
        - other URL
          => use URL as UID and SOURCE (same value)
    - we have no source_url
      => use OGo URL as UID and SOURCE (same value)

  Phone generation:
    TODO

  Address generation:
    for each address
    - get the vCard type
      - if OGo type starts with "V:", use the remainder as the vCard type
        - beware: OGo internally needs uniqued types per contact! you cannot
                  have "two" private addresses
      - otherwise use LSVCard_AddressMapping
      - if no type is given, generate none
    - generate the ADR   property with the type, use formatter for value
    - generate the LABEL property with the type, use formatter for value
*/

@class NSString, NSMutableString;

extern NSString *LSVUidPrefix;

@interface LSVCardCompanyFormatter : NSFormatter

+ (id)formatter;

/* vCard formatting */

- (void)_appendTextValue:(NSString *)_str toVCard:(NSMutableString *)_vCard;
- (void)_appendName:(NSString *)_name andValue:(id)_value
  toVCard:(NSMutableString *)_vCard;

/* common company stuff */

- (void)_appendIdentifier:(id)_contact         toVCard:(NSMutableString *)_ms;
- (void)_appendContactData:(id)_contact        toVCard:(NSMutableString *)_ms;
- (void)_appendAddressData:(id)_contact        toVCard:(NSMutableString *)_ms;
- (void)_appendTelephoneData:(id)_company      toVCard:(NSMutableString *)_ms;
- (void)_appendExtendedAttributes:(id)_contact toVCard:(NSMutableString *)_ms;

/* main entry */

- (void)appendContentForObject:(id)_company toString:(NSMutableString *)_ms;
- (NSString *)stringForObjectValue:(id)_company;

@end

@interface LSVCardTeamFormatter : LSVCardCompanyFormatter
@end

@interface LSVCardPersonFormatter : LSVCardCompanyFormatter
@end

@interface LSVCardEnterpriseFormatter : LSVCardCompanyFormatter
@end

#endif /* __LSAddress_LSVCardCompanyFormatter_H__ */
