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

#ifndef __Resources_SxGroupsFolder_H__
#define __Resources_SxGroupsFolder_H__

#include "SxResourceGroupFolder.h"

/*
  SxGroupsFolder
  
  A folder which contains all resource groups of the login account. Besides
  representing the groups as sub-collections of class SxResourceGroupFolder
  it also contains resources without a group as vcf files.
*/

@interface SxResourceGroupsFolder : SxResourceGroupFolder
{
}

- (id)groupFolder:(NSString *)_name inContext:(id)_ctx;

@end

#endif /* __Resources_SxGroupsFolder_H__ */
