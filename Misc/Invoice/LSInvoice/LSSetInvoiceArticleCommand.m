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

#import "common.h"
#import "LSSetInvoiceArticleCommand.h"

@implementation LSSetInvoiceArticleCommand

- (void)_checkArticleNrInContext:(id)_context {
  NSString     *artNr    = nil;
  NSString     *artId    = nil;

  artNr = [[self valueForKey:@"articleNr"] stringValue];
  artId = [[self valueForKey:@"articleId"] stringValue];

  [self assert:
        ((artNr != nil) &&
         ([artNr isNotNull]) &&
         (![artNr isEqualToString:@""]))
        reason:@"No Article No. set!"];

  {
    NSString         *expr      = nil;
    EOAdaptorChannel *adChannel = nil;

    adChannel  = [[_context valueForKey:LSDatabaseChannelKey] adaptorChannel];

    expr = [NSString stringWithFormat:
             @"SELECT COUNT(*) FROM article WHERE article_nr = '%@'"
             @" AND NOT article_id = %@ ", artNr, artId];
  
    if ([adChannel evaluateExpression:expr]) {
      NSDictionary *result;
      id v;

      result = [adChannel fetchAttributes:
                          [adChannel describeResults] withZone:nil];
      [adChannel cancelFetch];

      v = [[result keyEnumerator] nextObject];
      if (v) v = [result objectForKey:v];

      [self assert:([v intValue] == 0) reason:@"Article No. already existent"];
    }
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSNumber     *price;
  NSEnumerator *teamEnum;
  id           account;
  id           team;
  BOOL         access = NO;

  account = [_context valueForKey:LSAccountKey];
  price   = [self valueForKey:@"price"];

  teamEnum =
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", account,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];

  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
      break;
    }
  }
  [self assert:access reason:@"You have no permission for doing that!"];

  [self _checkArticleNrInContext:_context];

  [self assert:((price != nil) && ([price isNotNull]))
        reason:@"No Price set!"];

  [super _prepareForExecutionInContext:_context];
}

- (NSString *)entityName {
  return @"Article";
}

@end
