/*
  Copyright (C) 2008 Whitemice Consulting (Adam Tauno Williams)

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

#ifndef __RSS2_SxFolder_H__
#define __RSS2_SxFolder_H__

#include <LSFoundation/LSFoundation.h>
#include <LSFoundation/LSCommandContext.h>
#include <ZSFrontend/SxFolder.h>
#include <ZSFrontend/SxObject.h>
#include "common.h"

@interface SxFolder(RSS2)

- (NSString *)rssContentForFeed:(NSString *)_feed 
                      withLimit:(NSNumber *)_limit
                          atURL:(NSString *)_url
                      inContext:(LSCommandContext *)_ctx;

- (WOResponse *)rssContentForFeed:(NSString *)_feed inContext:(id)_ctx;
@end

#endif /* __RSS2_SxFolder_H__ */
