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

#ifndef __Backend_SxFreeBusyManager_H__
#define __Backend_SxFreeBusyManager_H__

#import <Foundation/NSObject.h>

@class NSString, NSCalendarDate, NSArray;
@class EOAdaptor, EOAdaptorContext, EOAdaptorChannel;
@class EOModel;

@interface SxFreeBusyManager : NSObject
{
  EOAdaptor        *adaptor;
  EOAdaptorContext *context;
  EOAdaptorChannel *channel;
  EOModel          *model;
}

+ (id)freeBusyManager;

- (id)emailForLogin:(NSString *)_login;

// return NSArray or NSException
- (id)freeBusyDataForEmail:(NSString *)_email;

- (id)freeBusyDataForEmail:(NSString *)_email
                      from:(NSCalendarDate *)_from
                        to:(NSCalendarDate *)_to;

- (id)freeBusyDataForCompanyId:(id)_companyId;

- (id)freeBusyDataForCompanyId:(id)_companyId
                          from:(NSCalendarDate *)_from
                            to:(NSCalendarDate *)_to;

- (id)freeBusyDataForLogin:(id)_login;

- (id)freeBusyDataForLogin:(id)_login
                      from:(NSCalendarDate *)_from
                        to:(NSCalendarDate *)_to;

@end /* SxFreeBusyManager */

#endif /* __Backend_SxFreeBusyManager_H__ */
