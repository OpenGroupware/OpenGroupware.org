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

#ifndef __JobUI_OGoJobStatus_H__
#define __JobUI_OGoJobStatus_H__

#import <Foundation/NSObject.h>

/*
  Wraps the state string and possible workflow transitions.

  Note: that does not check whether a user is actually allowed to make
        a transition!
*/

#define LSJobCreated    @"00_created"
#define LSJobAccepted   @"05_accepted"
#define LSJobCommented  @"10_commented"
#define LSJobDivided    @"15_divided"
#define LSJobProcessing @"20_processing"
#define LSJobDone       @"25_done"
#define LSJobArchived   @"30_archived"
#define LSJobReactivate @"27_reactivated"
#define LSJobRejected   @"02_rejected"

@interface OGoJobStatus : NSObject
{
  NSString *status;
}

+ (id)jobStatusWithString:(NSString *)_status;
- (id)initWithString:(NSString *)_status;

/* accessors */

- (NSString *)statusString;

/* current status */

- (BOOL)isArchived;
- (BOOL)isCreated;
- (BOOL)isRejected;
- (BOOL)isDone;

/* possible operations */

- (BOOL)allowAcceptTransition;
- (BOOL)allowDoneTransition;
- (BOOL)allowArchiveTransition;
- (BOOL)allowAnnotateTransition;
- (BOOL)allowRejectTransition;
- (BOOL)allowDeleteTransition;

@end

#endif /* __JobUI_OGoJobStatus_H__ */
