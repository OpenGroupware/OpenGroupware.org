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

#include "OGoComponent+FileManagerError.h"
#include "common.h"

@implementation OGoComponent(FileManagerError)

- (void)setErrorString:(NSString *)_string {
  // do nothing
}

- (id)fileManager {
  return nil;
}

- (NSString *)_errorDescription {
  int      errorCode = 0;
  NSString *errorKey = nil;

  if ([[self fileManager] supportsExternalErrorDescription]) {
    NSString *error;
    
    errorKey = [[self fileManager] lastErrorDescription];
    
    if ([(error = [[self labels] valueForKey:errorKey]) length])
      return error;
    return errorKey;
  }
  errorCode = [(SkyProjectFileManager *)[self fileManager] lastErrorCode];
  if (errorCode > 0) {
    errorKey  = [NSString stringWithFormat:@"fm_error_%d", errorCode];
    return [[self labels] valueForKey:errorKey];
  }
  else {
    NSException *exc;
    
    if ((exc = [[self fileManager] lastException]))
      return [[self labels] valueForKey:[exc reason]];
  }
  return nil;
}

- (id)printError {
  [self setErrorString:[self _errorDescription]];
  return nil;
}

- (id)printErrorWithSource:(NSString *)_src destination:(NSString *)_dest {
  NSString *str = [self _errorDescription];

  if (_src || _dest)
    str = [str stringByAppendingString:@" ("];
  if (_src) {
    str = [str stringByAppendingFormat:@"'%@'", _src];
    if (_dest)
      str = [str stringByAppendingString:@", "];
  }
  if (_dest)
    str = [str stringByAppendingFormat:@"'%@'", _dest];
  if (_src || _dest)
    str = [str stringByAppendingString:@")"];

  [self setErrorString:str];
  
  return nil;
}

@end /* OGoComponent(FileManagerError) */
