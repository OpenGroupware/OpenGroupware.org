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
// $Id: SxGroupsFolder.h 1 2004-08-20 11:17:52Z znek $

#ifndef __Contacts_SxGroupsFolder_H__
#define __Contacts_SxGroupsFolder_H__

#include "SxAddressFolder.h"

/*
  SxGroupsFolder
  
  A folder which contains all groups of the login account. Besides representing
  the groups as contact records, it also creates sub-collections of class
  SxGroupFolder for each of them.
  
  Note: do not mix that up with SxGroupFolder, which contains the members of
  a group. This group contains no account records, only groups and is usually
  the parent collection of a SxGroupFolder.
*/

@interface SxGroupsFolder : SxAddressFolder
{
}

- (id)groupFolder:(NSString *)_name inContext:(id)_ctx;

@end

#endif /* __Contacts_SxGroupsFolder_H__ */
