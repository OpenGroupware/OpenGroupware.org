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

#ifndef __LSWebInterface_SkyInvoice_SkyInvoiceList_H__
#define __LSWebInterface_SkyInvoice_SkyInvoiceList_H__

#include <OGoFoundation/LSWComponent.h>

/*
 * 2002-01-30:
 * new sky invoice list
 *
 *  > attributes      = ( key1, key2, key 3 ...);
 *  > invoices        = the invoices;
 *  > showViewAction  = show the view action     DEF: YES
 *  > showNewAction   = show the new action      DEF: YES
 * <> selected        = the selected invoices
 *  > formName        = the name of the form ..  DEF: InvoiceList
 *
 */

@class SkyCurrencyFormatter;
@class EODataSource;

@interface SkyInvoiceList: LSWComponent
{
@protected
  NSArray           *invoices;
  id                item;
  NSArray           *selected;
  NSArray           *attributes;
  NSString          *formName;
  
  BOOL              showViewAction;
  BOOL              showNewAction;

  SkyCurrencyFormatter *currencyFormatter;
  EODataSource         *invoiceCache;
}

@end /* SkyInvoiceList */

#endif /* __LSWebInterface_SkyInvoice_SkyInvoiceList_H__ */
