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

#ifndef __SkyJSSendMail_H__
#define __SkyJSSendMail_H__

#import <Foundation/NSObject.h>

/*
  JavaScript

    properties:
      String - From    - mail sender
      String - To      - mail receiver
      String - Cc      - carbon copy receivers
      String - Body    - mail content
      String - Subject - mail subject

    functions:
      bool send()  - send a mail
*/

@interface SkyJSSendMail : NSObject
{
  NSString *from;
  NSString *to;
  NSString *cc;
  NSString *body;
  NSString *subject;
}

@end

#endif /* __SkyJSSendMail_H__ */
