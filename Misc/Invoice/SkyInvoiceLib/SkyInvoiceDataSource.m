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

#include "SkyInvoiceDataSource.h"

#import <Foundation/Foundation.h>

#include "SkyInvoiceDocument.h"

#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOSortOrdering.h>

@interface SkyInvoiceDataSource(PrivateMethods)
- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos;
@end /* SkyInvoiceDataSource(PrivateMethods) */
  
@implementation SkyInvoiceDataSource

- (id)init {
  if ((self = [super init])) {
    self->invoices = nil;
    self->fspec    = nil;
  }
  return self;
}

- (id)initWithInvoices:(NSArray *)_invoices {
  if ((self = [super init])) {
    ASSIGN(self->invoices,_invoices);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->invoices);
  RELEASE(self->fspec);
  [super dealloc];
}
#endif

// accessors
- (void)setFetchSpecification:(EOFetchSpecification *)_fspec {
  //  if (![self->fspec isEqual:_fspec]) {
    ASSIGN(self->fspec,_fspec);
    [self postDataSourceChangedNotification];
    //  }
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fspec;
}

- (NSArray *)fetchObjects {
  NSArray *result = self->invoices;
  
  if (result == nil)
    return [NSArray array];

  result = [self _morphEOsToDocuments:result];
  
  if (self->fspec) {
    EOQualifier *qual;
    NSArray     *so;
    
    if ((qual = [self->fspec qualifier]))
      result = [result filteredArrayUsingQualifier:qual];
    if ((so = [self->fspec sortOrderings]))
      result = [result sortedArrayUsingKeyOrderArray:so];
  }
  return result;
}

@end /* SkyInvoiceDataSource */

@implementation SkyInvoiceDataSource(PrivateMethods)

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  int     cnt, i;
  id      *all;
  NSArray *ar;

  cnt = [_eos count];
  all = calloc(cnt, sizeof(id));

  for (i = 0; i < cnt; i++) {
    all[i] = [[SkyInvoiceDocument alloc]
                                  initWithValues:[_eos objectAtIndex:i]
                                  dataSource:self];
    AUTORELEASE(all[i]);
  }
  ar = [NSArray arrayWithObjects:all count:cnt];
  free(all);
  return ar;
}

@end /* SkyInvoiceDataSource(PrivateMethods) */
