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

#ifndef __LSLogic_LSFoundation_LSDBArrayFilterCommand_H__
#define __LSLogic_LSFoundation_LSDBArrayFilterCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSNumber;

/**
 * @class LSDBArrayFilterCommand
 * @brief Abstract database-aware filter command that selects
 *   objects from an input array.
 *
 * Like LSArrayFilterCommand, but inherits from
 * LSDBObjectBaseCommand so that subclasses have access to the
 * database channel and entity model during filtering.
 * Subclasses override -includeObjectInResult: to implement
 * the filter predicate.
 *
 * When "removeFromSource" is set to YES, matching objects are
 * also removed from the original source array.
 *
 * @see LSArrayFilterCommand
 * @see LSDBObjectBaseCommand
 */
@interface LSDBArrayFilterCommand : LSDBObjectBaseCommand
{
@private
  NSNumber *removeFromSource;
}

- (BOOL)includeObjectInResult:(id)_object;
- (BOOL)includeObjectInResult:(id)_object replacementObject:(id *)_newObject;

@end

#endif /* __LSLogic_LSFoundation_LSDBArrayFilterCommand_H__ */
