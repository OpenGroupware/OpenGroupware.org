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

#ifndef __SkyDBAction_H__
#define __SkyDBAction_H__

#include <OGoDaemon/SDXmlRpcAction.h>

@class EOAdaptorDataSource;
@class EOAdaptor, EOAdaptorContext, EOAdaptorChannel;

@interface SkyDBAction : SDXmlRpcAction
{
  EOAdaptor           *adaptor;
  EOAdaptorContext    *adCtx;
  EOAdaptorChannel    *adCh;
  EOAdaptorDataSource *databaseDataSource;
  BOOL didOpenChannel;
  BOOL didStartTx;
}

- (EOAdaptorDataSource *)databaseDataSource;
- (NSString *)adaptorName;
- (NSDictionary *)connectionDictionary;

- (EOAdaptor *)adaptor;
- (EOAdaptorContext *)adaptorContext;
- (EOAdaptorChannel *)adaptorChannel;

@end /* DirectAction */

#endif /* __SkyDBAction_H__ */
