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

#ifndef __SkyCommands_LSBase_LSIncrementCTagCommand_H__
#define __SkyCommands_LSBase_LSIncrementCTagCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

/**
 * @class LSIncrementCTagCommand
 *
 * Increments the CTag (change tag) counter in the
 * "ctags" database table for the entity of the
 * command's current object. This signals to sync
 * clients (e.g. CalDAV/CardDAV) that the collection
 * has been modified.
 *
 * Typically run as a post-processing sub-command after
 * create, update, or delete operations.
 */
@interface LSIncrementCTagCommand : LSDBObjectBaseCommand
{
}

@end

#endif /* __SkyCommands_LSBase_LSIncrementCTagCommand_H__ */
