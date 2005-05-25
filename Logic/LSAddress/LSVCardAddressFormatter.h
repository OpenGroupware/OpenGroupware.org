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

#ifndef __LSAddress_LSVCardAddressFormatter_H__
#define __LSAddress_LSVCardAddressFormatter_H__

#import <Foundation/NSFormatter.h>

/*
  LSVCardAddressFormatter
  
  Converts an address object with the KVC string keys
  
    street, city, zip, country, state
    
  into a vCard string value to be used with the ADR vCard property which is:

    pobox;extaddr;street;city;state;zip;country
  
  Note: OGo addresses are also generated as vCard labels (LABEL properties).
*/

@interface LSVCardAddressFormatter : NSFormatter
+ (id)formatter;
@end

#endif /* __LSAddress_LSVCardAddressFormatter_H__ */
