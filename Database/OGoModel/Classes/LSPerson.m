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

#include "LSPerson.h"
#include "common.h"

@implementation LSPerson
@end /* LSPerson */

@implementation LSPerson(JSSupport)

- (id)_jsprop_version {
  return [self objectForKey:@"objectVersion"];
}

- (id)_jsprop_login {
  return [self objectForKey:@"login"];
}
- (id)_jsprop_name {
  return [self objectForKey:@"name"];
}
- (id)_jsprop_middlename {
  return [self objectForKey:@"middlename"];
}
- (id)_jsprop_firstname {
  return [self objectForKey:@"firstname"];
}

- (id)_jsprop_url {
  return [self objectForKey:@"url"];
}
- (id)_jsprop_degree {
  return [self objectForKey:@"degree"];
}
- (id)_jsprop_salutation {
  return [self objectForKey:@"salutation"];
}
- (id)_jsprop_birthday {
  return [self objectForKey:@"birthday"];
}
- (id)_jsprop_sex {
  return [self objectForKey:@"sex"];
}

@end /* LSPerson(JSSupport) */
