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

#ifndef __Logic_OGoObjectLinkManager_H__
#define __Logic_OGoObjectLinkManager_H__

#import <Foundation/NSObject.h>

@class NSException, NSArray, NSString;
@class EOAdaptor, EODatabase, EOAdaptorChannel, EOEntity;
@class EOGlobalID, EOKeyGlobalID;
@class OGoObjectLink, LSCommandContext;

@interface OGoObjectLinkManager : NSObject
{
  LSCommandContext *context;
  EOAdaptor        *adaptor;
  EODatabase       *database;
  EOAdaptorChannel *adChannel;
  EOEntity         *entity;
}

- (id)initWithContext:(LSCommandContext *)_ctx;

/* link deletion */

- (NSException *)deleteLinksTo:(EOKeyGlobalID *)_tgid   type:(NSString *)_t;
- (NSException *)deleteLinksFrom:(EOKeyGlobalID *)_sgid type:(NSString *)_t;
- (NSException *)deleteLink:(OGoObjectLink *)_link;
- (NSException *)deleteLinkGID:(EOGlobalID *)_gid;

/* link creation */

- (NSException *)createLink:(OGoObjectLink *)_link;

/* link queries */

- (NSArray *)allLinks:(NSString *)_type;

- (NSArray *)allLinksFrom:(EOKeyGlobalID *)_sgid;
- (NSArray *)allLinksTo:(EOKeyGlobalID *)_tgid;

- (NSArray *)allLinksFrom:(EOKeyGlobalID *)_sgid type:(NSString *)_type;
- (NSArray *)allLinksTo:(EOKeyGlobalID *)_tgid   type:(NSString *)_type;

- (NSArray *)allLinksFrom:(EOKeyGlobalID *)_sgid to:(EOKeyGlobalID *)_tgid
  type:(NSString *)_type;

@end /* OGoObjectLinkManager */

#endif /* __Logic_OGoObjectLinkManager_H__ */
