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

#include "common.h"
#include "SkyArticleAssignmentEditor.h"
#include "SkyCurrencyFormatter.h"

@interface SkyArticleAssignmentEditor(PrivateMethods)
- (id)assignment;

@end

@implementation SkyArticleAssignmentEditor

- (id)init {
  if ((self = [super init])) {
    self->invoice = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->invoice);
  [super dealloc];
}
#endif

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if (![self isInNewMode]) {
    id article = [[self object] valueForKey:@"toArticle"];
    [[self assignment] takeValue:[article valueForKey:@"articleNr"]
                       forKey:@"articleNr"];
    [self setInvoice: [[self object] valueForKey:@"toInvoice"]];
  }
  return YES;
}

//accessors

- (NSMutableDictionary *)assignment {
  return [self snapshot];
}

- (void)setInvoice:(id)_invoice {
  ASSIGN(self->invoice, _invoice);
}
- (id)invoice {
  return self->invoice;
}

- (NSString *)currency {
  return [[[self session] userDefaults] stringForKey:@"invoice_currency"];
}
- (NSFormatter *)currencyFormatter {
  SkyCurrencyFormatter *format = [[SkyCurrencyFormatter alloc] init];
  [format setCurrency:[self currency]];
  
  [format setFormat:@".__0,00"];
  [format setThousandSeparator:@"."];
  [format setDecimalSeparator:@","];
  return AUTORELEASE(format);
}
// notifications

- (NSString *)insertNotificationName {
  return @"LSWUpdatedInvoice";
}
- (NSString *)updateNotificationName {
  return @"LSWUpdatedInvoice";
}
- (NSString *)deleteNotificationName {
  return @"LSWUpdatedInvoice";
}

//actions

- (BOOL)_checkAssignment {
  id a       = [self assignment];
  id article =
    [[self runCommand:@"article::get",
           @"articleNr",
           [a valueForKey:@"articleNr"],
           @"returnType", intObj(LSDBReturnType_ManyObjects),
           nil] lastObject];
  NSString *articleCount = [[a valueForKey:@"articleCount"] stringValue];
  NSString *netAmount    = [[a valueForKey:@"netAmount"] stringValue];
  NSString *comment      = [a valueForKey:@"comment"];
  
  NSNumber *artCount =
    ((articleCount != nil) &&
     (![articleCount isEqualToString:@""])) ?
    [NSNumber numberWithDouble:[articleCount doubleValue]] :
    [NSNumber numberWithDouble: 1.0];
  
  NSNumber *artNet =
    ((netAmount != nil) &&
     (![netAmount isEqualToString:@""])) ?
    [NSNumber numberWithDouble:[netAmount doubleValue]] :
    [article valueForKey:@"price"];

  if ((comment == nil) || (![comment isNotNull])) {
    [a takeValue: @""
       forKey:@"comment"];
  }
                       
  
  [a takeValue:artCount   forKey:@"articleCount"];
  [a takeValue:artNet     forKey:@"netAmount"];
  [a takeValue:[article valueForKey:@"articleId"] forKey:@"articleId"];
    
  return ((article == nil) || (![article isNotNull])) ? NO : YES;
}

- (id)insertObject {
  if ([self _checkAssignment]) {
    [[self assignment] takeValue:[self->invoice valueForKey:@"invoiceId"]
                       forKey:@"invoiceId"];
    
    if (([self runCommand:@"invoicearticleassignment::new"
               arguments:[self assignment]]) != nil) {
      return [self runCommand:@"invoice::set",
                   @"object", self->invoice,
                   nil]; 
    }
    
    return nil;
  }
  [self setErrorString:@"Unknown article"];
  return nil;
}

- (id)updateObject {
  if ([self _checkAssignment]) {
    if(([self runCommand:@"invoicearticleassignment::set" arguments:
              [self assignment]]) != nil) {
      return [self->invoice run:@"invoice::set",
                  @"saveArticles", [NSNumber numberWithBool:NO],
                  nil]; 
    }

    return nil;
  }
  [self setErrorString:@"Unknown article"];
  return nil;
}

@end
