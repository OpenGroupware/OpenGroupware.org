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

#ifndef __LSLogic_LSFoundation_LSDBObjectSetCommand_H__
#define __LSLogic_LSFoundation_LSDBObjectSetCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSNumber;

/*
  LSDBObjectSetCommand faehrt ein Datenbank-Update.

  Benoetigt wird entweder der Primary-Key des Objektes oder das Objekt selbst.
  Wird der Primary-Key benutzt, wird das Objekt automatisch angefordert.

    _prepareForExecutionInContext:
      setzt den 'status' auf 'updated'
      wenn das 'primaryKey' Attribute benutzt wird, hole Objekt
      initialisiere Objekt mit den recordDict-Werten

    _executeInContext:
      fuehrt updateObject in der Datenbank aus
*/

@interface LSDBObjectSetCommand : LSDBObjectBaseCommand
{
  NSNumber *checkAccess;
}

// command methods

- (NSArray  *)_fetchRelationForEntity:(EOEntity *)_entity;

- (void)_prepareForExecutionInContext:(id)_context;
- (void)_executeInContext:(id)_context;

- (NSNumber *)checkAccess;
- (void)setCheckAccess:(NSNumber *)_n;
// key/value coding

- (void)takeValue:(id)_value forKey:(NSString *)_key;
- (id)valueForKey:(NSString *)_key;


@end

#endif /* __LSLogic_LSFoundation_LSDBObjectSetCommand_H__ */
