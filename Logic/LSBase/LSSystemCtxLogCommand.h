/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#ifndef __LSLogic_LSFoundation_LSSystemCtxLogCommand_H__
#define __LSLogic_LSFoundation_LSSystemCtxLogCommand_H__

#include <LSFoundation/LSBaseCommand.h>
#import  <NGStreams/NGTextStreamProtocols.h>

/*
  Mit diesem Kommando kann man Keys aus dem Context auf einen stream
  loggen.
*/

@class NSArray;

@interface LSSystemCtxLogCommand : LSBaseCommand
{
  id<NSObject,NGExtendedTextOutputStream> out;
  NSArray *keysToLog;
}

// command methods

- (void)_executeInContext:(id)_context;

// accessors

- (void)setLogStream:(id<NSObject,NGExtendedTextOutputStream>)_stream;
- (id<NSObject,NGExtendedTextOutputStream>)logStream;

- (void)setKeysToLog:(NSArray *)_keys;
- (NSArray *)keysToLog;

@end

#endif /* __LSLogic_LSFoundation_LSSystemCtxLogCommand_H__ */
