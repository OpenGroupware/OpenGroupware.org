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

#ifndef __LSAddress_LSVCardNameFormatter_H__
#define __LSAddress_LSVCardNameFormatter_H__

#import <Foundation/NSFormatter.h>

/*
  LSVCardFormattedNameFormatter
  
  This generates a value suitable for use with the vCard "FN" property. The
  format is:
  
    FN:givenname lastname
  
  And its 'clever' about missing values.
*/

@interface LSVCardFormattedNameFormatter : NSFormatter

+ (id)formatter;

- (NSString *)fnForPerson:(id)_person;

@end

/*
  LSVCardNameFormatter
  
  This generates a value suitable for use with the vCard "N" property. The
  format is:
    N:lastname;givenname;additional names;honorific prefixes;
       honorifix suffixes

  the KVC keys used from the object are:
    name
    firstname
    middlename
    degree
    other_title1
    other_title2
*/

@interface LSVCardNameFormatter : LSVCardFormattedNameFormatter
@end

#endif /* __LSAddress_LSVCardNameFormatter_H__ */
