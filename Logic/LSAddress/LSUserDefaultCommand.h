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

#ifndef __LSLogic_LSAddress_LSUserDefaultCommand_H__
#define __LSLogic_LSAddress_LSUserDefaultCommand_H__

#include <LSFoundation/LSBaseCommand.h>

/**
 * @class LSUserDefaultCommand
 *
 * Command for getting, setting, and deleting individual
 * per-user default values.
 *
 * Operates on the LSUserDefaults storage for the current
 * account. The @c mode enum selects the operation
 * (get, set, or delete), and the @c kind enum selects the
 * value type (object, string, int, float, array, or
 * dictionary).
 *
 * Accepts a @c key and an optional @c value via KVC.
 */
@interface LSUserDefaultCommand : LSBaseCommand
{
  NSString *key;
  id       value;
  
  enum {
    def_mode_empty = 0,
    def_set        = 1,
    def_get        = 2,
    def_del        = 3
  } mode;
  enum {
    def_object       = 0,
    def_string       = 1,
    def_intNumber    = 2,
    def_floatNumber  = 3,
    def_array        = 4,
    def_dictionary   = 5
  } kind;
}

@end

#endif /* __LSLogic_LSAddress_LSUserDefaultCommand_H__ */
