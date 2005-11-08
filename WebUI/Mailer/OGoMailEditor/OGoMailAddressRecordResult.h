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

#ifndef __OGoWebMail_OGoMailAddressRecordResult_H__
#define __OGoWebMail_OGoMailAddressRecordResult_H__

#import <Foundation/NSObject.h>

/*
  OGoMailAddressRecordResult
  
  This is used in the RecipientsPopup inside LSWImapMailEditor. The 'email'
  is the selected record.
  
  This object manages three things:
  a) the array of email records which matched a search
  b) the selected email record
  c) the type of the recipient field (to/cc/bcc)
*/

@class NSString, NSArray;

@interface OGoMailAddressRecordResult : NSObject
{
  NSString *header;
  id       email;
  NSArray  *emails;
}

/* accessors */

- (void)setEMails:(NSArray *)_mails;
- (void)setHeader:(NSString *)_header;
- (void)setEMail:(id)_email;

/* mimic dictionary */

- (unsigned)count;

@end

#endif /* __OGoWebMail_OGoMailAddressRecordResult_H__ */
