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

#ifndef __LSLogic_LSFoundation_LSGetObjectForGlobalIDs_H__
#define __LSLogic_LSFoundation_LSGetObjectForGlobalIDs_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  LSGetObjectForGlobalIDs

  This class is a superclass for commands which fetch objects based on a list
  of EOGlobalIDs.
*/

@class NSNumber, NSString, NSArray;

@interface LSGetObjectForGlobalIDs : LSDBObjectBaseCommand
{
  NSArray  *gids;
  NSArray  *attributes;
  NSArray  *sortOrderings;
  NSString *groupBy;
  NSNumber *noAccessCheck;
}

/* subclasses overwride this methods */

- (EOSQLQualifier *)validateQualifier:(EOSQLQualifier *)_qual;
- (void)fetchAdditionalInfosForObjects:(NSArray *)_obj context:(id)_context;

@end

#endif /* __LSLogic_LSFoundation_LSGetObjectForGlobalIDs_H__ */
