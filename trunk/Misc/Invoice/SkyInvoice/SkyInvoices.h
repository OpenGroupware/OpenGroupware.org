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

#ifndef __LSWebInterface_SkyInvoice_SkyInvoices_H__
#define __LSWebInterface_SkyInvoice_SkyInvoices_H__

#include <OGoFoundation/LSWContentPage.h>
#include <Foundation/NSFormatter.h>

@interface SkyInvoices : LSWContentPage
{
  @private
  //List
  NSArray       *listInvoices; //invoices for invoices-tab
  NSArray       *invoices;     //filtered invoices
  NSArray       *badDebitors;  //debitors with unsettled invoices
  NSArray       *selected;
  NSArray       *articles;     //filtered articles
  NSArray       *accounts;     //invoice accounts
  NSString      *articleSearchString;
  NSString      *invoiceSearchString;
  NSArray       *articleCategories;
  NSArray       *units;
  NSString      *selectedYear;
  NSArray       *months;           // months-popup
  id            selectedMonth;
  NSArray       *invoiceKinds;     // invoice kind - popup
  NSString      *selectedKind;
  BOOL          fetchListInvoices;
  BOOL          fetchArticleCategories;
  BOOL          fetchUnits;
  BOOL          fetchBadDebitors;
  BOOL          fetchAccounts;
  BOOL          searchingInvoices;
  id            item;
  id            button;
  unsigned      startIndex;
  BOOL          isDescending;
  NSDictionary  *selectedAttribute;
  //Tab
  NSString      *tabKey;
  //overviewform
  NSString      *overviewFrom;
  NSString      *overviewTo;
  NSString      *overviewOutput;

  // formatting
  NSFormatter   *currencyFormatter;
}

@end

#endif /* __LSWebInterface_SkyInvoice_SkyInvoices_H__ */
