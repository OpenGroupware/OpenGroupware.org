/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#ifndef __LSFoundation_NGBundleManager_OGo_H__
#define __LSFoundation_NGBundleManager_OGo_H__

#include <NGExtensions/NGBundleManager.h>

@interface NGBundleManager(OGo)

/* search directory _p for all bundles ending in _type, load them */
- (void)loadBundlesOfType:(NSString *)_type inPath:(NSString *)_p;

- (void)loadBundlesOfType:(NSString *)_type typeDirectory:(NSString *)_dir
  inPaths:(NSArray *)_paths;

@end

#endif /* __LSFoundation_NGBundleManager_OGo_H__ */
