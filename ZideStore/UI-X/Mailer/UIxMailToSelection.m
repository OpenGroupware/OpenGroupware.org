/*
 Copyright (C) 2004-2005 SKYRIX Software AG
 
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

#include <SOGoUI/UIxComponent.h>

/*
  UIxMailToSelection
  
  Select a set of address headers for composing an email.
  
  Bindings:
  to   - array of strings suitable for placement in a To: header
  cc   - array of strings suitable for placement in a Cc: header
  bcc  - array of strings suitable for placement in a Bcc: header
  
  Sample:
  <var:component className="UIxMailToSelection"
  to="to"
  cc="cc"
  bcc="bcc"
  />
*/

@class NSArray;

@interface UIxMailToSelection : UIxComponent
{
  NSArray *to;
  NSArray *cc;
  NSArray *bcc;
  id      item;
  id      address;
  NSArray *addressList;
  int     currentIndex;
}

- (void)setTo:(NSArray *)_to;
- (NSArray *)to;
- (void)setCc:(NSArray *)_cc;
- (NSArray *)cc;
- (void)setBcc:(NSArray *)_bcc;
- (NSArray *)bcc;

- (NSArray *)properlySplitAddresses:(NSArray *)_addresses;

- (void)getAddressesFromFormValues:(NSDictionary *)_dict;
- (NSString *)getIndexFromIdentifier:(NSString *)_identifier;

@end

#include "common.h"
#include <NGMail/NGMail.h>

@implementation UIxMailToSelection

static NSArray *headers = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit)
    return;
  
  didInit = YES;
  headers = [[NSArray alloc] initWithObjects:@"to", @"cc", @"bcc", nil];
}

- (id)init {
  self = [super init];
  if(self) {
    self->currentIndex = 0;
  }
  return self;
}

- (void)dealloc {
  [self->to          release];
  [self->cc          release];
  [self->bcc         release];
  [self->item        release];
  [self->address     release];
  [self->addressList release];
  [super dealloc];
}

/* accessors */

- (void)setTo:(NSArray *)_to {
  _to = [self properlySplitAddresses:_to];
  ASSIGNCOPY(self->to, _to);
}
- (NSArray *)to {
  return self->to;
}

- (void)setCc:(NSArray *)_cc {
  _cc = [self properlySplitAddresses:_cc];
  ASSIGNCOPY(self->cc, _cc);
}
- (NSArray *)cc {
  return self->cc;
}

- (void)setBcc:(NSArray *)_bcc {
  _bcc = [self properlySplitAddresses:_bcc];
  ASSIGNCOPY(self->bcc, _bcc);
}
- (NSArray *)bcc {
  return self->bcc;
}

- (void)setAddressList:(NSArray *)_addressList {
  ASSIGN(self->addressList, _addressList);
}
- (NSArray *)addressList {
  return self->addressList;
}

- (void)setAddress:(id)_address {
  ASSIGN(self->address, _address);
}
- (id)address {
  return self->address;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSArray *)addressLists {
  NSMutableArray *ma;
  
  ma = [NSMutableArray arrayWithCapacity:3];
  if ([self->to  isNotNull]) [ma addObject:self->to];
  if ([self->cc  isNotNull]) [ma addObject:self->cc];
  if ([self->bcc isNotNull]) [ma addObject:self->bcc];
  
  /* ensure that at least one object is available */
  if ([ma count] == 0) {
    NSArray *tmp = [NSArray arrayWithObject:@""];
    ASSIGNCOPY(self->to, tmp);
    [ma addObject:self->to];
  }
  return ma;
}

- (NSArray *)headers {
  return headers;
}

- (NSString *)currentHeader {
  if(self->addressList == self->to)
    return @"to";
  else if(self->addressList == self->cc)
    return @"cc";
  return @"bcc";
}

/* identifiers */

- (NSString *)currentRowId {
  unsigned char buf[16];
  sprintf(buf, "row_%d", self->currentIndex);
  return [NSString stringWithCString:buf];
}

- (NSString *)currentPopUpId {
  unsigned char buf[16];
  sprintf(buf, "popup_%d", self->currentIndex);
  return [NSString stringWithCString:buf];
}

- (NSString *)currentAddressId {
  unsigned char buf[16];
  sprintf(buf, "addr_%d", self->currentIndex);
  return [NSString stringWithCString:buf];
}

- (NSString *)nextId {
  self->currentIndex++;
  return @"";
}

/* address handling */

- (NSArray *)properlySplitAddresses:(NSArray *)_addresses {
  NSString            *addrs;
  NGMailAddressParser *parser;
  NSArray             *result;
  NSMutableArray      *ma;
  unsigned            i, count;

  if(!_addresses || [_addresses count] == 0)
    return nil;

  /* create one huge string, then split it using the parser */
  addrs = [_addresses componentsJoinedByString:@","];
  parser = [NGMailAddressParser mailAddressParserWithString:addrs];
  result = [parser parseAddressList];
  if(result == nil) {
    [self debugWithFormat:@"Couldn't parse given addresses:%@", _addresses];
    return _addresses;
  }

  count = [result count];
  ma = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NGMailAddress   *addr;
    NSMutableString *s;
    BOOL hasName = NO;

    s = [[NSMutableString alloc] init];
    addr = [result objectAtIndex:i];
    if([addr displayName]) {
      [s appendString:[addr displayName]];
      [s appendString:@" "];
      hasName = YES;
    }
    if(hasName)
      [s appendString:@"<"];
    [s appendString:[addr address]];
    if(hasName)
      [s appendString:@">"];
    [ma addObject:s];
  }
  return ma;
}

/* handling requests */

- (void)getAddressesFromFormValues:(NSDictionary *)_dict {
  NSMutableArray *rawTo, *rawCc, *rawBcc;
  NSArray *keys;
  unsigned i, count;

  rawTo  = [NSMutableArray arrayWithCapacity:4];
  rawCc  = [NSMutableArray arrayWithCapacity:4];
  rawBcc = [NSMutableArray arrayWithCapacity:2];
  
  keys  = [_dict allKeys];
  count = [keys count];
  for (i = 0; i < count; i++) {
    NSString *key;
    
    key = [keys objectAtIndex:i];
    if([key hasPrefix:@"addr_"]) {
      NSString *idx, *addr, *popupKey, *popupValue;
      
      addr = [[_dict objectForKey:key] lastObject];
      idx  = [self getIndexFromIdentifier:key];
      popupKey = [NSString stringWithFormat:@"popup_%@", idx];
      popupValue = [[_dict objectForKey:popupKey] lastObject];
      if([popupValue isEqualToString:@"0"])
        [rawTo addObject:addr];
      else if([popupValue isEqualToString:@"1"])
        [rawCc addObject:addr];
      else
        [rawBcc addObject:addr];
    }
  }
  
  [self setTo:rawTo];
  [self setCc:rawCc];
  [self setBcc:rawBcc];
}

- (NSString *)getIndexFromIdentifier:(NSString *)_identifier {
  NSRange r;
  
  r = [_identifier rangeOfString:@"_"];
  return [_identifier substringFromIndex:NSMaxRange(r)];
}

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  /* OK, we have a special form value processor */
  NSDictionary *d;

  if ((d = [_rq formValues]) == nil)
    return;

#if 0
  [self debugWithFormat:@"Note: will take values ..."];
  NSLog(@"%s formValues: %@",
        __PRETTY_FUNCTION__,
        d);
#endif
  [self getAddressesFromFormValues:d];
}

/* response generation */

- (NSString *)jsCode {
  // TODO: can't we put this into a resource?
  // TODO: might be better to use -stringByReplacingBindings: etc
  static NSString *script = \
  @"var currentIndex = %d;\n"
  @"\n"
  @"function hasAddress(email) {\n"
  @"  var e = document.getElementById(email);\n"
  @"  if(e)\n"
  @"    return true;\n"
  @"  return false;\n"
  @"}\n"
  @"\n"
  @"function rememberAddress(email) {\n"
  @"  var list, span, idx;\n"
  @"  \n"
  @"  list = document.getElementById('addr_addresses');\n"
  @"  span = document.createElement('span');\n"
  @"  span.id = email;\n"
  @"  idx = document.createTextNode(currentIndex);\n"
  @"  span.appendChild(idx);\n"
  @"  list.appendChild(span);\n"
  @"}\n"
  @"\n"
  @"function sanitizedCn(cn) {\n"
  @"  var parts;\n"
  @"  parts = cn.split(', ');\n"
  @"  if(parts.length == 1)\n"
  @"    return cn;\n"
  @"  return parts[0];\n"
  @"}\n"
  @"\n"
  @"function addAddress(type, cn, dn, email, uid, sn) {\n"
  @"  var shouldAddRow, s, e;\n"
  @"  \n"
  @"  shouldAddRow = true;\n"
  @"  s = this.sanitizedCn(cn) + ' <' + email + '>';\n"
  @"\n"
  @"  if(this.hasAddress(email))\n"
  @"    return;\n"
  @"\n"
  @"  e = document.getElementById('addr_0');\n"
  @"  if(e.value == '') {\n"
  @"    e.value = s;\n"
  @"    shouldAddRow = false;\n"
  @"  }\n"
  @"  if(shouldAddRow) {\n"
  @"    this.fancyAddRow(false, s);\n"
  @"  }\n"
  @"  this.rememberAddress(email);\n"
  @"}\n"
  @"\n"
  @"function fancyAddRow(shouldEdit, text) {\n"
  @"  var table, lastChild, proto, row, select, input;\n"
  @"\n"
  @"  table = this.getTable();\n"
  @"  lastChild = document.getElementById('row_last');\n"
  @"\n"
  @"  currentIndex++;\n"
  @"\n"
  @"  proto = document.getElementById('row_0');\n"
  @"  row = proto.cloneNode(true);\n"
  @"  row.id = 'row_' + currentIndex;\n"
  @"\n"
  @"  select = row.childNodes[1].childNodes[1];\n"
  @"  select.name = 'popup_' + currentIndex;\n"
  @"  input = row.childNodes[3].childNodes[1];\n"
  @"  input.name  = 'addr_' + currentIndex;\n"
  @"  input.id    = 'addr_' + currentIndex;\n"
  @"  input.value = text;\n"
  @"\n"
  @"  table.insertBefore(row, lastChild);\n"
  @"  if(shouldEdit) {\n"
  @"    input.focus();\n"
  @"    input.select();\n"
  @"  }\n"
  @"}\n"
  @"\n"
  @"function removeIfNecessary(sender) {\n"
  @"  var idx, addr, table, senderRow;\n"
  @"\n"
  @"  if(sender.value != '')\n"
  @"    return;\n"
  @"  if(sender.id == 'addr_0')\n"
  @"    return;\n"
  @"  idx = this.getIndexFromIdentifier(sender.id);\n"
  @"  addr = this.findAddressWithIndex(idx);\n"
  @"  if(addr) {\n"
  @"     var addresses = document.getElementById('addr_addresses');\n"
  @"     addresses.removeChild(addr);\n"
  @"  }\n"
  @"  table = this.getTable();\n"
  @"  senderRow = this.findRowWithIndex(idx);\n"
  @"  table.removeChild(senderRow);\n"
  @"}\n"
  @"\n"
  @"function findAddressWithIndex(idx) {\n"
  @"  var list, i, count, addr, idx\n"
  @"  list = document.getElementById('addr_addresses').childNodes;\n"
  @"  count = list.length;\n"
  @"  for(i = 0; i < count; i++) {\n"
  @"    addr = list[i];\n"
  @"    if(addr.innerHTML == idx)\n"
  @"      return addr;\n"
  @"  }\n"
  @"  return null;\n"
  @"}\n"
  @"\n"
  @"function findRowWithIndex(idx) {\n"
  @"  var id = 'row_' + idx;\n"
  @"  return document.getElementById(id);\n"
  @"}\n"
  @"\n"
  @"function getIndexFromIdentifier(id) {\n"
  @"  return id.split('_')[1];\n"
  @"}\n"
  @"\n"
  @"function getTable() {\n"
  @"  return document.getElementById('addr_table').childNodes[1];\n"
  @"}\n";
  unsigned idx;
  
  idx = [self->to count] + [self->cc count] + [self->bcc count];
  
  return [NSString stringWithFormat:script, idx];
}

@end /* UIxMailToSelection */
