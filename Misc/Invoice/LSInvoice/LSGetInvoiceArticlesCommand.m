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
#import "LSGetInvoiceArticlesCommand.h"
#include <math.h>

@implementation LSGetInvoiceArticlesCommand

- (void)_executeInContext:(id)_context {
  NSArray      *assigns;
  NSEnumerator *assignEnum;
  id assignment;

  LSRunCommandV(_context, @"invoice", @"get",
                @"invoiceId",
                [[self object] valueForKey:@"invoiceId"],
                nil);

  assigns    = [[self object] valueForKey:@"toInvoiceArticleAssignment"];
  assignEnum = [assigns objectEnumerator];

  if ((assigns == nil) || (![assigns isNotNull])) {
    [self setReturnValue:nil];
  } else {
    while ((assignment = [assignEnum nextObject])) {
      id article;
      
      article = [assignment valueForKey:@"toArticle"];

      if (article != nil) {
        double cnt;
        double allNetAmount;

        cnt =  [[assignment valueForKey:@"articleCount"] doubleValue];

        [assignment takeValue:[article valueForKey:@"articleName"]
                    forKey:@"articleName"];
        [assignment takeValue:[article valueForKey:@"articleNr"]
                    forKey:@"articleNr"];

        if (cnt == 1.0) {
          [assignment takeValue:
                      [NSString stringWithFormat:
                                [[article valueForKey:@"toArticleUnit"]
                                          valueForKey:@"singularUnit"],
                                cnt]
                      forKey:@"countString"];
        } else {
          [assignment takeValue:
                      [NSString stringWithFormat:
                                [[article valueForKey:@"toArticleUnit"]
                                          valueForKey:@"pluralUnit"],
                                cnt]
                      forKey:@"countString"];
        }
        allNetAmount = [[assignment valueForKey:@"netAmount"] doubleValue]
          * cnt;
        allNetAmount = rint(allNetAmount * 100.0) * 0.01;

        [assignment takeValue:[NSNumber numberWithDouble:allNetAmount]
                    forKey:@"allNetAmount"];
        [assignment takeValue:[article valueForKey:@"comment"]
                    forKey:@"defaultComment"];
        [assignment takeValue:[article valueForKey:@"toArticleCategory"]
                    forKey:@"articleCategory"];
      }
    }
    [self setReturnValue:assigns];
  }
}

- (NSString *)entityName {
  return @"Invoice";
}

@end
