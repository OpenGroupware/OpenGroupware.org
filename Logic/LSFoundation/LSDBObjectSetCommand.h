/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#ifndef __LSLogic_LSFoundation_LSDBObjectSetCommand_H__
#define __LSLogic_LSFoundation_LSDBObjectSetCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSNumber;

/*
  LSDBObjectSetCommand runs a database update for a given object.

  The command either requires a primary key of an object or the object itself.
  In case the primary key is being used, the object is automatically retrieved
  from the store.

    _prepareForExecutionInContext:
      sets the 'status' to 'updated'
      in case the 'primaryKey' attribute is being used, get the object
      initialize object with the recordDict values

    _executeInContext:
      run -updateObject: in the database
*/

@interface LSDBObjectSetCommand : LSDBObjectBaseCommand
{
  NSNumber *checkAccess;
}

/* command methods */

- (NSArray  *)_fetchRelationForEntity:(EOEntity *)_entity;

- (void)_prepareForExecutionInContext:(id)_context;
- (void)_executeInContext:(id)_context;

- (void)bumpChangeTrackingFields;

/* accessors */

- (void)setCheckAccess:(NSNumber *)_n;
- (NSNumber *)checkAccess;

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key;
- (id)valueForKey:(NSString *)_key;

@end

#endif /* __LSLogic_LSFoundation_LSDBObjectSetCommand_H__ */
