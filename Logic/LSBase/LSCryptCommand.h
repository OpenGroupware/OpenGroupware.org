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

#ifndef __LSLogic_LSFoundation_LSCryptCommand_H__
#define __LSLogic_LSFoundation_LSCryptCommand_H__

#include <LSFoundation/LSBaseCommand.h>

extern char *crypt(const char *key, const char *salt);

/**
 * @class LSCryptCommand
 *
 * Encrypts a password string using the POSIX crypt(3)
 * function. If no salt is provided, a random two-
 * character salt is generated from the current time.
 *
 * The return value is the encrypted password string.
 * Does not require a database channel or transaction.
 *
 * Keys: "password" (the plaintext), "salt" (optional
 * two-character salt).
 */
@interface LSCryptCommand : LSBaseCommand
{
@private 
  NSString *passwd;
  NSString *salt;
}

- (void)setPasswd:(NSString *)_passwd;
- (NSString *)passwd;
- (void)setSalt:(NSString *)_salt;
- (NSString *)salt;

@end

#endif /* __LSLogic_LSFoundation_LSCryptCommand_H__ */
