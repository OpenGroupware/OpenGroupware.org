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

#ifndef __Invoice_SkyInvoiceLib_SkyInvoiceDocument_H__
#define __Invoice_SkyInvoiceLib_SkyInvoiceDocument_H__

#include <OGoDocuments/SkyDocument.h>

@class NSCalendarDate, NSNumber;
@class SkyInvoiceDataSource;
@class EOGlobalID, EODataSource;

@interface SkyInvoiceDocument : SkyDocument
{
  NSString       *invoiceNr;
  NSCalendarDate *invoiceDate;
  NSString       *state;
  NSString       *kind;

  // amounts
  NSNumber       *netAmount;
  NSNumber       *grossAmount;
  NSNumber       *paid;
  NSNumber       *monitionLevel;
  NSNumber       *toPay;

  // debitor
  NSNumber       *debitorId;
  NSString       *debitorDescription;

  EOGlobalID     *globalID;

  EODataSource   *dataSource;
}

- (id)initWithValues:(id)_values dataSource:(SkyInvoiceDataSource *)_ds;

// accessors
- (NSString *)invoiceNr;
- (NSCalendarDate *)invoiceDate;
- (NSString *)state;
- (NSString *)kind;

- (NSNumber *)netAmount;
- (NSNumber *)grossAmount;
- (NSNumber *)paid;
- (NSNumber *)toPay;
- (NSNumber *)monitionLevel;

- (NSNumber *)debitorId;
- (NSString *)debitorDescription;

- (BOOL)isPrintable;
- (BOOL)isMoveable;
- (BOOL)isFinishable;

@end /* SkyInvoiceDocument */

#endif /* __Invoice_SkyInvoiceLib_SkyInvoiceDocument_H__ */
