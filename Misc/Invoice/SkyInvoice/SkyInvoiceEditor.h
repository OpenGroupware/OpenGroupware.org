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

#ifndef __LSWebInterface_SkyInvoice_SkyInvoiceEditor_H__
#define __LSWebInterface_SkyInvoice_SkyInvoiceEditor_H__

#include <OGoFoundation/LSWEditorPage.h>

@class NSNumber, NSFormatter, NSArray, NSMutableArray, NSDictionary;
@class NSString;

@interface SkyInvoiceEditor : LSWEditorPage
{
@private
  id             item;
  NSDictionary   *attribute;
  NSString       *searchString;
  NSString       *articlesText;
  NSMutableArray *articles;
  NSArray        *resultList;
  NSDictionary   *mappedArticles;
  id             debitor;
  BOOL           fetchDebitor;
  BOOL           hasAddErrors;
  NSString       *errors;
  NSString       *invoiceDate;
  id             reference; //for proforma invoices

  NSFormatter    *currencyFormatter;
}

- (void)setDebitor:(id)_debitor;
- (void)setReference:(id)_ref;
- (void)setArticles:(NSMutableArray *)_articles;
- (void)_putArticlesToTextField;

@end

#endif /* __LSWebInterface_SkyInvoice_SkyInvoiceEditor_H__ */
