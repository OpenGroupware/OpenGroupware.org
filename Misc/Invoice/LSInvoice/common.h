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


#ifndef __LSLogic_LSInvoice_common_H__
#define __LSLogic_LSInvoice_common_H__

// common include file

#define INVOICES_TEAM @"invoices"
#define INVOICE_PROJECT_KIND @"00_invoiceProject"
#define INVOICE_PROJECT_NAME @"Invoices - "
#define ROOT_ID 10000


#import <Foundation/Foundation.h>
#import <NGExtensions/NGExtensions.h>
#import <NGStreams/NGStreams.h>

#import <EOAccess/EOAccess.h>
#import <GDLExtensions/GDLExtensions.h>

#include <LSFoundation/LSFoundation.h>


#define MONEY2SAVEFORNUMBER(val) \
  [NSString stringWithFormat:@"%.4lf", [(val) doubleValue]]

#define MONEY2SAVEFORDOUBLE(val) \
  [NSString stringWithFormat:@"%.4lf", (val)]

#define PREPAREINVOICEMONEY(invoice) { \
  [(invoice) \
      takeValue:MONEY2SAVEFORNUMBER([(invoice) valueForKey:@"netAmount"]) \
      forKey:@"netAmount"]; \
  [(invoice) \
      takeValue:MONEY2SAVEFORNUMBER([(invoice) valueForKey:@"grossAmount"]) \
      forKey:@"grossAmount"]; \
  [(invoice) \
      takeValue:MONEY2SAVEFORNUMBER([(invoice) valueForKey:@"paid"]) \
      forKey:@"paid"]; \
  }

#endif /* __LSLogic_LSInvoice_common_H__ */
