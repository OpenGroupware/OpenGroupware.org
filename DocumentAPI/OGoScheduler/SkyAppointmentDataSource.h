/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#ifndef __SkyAppointmentDataSource_H__
#define __SkyAppointmentDataSource_H__

#include <EOControl/EODataSource.h>

#define SkyUpdatedAppointmentNotification @"SkyUpdatedAppointmentNotification"
#define SkyDeletedAppointmentNotification @"SkyDeletedAppointmentNotification"
#define SkyNewAppointmentNotification     @"SkyNewAppointmentNotification"

@class LSCommandContext, EOFetchSpecification;

/*
  Input:
    EOFetchSpecification
      qualifier => SkyAppointmentQualifier
      hints: attributes (NSArray)    => attributes to fetch
             fetchGIDs  (NSArray)    => make SkyAppointentDocuments of it
             timeZone   (NSTimeZone) => timeZone,the qualifier can overwrite it
             fetchGlobalIDs (BOOL)   => return globalIDs (default is NO)

  Ouput:
    Array of SkyAppointmentDocuments
*/

@interface SkyAppointmentDataSource : EODataSource
{
  LSCommandContext     *context;
  EOFetchSpecification *fetchSpecification;
}

- (id)initWithContext:(LSCommandContext *)_ctx;


- (LSCommandContext *)context;

@end

/* TODO: the resolver class does not really need to be public? */

#include <OGoDocuments/SkyDocumentManager.h>

@interface SkyAppointmentDocumentGlobalIDResolver : NSObject
  <SkyDocumentGlobalIDResolver>
@end

#endif /* __SkyAppointmentDataSource_H__ */
