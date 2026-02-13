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

#ifndef __LSLogic_LSFoundation_LSDBObjectNewKeyCommand_H__
#define __LSLogic_LSFoundation_LSDBObjectNewKeyCommand_H__

#include <LSFoundation/LSBaseCommand.h>

@class EOEntity;

/**
 * @class LSDBObjectNewKeyCommand
 * @brief Command that generates new primary keys for a given
 *   entity.
 *
 * Delegates to the EOAdaptorChannel's
 * -primaryKeyForNewRowWithEntity: to obtain a new primary key.
 * Keys are generated in batches (default batch size 10) and
 * cached in the command context to reduce database round-trips
 * for consecutive inserts.
 *
 * Registered as the "system::newkey" command and used
 * internally by LSDBObjectNewCommand.
 *
 * @see LSDBObjectNewCommand
 * @see LSBaseCommand
 */
@interface LSDBObjectNewKeyCommand : LSBaseCommand
{
@protected
  EOEntity *entity;
}

// accessors

- (void)setEntity:(EOEntity *)_entity;
- (EOEntity *)entity;

@end

#endif /* __LSLogic_LSFoundation_LSDBObjectNewKeyCommand_H__ */
