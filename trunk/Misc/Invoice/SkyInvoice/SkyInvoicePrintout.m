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

#include "SkyInvoicePrintout.h"
#include "common.h"

@interface SkyInvoicePrintout(PrivateMethods) 
- (void)setArticle:(id)_article;
- (NSArray*)articles;
- (id)invoice;
- (id)debitor;
- (void)setHeader:(NSString*)_header;
- (void)setSummary:(NSString*)_summary;
- (void)setArticlesString:(NSString*)_artStr;
- (void)setAll:(NSString*)_all;
- (void)setFormat:(SkyInvoicePrintoutFormatter*)_format;
- (NSString *)currency;
@end

@interface LSWSession(SkyInvoicePrintout)
- (NSNotificationCenter *)notificationCenter;
@end

@implementation SkyInvoicePrintout

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter *nc = nil;

    nc = [(id)[self session] notificationCenter];
    [nc addObserver:self selector:@selector(noteChange:)
        name:@"LSWNewInvoice" object:nil];
    [nc addObserver:self selector:@selector(noteChange:)
        name:@"LSWUpdatedInvoice" object:nil];
    [nc addObserver:self selector:@selector(noteChange:)
        name:@"LSWDeletedInvoice" object:nil];
    self->articles = nil;
    self->invoice  = nil;
    self->all      = nil;
    self->debitor  = nil;
    self->recomputeOutput = YES;
    self->currency = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [self unregisterAsObserver];
  RELEASE(self->invoice);
  RELEASE(self->debitor);
  RELEASE(self->article);
  RELEASE(self->articles);
  RELEASE(self->all);
  RELEASE(self->header);
  RELEASE(self->summary);
  RELEASE(self->format);
  [super dealloc];
}
#endif

- (void)_computeOutput {
  NSUserDefaults *ud             = [[self session] userDefaults];
  NSDictionary   *formatSettings =
    [ud dictionaryForKey:@"invoice_format_settings"];
  NSDictionary   *settings       =
    [formatSettings objectForKey:@"standard-printout"];
  SkyInvoicePrintoutFormatter *formatter =
    [SkyInvoicePrintoutFormatter skyInvoicePrintoutFormatterWithDefaultSettings:settings];
  NSDictionary *invoiceKinds = [ud dictionaryForKey:@"invoice_kinds"];
  NSDictionary *invoiceKind  =
    [invoiceKinds objectForKey:[[self invoice] valueForKey:@"kind"]];
  NSString     *printoutAttr = [invoiceKind objectForKey:@"printout"];
  
  if (printoutAttr != nil) {
    [formatter setFormatSettings:
               [formatSettings objectForKey:printoutAttr]];
  }

  [formatter setInvoice:  [self invoice]];
  [formatter setDebitor:  [self debitor]];
  [formatter setArticles: [self articles]];
  [formatter setCurrency: [self currency]];
  [self setHeader:[formatter stringForKey:@"HEADER_ITEM"
                             andObject:nil]];
  [self setSummary:[formatter stringForKey:@"FOOTER_ITEM"
                              andObject:nil]];
  [self setAll:[formatter formattedString]];
  [self setFormat:formatter];
}

- (void)noteChange:(id)_cn {
  self->recomputeOutput = YES;
}

- (void)syncAwake {
  [super syncAwake];
  if (self->recomputeOutput) {
    [self _computeOutput];
    self->recomputeOutput = NO;
  }
}

//accessors
//API

- (void)setInvoice:(id)_invoice {
  ASSIGN(self->invoice,_invoice);
}
- (id)invoice {
  return self->invoice;
}

- (void)setDebitor:(id)_debitor {
  ASSIGN(self->debitor,_debitor);
}
- (id)debitor {
  return self->debitor;
}

- (void)setArticles:(NSArray*)_articles {
  ASSIGN(self->articles, _articles);
}
- (NSArray*)articles {
  return self->articles;
}

- (void)setPreviewMode:(BOOL)_flag {
  self->previewMode = _flag;
}
- (BOOL)previewMode {
  return self->previewMode;
}

- (void)setCurrency:(NSString *)_cur {
  if (![_cur isEqualToString:self->currency]) {
    ASSIGN(self->currency,_cur);
    self->recomputeOutput = YES;
  }
}
- (NSString *)currency {
  return self->currency;
}

//intern

- (void)setArticle:(NSDictionary*)_article {
  ASSIGN(self->article, _article);
}
- (NSDictionary*)article {
  return self->article;
}

- (void)setHeader:(NSString*)_header {
  ASSIGN(self->header, _header);
}
- (NSString*)header {
  return self->header;
}

- (void)setSummary:(NSString*)_summary {
  ASSIGN(self->summary, _summary);
}
- (NSString*)summary {
  return self->summary;
}


- (NSString*)articleString {
  return [self->format stringForKey:@"ARTICLE" andObject:self->article];
}

- (void)setAll:(NSString*)_all {
  ASSIGN(self->all, _all);
}
- (NSString*)all {
  return self->all;
}

- (void)setFormat:(SkyInvoicePrintoutFormatter*)_format {
  ASSIGN(self->format, _format);
}

- (SkyInvoicePrintoutFormatter*)format {
  return self->format;
}

- (NSData*)createOutput {
  return [self->all dataUsingEncoding:[NSString defaultCStringEncoding]];
}

- (id)createResponse {
  WOResponse* response = nil;

  response = [WOResponse responseWithRequest:[[self context] request]];
  [response setStatus:200];
  [response setHeader:@"text/plain"
            forKey:@"content-type"];
  [response setContent:[self createOutput]];

  return response;
}

- (id)viewAssignment {
  [[self session] transferObject:self->article
                  owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

@end
