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

#ifndef __LSWebInterface_SkyInvoice_SkyInvoicePrintout_H__
#define __LSWebInterface_SkyInvoice_SkyInvoicePrintout_H__

#import <OGoFoundation/LSWViewerPage.h>
#import "SkyInvoicePrintoutFormatter.h"

@interface SkyInvoicePrintout : LSWViewerPage
{
@protected
  id              invoice;
  id              debitor;
  NSArray*        articles;
  BOOL            previewMode;
  NSString        *currency;
  
  //intern
  id               article;
  NSString*       header;
  NSString*       summary;
  NSString*       all;

  BOOL             recomputeOutput;
  SkyInvoicePrintoutFormatter *format;
}

- (void)setInvoice:(id)_invoice;
- (id)invoice;
- (void)setDebitor:(id)_debitor;
- (id)debitor;
- (void)setArticles:(NSArray*)_articles;
- (NSArray*)articles;

- (NSString*)all;
- (NSData*)createOutput;
- (id)createResponse; // output in a response

//Intern --> see private methods

@end

#endif /* __LSWebInterface_SkyInvoice_SkyInvoicePrintout_H__ */
