/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include "OGoQuotaTabExporter.h"
#include "OGoQuotaTabConfigFile.h"
#include "OGoConfigGenTarget.h"
#include "OGoConfigGenTransaction.h"
#include "common.h"

@implementation OGoQuotaTabExporter

static NSString *quotaTabSeparator = @":";
static NSString *quotaTabEOL       = @"\n";

+ (id)sharedQuotaTabExporter {
  static id singleton = nil;
  if (singleton) return singleton;
  singleton = [[self alloc] init];
  return singleton;
}

/* exporting */

- (NSException *)exportQuotaTabEntry:(NSDictionary *)_entry 
  toTarget:(id)_target
  inContext:(id)_ctx 
  transaction:(OGoConfigGenTransaction *)_tx
{
  NSString *mailbox;
  id quota;
  
  mailbox = [_entry objectForKey:@"mailbox"];
  quota   = [_entry objectForKey:@"quota"];
  if (![mailbox isNotNull]) {
    [self logWithFormat:@"ERROR: no mailbox name in quota tab entry: %@", 
            _entry];
    return nil;
  }

  /* write out: "mailbox:18727\n" */
  [_target write:mailbox];
  [_target write:quotaTabSeparator];
  [_target write:[quota isNotNull] ? quota : @"-1"];
  [_target write:quotaTabEOL];
  return nil;
}

- (NSException *)exportConfigEntry:(id)_entry 
  inContext:(id)_ctx 
  transaction:(OGoConfigGenTransaction *)_tx
{
  NSException *e;
  NSString    *s, *tn;
  NSArray     *entries;
  
  tn = [[_entry name] stringByAppendingPathExtension:@"quotatab"];
  self->target = [_tx targetWithName:tn];
  
  e = nil;
  if (e == nil && (s = [_entry rawPrefix])) 
    e = [self->target writeln:s];
  
  if (e == nil && (entries = [_entry generateQuotaTabEntriesInContext:_ctx])) {
    NSEnumerator *en;
    NSDictionary *entry;
    
    en = [entries objectEnumerator];
    while ((entry = [en nextObject]) && (e == nil)) {
      e = [self exportQuotaTabEntry:entry 
                toTarget:self->target
                inContext:_ctx
                transaction:_tx];
    }
  }
  
  if (e == nil && (s = [_entry rawSuffix]))
    e = [self->target writeln:s];
  
  return e;
}

@end /* OGoQuotaTabExporter */
