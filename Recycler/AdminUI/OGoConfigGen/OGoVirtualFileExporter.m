/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "OGoVirtualFileExporter.h"
#include "OGoConfigGenTarget.h"
#include "OGoConfigGenTransaction.h"
#include "common.h"

@implementation OGoVirtualFileExporter

static NSString *ventrySeparator      = @", ";
static NSString *leftRightSeparator   = @"\n    "; // continuation line
static NSString *ventryLineTerminator = @"\n";
static NSString *ventryEntrySeparator = @"\n";

+ (id)sharedVirtualFileExporter {
  static id singleton = nil;
  if (singleton) return singleton;
  singleton = [[self alloc] init];
  return singleton;
}

/* writing out virtual entries */

- (NSException *)virtualConfigFile:(id)_config
  forwardMailToAddress:(NSString *)_leftSide
  toAddresses:(NSArray *)_recipients
{
  [self logWithFormat:@"map '%@' to: %@",
	  _leftSide, [_recipients componentsJoinedByString:@","]];

  if ([_leftSide length] == 0) {
    [self logWithFormat:@"ERROR: invalid left side ..."];
    return nil; // TODO: gen exception
  }

  if ([_recipients count] == 0) {
    [self->target write:@"# empty target: "];
    [self->target writeln:_leftSide];
  }
  else {
    unsigned i, count;
    
    [self->target write:_leftSide];
    [self->target write:leftRightSeparator];
    for (i = 0, count = [_recipients count]; i < count; i++) {
      if (i != 0) [self->target write:ventrySeparator];
      [self->target write:[_recipients objectAtIndex:i]];
    }
    [self->target write:ventryLineTerminator];
    [self->target write:ventryEntrySeparator];
  }
  
  return nil;
}

/* exporting */

- (NSException *)exportConfigEntry:(id)_entry 
  inContext:(id)_ctx 
  transaction:(OGoConfigGenTransaction *)_tx
{
  NSException *e;
  NSString    *s, *tn;
  
  tn = [[_entry name] stringByAppendingPathExtension:@"virtual"];
  self->target = [_tx targetWithName:tn];
  
  e = nil;
  if (e == nil && (s = [_entry rawPrefix])) 
    e = [self->target writeln:s];
  
  if (e == nil)
    e = [_entry produceVirtualEntriesOnConsumer:self inContext:_ctx];

  if (e == nil && (s = [_entry rawSuffix]))
    e = [self->target writeln:s];
  
  return e;
}

@end /* OGoVirtualFileExporter */
