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
// $Id: SxEvoContactRenderer.h 1 2004-08-20 11:17:52Z znek $

#ifndef __Contacts_SxEvoContactRenderer_H__
#define __Contacts_SxEvoContactRenderer_H__

#import <Foundation/NSObject.h>

@class NSString, NSMutableString;
@class SxFolder;

@interface SxEvoContactRenderer : NSObject
{
  SxFolder *folder;
  NSString *baseURL;
  id       context; /* non-retained */
  
  NSMutableString *ms;
}

+ (id)rendererWithFolder:(SxFolder *)_folder inContext:(id)_ctx;
- (id)initWithFolder:(SxFolder *)_folder inContext:(id)_ctx;

/* rendering */

- (NSString *)renderAddressWithPrefix:(NSString *)_prefix from:(id)_object;
- (id)renderEntry:(id)_entry;
- (id)postProcessRecord:(id)_record;

@end /* SxEvoContactRenderer */

#endif /* __Contacts_SxEvoContactRenderer_H__ */
