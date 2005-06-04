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

#ifndef __LSLogic_LSAddress_LSSetCompanyCommand_H__
#define __LSLogic_LSAddress_LSSetCompanyCommand_H__

#include <LSFoundation/LSDBObjectSetCommand.h>

@class NSString, NSArray, NSData;

/*
  LSSetCompanyCommand

  Subclasses:
    person::set
    enterprise::set
    TODO?

  Handling of phone numbers

    Apparently phone number handling is automagic. The "telephones" argument
    can be set to configure those, the command will create them automagically.
    A single record is an NSDictionary containing those keys:
      type
      number
      info
      telephoneId (to change exisiting numbers)
*/

@interface LSSetCompanyCommand : LSDBObjectSetCommand
{
@private
  NSString *comment; // used in company_info
  NSArray  *telephones;
  NSData   *pictureData;
  NSString *pictureFilePath;
  BOOL     deleteImage;
  BOOL     loginStatus;
}

// accessors

- (void)setComment:(NSString *)_comment;
- (NSString *)comment;

@end

#endif /* __LSLogic_LSAddress_LSSetCompanyCommand_H__ */
