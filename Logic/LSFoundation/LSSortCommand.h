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

#ifndef __LSLogic_LSFoundation_LSSortCommand_H__
#define __LSLogic_LSFoundation_LSSortCommand_H__

#include <LSFoundation/LSBaseCommand.h>

/**
 * @class LSSortCommand
 * @brief Command that sorts an array using LSSort.
 *
 * LSSortCommand is a Logic command that wraps LSSort to
 * sort a list of objects by a given attribute key. It
 * does not require a database channel or transaction.
 * The sorted array is returned as the command result.
 *
 * @see LSSort
 * @see LSBaseCommand
 */
@interface LSSortCommand : LSBaseCommand
{
@private 
  id         sortAttribute;
  NSArray    *sortList;
  LSOrdering ordering;
}

- (void)setSortAttribute:(id)_sortAttribute;
- (id)sortAttribute;
- (void)setSortList:(NSArray *)_sortList;
- (NSArray *)sortList;
- (void)setOrdering:(LSOrdering)_ordering;
- (LSOrdering)ordering;

@end

#endif /* __LSLogic_LSFoundation_LSSortCommand_H__ */
