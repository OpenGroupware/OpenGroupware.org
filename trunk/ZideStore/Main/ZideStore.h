/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#ifndef __ZideStore_H__
#define __ZideStore_H__

#include <NGObjWeb/SoApplication.h>

/*
  The Application class is also the "root" object. Just below the root object
  are the "home directories" of class SxUserFolder.
  
  The root object contains the common authenticator and provides access to
  the connection pool.
*/

@class NSMutableSet;
@class OGoContextManager;

@interface ZideStore : SoApplication
{
  OGoContextManager *lso;
  unsigned int      vMemSizeLimit;
  NSMutableSet      *knownLogins;
}

@end

#endif /* __ZideStore_H__ */
