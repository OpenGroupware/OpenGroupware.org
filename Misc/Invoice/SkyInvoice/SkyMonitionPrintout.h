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

#ifndef __LSWebInterface_SkyInvoice_SkyMonitionPrintout_H__
#define __LSWebInterface_SkyInvoice_SkyMonitionPrintout_H__

#import <OGoFoundation/LSWViewerPage.h>
#import "SkyInvoicePrintoutFormatter.h"

@interface SkyMonitionPrintout : LSWViewerPage
{
@protected
  id        debitor;
  NSArray   *invoices;
  NSString  *currency;

  //intern
  id        invoice;
  NSString *header;
  NSString *summary;
  NSString *all;

  BOOL      recomputeOutput;
  SkyInvoicePrintoutFormatter *format;
}

- (void)setInvoices:(id)_invoices;
- (void)setDebitor:(id)_debitor;

- (NSString*)all;
- (NSData*)createOutput;
- (id)createResponse;

@end

#endif /* __LSWebInterface_SkyInvoice_SkyMonitionPrintout_H__ */
