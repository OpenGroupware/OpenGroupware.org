/*
  Copyright (C) 2009 Whitemice Consulting (Adam Tauno Williams)

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

#ifndef __LSFoundation_LSGetCTagForEntityCommand_H__
#define __LSFoundation_LSGetCTagForEntityCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSMutableString;
@class LSCommandContext;

/**
 * @class LSGetCTagForEntityCommand
 *
 * Retrieves the current CTag (change tag) value for a
 * given entity name from the "ctags" database table.
 * CTags are integer counters that are incremented
 * whenever an entity of that type is modified, enabling
 * clients to detect changes without fetching full data.
 *
 * The entity name is set via the "entity" key. The
 * return value is the CTag string. The command performs
 * a rollback after reading to avoid holding a
 * transaction.
 */
@interface LSGetCTagForEntityCommand : LSDBObjectBaseCommand
{
  NSString          *entity;
}

- (NSString *)entity;
- (void)setEntity:(NSString *)_entity;

@end /* LSGetCTagForEntityCommand */

#endif /*  __LSFoundation_LSGetCTagForEntityCommand_H__ */
