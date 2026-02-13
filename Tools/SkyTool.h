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

#ifndef __SkyTool_H__
#define __SkyTool_H__

#import <Foundation/NSObject.h>

/**
 * @class SkyTool
 *
 * Abstract base class for OGo command-line tools. Provides
 * common infrastructure for login/password authentication
 * via NSUserDefaults (-l and -p switches), an
 * LSCommandContext for executing Logic commands, verbose
 * logging, standard --help/--version argument handling,
 * and an optional root-only login requirement.
 *
 * Subclasses override -toolName, -toolDescription,
 * -versionInformation, -additionalSwitches and
 * -runWithArguments: to implement their specific behavior.
 *
 * Exit codes: 1 = missing login, 2 = wrong password/user,
 * 3 = root login required.
 */
@interface SkyTool : NSObject
{
  LSCommandContext *commandContext;
  BOOL             verbose;
}


- (LSCommandContext *)commandContext;

- (void)logFormat:(NSString *)_format,...;
- (void)logString:(NSString *)_str;

- (BOOL)verbose;

- (BOOL)onlyRoot;

- (NSString *)additionalSwitches;
- (NSString *)toolName;
- (NSString *)toolDescription;
- (NSString *)versionInformation;

- (void)version;
- (void)usage;

- (int)runWithArguments:(NSArray *)_args;

@end /* SkyTool */

#endif /* __SkyTool_H__ */
