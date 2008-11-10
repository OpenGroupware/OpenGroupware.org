/*
  Copyright (C) 2003-2008 SKYRIX Software AG

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

#include <LSFoundation/LSFoundation.h>
#include <LSFoundation/LSCommandContext.h>
#include <ZSTasks/SxTaskFolder.h>
#include "SxRSSTaskRenderer.h"
#include <ZSFrontend/SxFolder.h>
#include "SxFolder+RSS2.h"
#include <ZSFrontend/SxObject.h>
#include "common.h"

@implementation SxTaskFolder(RSS)

/* 
   hack: in "real" SOPE this should be a "category-bound" attribute in the
         products.plist! That is, you define an attribute "rss" for the SoClass
         SxTaskFolder and SOPE will create the SxRSSTaskRenderer automagically.
*/

/* implements "old" RSS support that reports tasks themselves */
- (id)rssInContext:(id)_ctx {
  // TODO: implement as SoMethod!
  id renderer;
  
  if ((renderer = [SxRSSTaskRenderer renderer]) != nil)
    return [renderer rssResponseForFolder:self inContext:_ctx];
  
  return [NSException exceptionWithHTTPStatus:500
                      reason:@"RSS task rendering failed"];
}

- (id)rssDelegatedActionsFeed:(id)_ctx {
  return [self rssContentForFeed:@"job::get-delegated-rss"
                       inContext:(id)_ctx];
}

- (id)rssToDoActionsFeed:(id)_ctx {
  return [self rssContentForFeed:@"job::get-todo-rss"
                       inContext:(id)_ctx];
}

- (id)rssProjectActionsFeed:(id)_ctx {
  return [self rssContentForFeed:@"job::get-project-task-rss"
                       inContext:(id)_ctx];
}

@end /* SxTaskFolder(RSS) */
