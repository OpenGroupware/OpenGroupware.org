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

#include "SkyInvoicePrintoutFormatter.h"
#include "common.h"

#include <Foundation/NSNumberFormatter.h>
#include <Foundation/NSDateFormatter.h>

@class NSDateFormatter, NSNumberFormatter;

@interface SkyInvoicePrintoutFormatter(PrivateMethods) 
- (id)invoice;
- (NSArray *)invoices;
- (NSArray *)articles;
- (id)debitor;
- (NSString *)currency;
- (NSString*)_stringWithSettings:(NSDictionary*)_settings
                       andObject:(id)_obj;
- (void)setDefaultSettings:(NSDictionary*)_settings;
- (void)setFormatSettings:(NSDictionary*)_settings;
@end

#include "SkyCurrencyFormatter.h"

@implementation SkyInvoicePrintoutFormatter

- (id)init {
  if ((self = [super init])) {
    self->formattedString = nil;
    
    self->currency = @"DEM";
    RETAIN(self->currency);
  }
  return self;
}

+ (SkyInvoicePrintoutFormatter *)
skyInvoicePrintoutFormatterWithDefaultSettings:
  (NSDictionary *)_settings
{
  SkyInvoicePrintoutFormatter *format =
    [[SkyInvoicePrintoutFormatter alloc] init];
  [format setDefaultSettings:_settings];
  return AUTORELEASE(format);
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->invoice);
  RELEASE(self->invoices);
  RELEASE(self->articles);
  RELEASE(self->debitor);
  RELEASE(self->defaultSettings);
  RELEASE(self->formatSettings);
  RELEASE(self->formattedString);
  RELEASE(self->currency);
  [super dealloc];
}
#endif

- (NSString *)labelForCurrency {
  if ([self->currency isEqualToString:@"DEM"])
    return @"DM";
  return self->currency;
}

//printing functions

- (NSString*)_stringWithFormat:(NSString*)_format
                     andObject:(id)_obj
{
  NSArray      *sep     = [_format componentsSeparatedByString:@"{%"];
  NSEnumerator *sepEnum = [sep objectEnumerator];
  NSString     *str;
  NSString     *output  = @"";

  while ((str = [sepEnum nextObject])) {
    NSMutableArray* strs =
      [NSMutableArray arrayWithArray:
                      [str componentsSeparatedByString:@"}"]];
    if ([strs count] > 1) {
      NSString *toReplace      = [strs objectAtIndex:0];
      NSArray  *replaceStrings = [toReplace componentsSeparatedByString:@"%"];
      NSString *format         = [replaceStrings objectAtIndex:0];
      NSString *key            = [replaceStrings objectAtIndex:1];
      NSString *readyString;
      id       value;

      [strs removeObjectAtIndex:0]; // toReplaceString

      if (![key isEqualToString:@""]) {
        value =
          [self _stringWithSettings:[self->formatSettings objectForKey:key]
                andObject: _obj];
      } else {
        value = _obj != nil ? [_obj stringValue] : @"";
      }
      format      = [NSString stringWithFormat: @"%%%@", format];
      readyString = [NSString stringWithFormat: format, value];
      str         = [NSString stringWithFormat:@"%@%@",
                              readyString,
                              [strs componentsJoinedByString:@"}"]];
    } else {
      str = str;
    }
    output = [output stringByAppendingString: str];
  }
  return output;
}

- (NSString*)_stringWithSettings:(NSDictionary*)_settings
                       andObject:(id)_obj
{
  NSString *object            = nil;
  NSString *key               = nil;
  NSString *type              = nil;
  NSString *subItem           = nil;
  NSString *value             = nil;
  NSString *nullString        = nil;
  NSString *dateFormat        = nil;
  NSString *numberFormat      = nil;
  NSString *numberFormat_tSep = nil;
  NSString *numberFormat_dSep = nil;
  NSString *split             = nil;
  BOOL     isCurrency         = NO;

  NSString *readyString = @"";
  id       subObj       = nil;

  object            = [_settings objectForKey:@"object"];
  key               = [_settings objectForKey:@"key"];
  type              = [_settings objectForKey:@"type"];
  subItem           = [_settings objectForKey:@"subItem"];
  value             = [_settings objectForKey:@"value"];
  nullString        = [_settings objectForKey:@"nullString"];
  dateFormat        = [_settings objectForKey:@"dateFormat"];
  numberFormat      = [_settings objectForKey:@"numberFormat"];
  numberFormat_tSep = [_settings objectForKey:@"numberFormat_tSep"];
  numberFormat_dSep = [_settings objectForKey:@"numberFormat_dSep"];
  split             = [_settings objectForKey:@"split"];
  isCurrency        = [[_settings objectForKey:@"isCurrency"] boolValue];


  if (value != nil)
    return value;

  if ((_obj != nil) && ([_obj isNotNull])
      && ([_obj isKindOfClass: [NSArray class]])
      && (!([type isEqualToString:@"list"] && (key == nil))
          ))
      _obj = [_obj lastObject];

  if (object != nil) {
    if ([object isEqualToString:@"invoice"])
      _obj = [self invoice];
    else if ([object isEqualToString:@"invoices"])
      _obj = [self invoices];
    else if ([object isEqualToString:@"articles"])
      _obj = [self articles];
    else if ([object isEqualToString:@"debitor"])
      _obj = [self debitor];
    else if ([object isEqualToString:@"now"])
      _obj = [NSCalendarDate date];
    else if ([object isEqualToString:@"currency"])
      return [self labelForCurrency];
  }

  if ((key != nil) && (_obj != nil))
    subObj = [_obj valueForKey:key];
  else
    subObj = _obj;

  if ((split != nil) && ([type isEqualToString:@"list"]))
    subObj = [[subObj stringValue] componentsSeparatedByString:split];
  else if (dateFormat != nil) {
    NSDateFormatter *dform =
      [[NSDateFormatter alloc] initWithDateFormat:dateFormat
                                allowNaturalLanguage:NO];
    subObj = [dform stringForObjectValue: subObj];
    RELEASE(dform); dform = nil;
  } else if (numberFormat != nil) {
    NSFormatter *nform = nil;
    if (isCurrency) {
      nform = [[SkyCurrencyFormatter alloc] init];
      [(SkyCurrencyFormatter *)nform setCurrency:self->currency];
    }
    else {
      nform = [[NSNumberFormatter alloc] init];
    }
    [(NSNumberFormatter *)nform setFormat: numberFormat];
    if (numberFormat_tSep != nil)
      [(NSNumberFormatter *)nform setThousandSeparator:numberFormat_tSep];
    if (numberFormat_dSep != nil)
      [(NSNumberFormatter *)nform setDecimalSeparator:numberFormat_dSep];
    subObj = [nform stringForObjectValue: subObj];
    RELEASE(nform); nform = nil;
  }

  if (nullString != nil) {
    if ((subObj == nil)
        || (![subObj isNotNull])
        || (([subObj isKindOfClass: [NSArray class]])
            && ([subObj count] == 0))
        || (([subObj isKindOfClass: [NSString class]])
            && (([subObj isEqualToString:@""])
                || ([subObj isEqualToString:@" "])))
        )
        return nullString;
  }

  if ([type isEqualToString:@"key"]) {
    if (subItem != nil)
      readyString =  [self _stringWithFormat:
                           [self->formatSettings objectForKey:subItem]
                           andObject:subObj];
    else
      readyString = [subObj stringValue];
  } else if ([type isEqualToString:@"list"]) {
    NSEnumerator *objEnum = [subObj objectEnumerator];
    id obj;
    obj = nil;

    if (subItem != nil) {
      while ((obj = [objEnum nextObject])) {
        readyString =
          [readyString stringByAppendingString:
                       [self _stringWithFormat:
                             [self->formatSettings objectForKey:subItem]
                             andObject: obj]];
      }
    } else {
      while ((obj = [objEnum nextObject]))
        readyString = [readyString stringByAppendingString:
                                   [obj stringValue]];
    }
  }
  if (nullString != nil) {
    if ([readyString length] == 0) {
        return nullString;
    }
  }
  return readyString;
}

- (void)setFormattedString:(NSString*)_formatted {
  ASSIGN(self->formattedString, _formatted);
}

- (NSString*)formattedString {
  NSString* formatted = self->formattedString;
  if (formatted == nil) {
    formatted =
      [self _stringWithFormat:[self->formatSettings objectForKey:@"MAIN"]
            andObject: nil];
    [self setFormattedString: formatted];
  }
  return formatted;
}

//accessors

- (void)setInvoice:(id)_invoice {
  ASSIGN(self->invoice, _invoice);
}
- (id)invoice {
  return self->invoice;
}

- (void)setInvoices:(NSArray *)_invoices {
  ASSIGN(self->invoices, _invoices);
}
- (NSArray *)invoices {
  return self->invoices;
}

- (void)setArticles:(NSArray *)_articles {
  ASSIGN(self->articles, _articles);
}
- (NSArray*)articles {
  return self->articles;
}

- (void)setDebitor:(id)_debitor {
  ASSIGN(self->debitor, _debitor);
}
- (id)debitor {
  return self->debitor;
}

- (void)setDefaultSettings:(NSDictionary *)_settings {
  ASSIGN(self->defaultSettings, _settings);
  [self setFormatSettings:_settings];
}
- (NSDictionary*)defaultSettings {
  return self->defaultSettings;
}

- (void)setFormatSettings:(NSDictionary*)_settings {
  NSMutableDictionary *settings =
    [NSMutableDictionary dictionaryWithDictionary:self->formatSettings];
  [settings addEntriesFromDictionary:_settings];
  ASSIGN(self->formatSettings, settings);
}
- (id)formatSettings {
  return self->formatSettings;
}

- (NSData*)createOutput {
  return [[self formattedString]
                dataUsingEncoding:[NSString defaultCStringEncoding]];
}

- (NSString*)stringForKey:(NSString*)_key andObject:(id)_obj {
  return
    [self _stringWithFormat:[self->formatSettings objectForKey:_key]
          andObject:_obj];
}

- (void)setCurrency:(NSString *)_cur {
  ASSIGN(self->currency,_cur);
}
- (NSString *)currency {
  return self->currency;
}


@end
