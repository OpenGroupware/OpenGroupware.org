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

#include "PPAddressPacker.h"
#include "PPAddressDatabase.h"
#include "PPSyncContext.h"
#include "common.h"

#define hi(x)     (((x) >> 4) & 0x0f)
#define lo(x)     ((x) & 0x0f)
#define pair(x,y) (((x) << 4) | (y))

enum {
  entryLastname, entryFirstname, entryCompany, 
  entryPhone1, entryPhone2, entryPhone3, entryPhone4, entryPhone5,
  entryAddress, entryCity, entryState, entryZip, entryCountry, entryTitle,
  entryCustom1, entryCustom2, entryCustom3, entryCustom4,
  entryNote
};

static NSString *phoneTypeKeys[8] = {
  @"phoneWork",
  @"phoneHome",
  @"phoneFax",
  @"phoneOther",
  @"phoneEmail",
  @"phoneMain",
  @"phonePager",
  @"phoneMobile"
};

static int typeForPhoneKey(NSString *key) {
  int i;
  for (i = 0; i < 8; i++) {
    if ([key isEqualToString:phoneTypeKeys[i]])
      return i;
  }
  return NSNotFound;
}

#if 0
static int realentry[19] = { 0, 1, 13, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
                             14, 15, 16, 17, 18 };
static BOOL isIdxPlainKey[19] = {
  YES, YES, YES,
  NO, NO, NO, NO, NO,
  YES, YES, YES, YES, YES, YES,
  YES, YES, YES, YES,
  YES
};
#endif

static NSString *entryKeys[19] = {
  @"lastName", @"firstName", @"company",
  @"phone1", @"phone2", @"phone3", @"phone4", @"phone5",
  @"address", @"city", @"state", @"zip", @"country", @"title",
  @"custom1", @"custom2", @"custom3", @"custom4",
  @"note"
};
static int plainKeys[] = {
  entryLastname, entryFirstname, entryCompany,
  entryAddress, entryCity, entryState, entryZip, entryCountry, entryTitle,
  entryCustom1, entryCustom2, entryCustom3, entryCustom4,
  entryNote,
  -1
};

@implementation PPAddressPacker

static EONull *null = nil;

+ (int)version {
  return [super version] + 1 /* v2 */;
}

- (id)initWithObject:(id)_object {
  if (null == nil)
    null = [[EONull null] retain];
  
  self->eo = RETAIN(_object);
  return self;
}

- (void)dealloc {
  RELEASE(self->eo);
  [super dealloc];
}

/* accessors */

- (id)object {
  return self->eo;
}

/* operations */

- (NSData *)packWithDatabase:(PPRecordDatabase *)_db {
  int            phoneTypeIndices[5];
  int            showPhoneIdx;
  char           *entry[19];
  unsigned char  record[0xffff];
  unsigned       len;
  int            i;
  unsigned char  *buffer;
  unsigned long  contents;
  unsigned long  v;
  unsigned long  phoneflag;
  unsigned char  offset;
  int            l;

#if 0
  NSLog(@"packing: %@, snapshot=%@", self->eo, [self->eo snapshot]);
#endif
  
  for (i = 0; i < 19; i++) entry[i] = NULL;
  for (i = 0; i < 5;  i++) phoneTypeIndices[i] = 0;
  showPhoneIdx = 0;
  
  for (i = 0; plainKeys[i] != -1; i++) {
    NSString *value;
    
    value = [self->eo storedValueForKey:entryKeys[plainKeys[i]]];
    
    if ([value indexOfString:@"\r\n"] != NSNotFound) {
      value = [[value componentsSeparatedByString:@"\r\n"]
                      componentsJoinedByString:@"\n"];
    }
    if (value == nil) value = @"";
    
    entry[plainKeys[i]] = (char *)[value cString];
#if 0
    NSLog(@"value of length %i for key %@ (idx=%i)",
          [value length], entryKeys[plainKeys[i]], plainKeys[i]);
#endif
  }
  
  /* generate phone values */
  {
    id       keys, showPhone;
    NSString *key;
    int      j;
    
    keys = [self->eo valueForKey:@"phoneKeys"];
    keys = [keys objectEnumerator];
    for (j = 0; (key = [keys nextObject]); j++) {
      int idx;
      
      idx = typeForPhoneKey(key);
      
      phoneTypeIndices[j] = idx;
      entry[3 + j]     = (char *)[[self->eo valueForKey:key] cString];
    }
    
    for (i = 0; j < 5; j++, i++) {
      /* fill remaining entries */
      phoneTypeIndices[j] = i;
      entry[3 + j] = "";
    }
    
    keys = [self->eo valueForKey:@"phoneKeys"];
    
    /* determine show-phone index */
    
    if ((showPhone = [self->eo valueForKey:@"showPhone"])) {
      int showPhoneType;
      int i;
      
      showPhoneType = typeForPhoneKey(showPhone);
      showPhoneIdx = -0;
      for (i = 0; i < 5; i++) {
        if (phoneTypeIndices[i] == showPhoneType) {
          showPhoneIdx = i;
          break;
        }
      }
#if 0
      NSLog(@"packer on %@/%@, showphone: %@, idx is %i",
            [self->eo valueForKey:@"company"],
            [self->eo valueForKey:@"lastName"],
            showPhone, showPhoneIdx);
#endif
    }
    else if ([keys count] > 0) {
      NSLog(@"WARNING: no showPhone is configured (keys=%@) ..", keys);
      showPhoneIdx = 0;
    }
    else {
      NSLog(@"WARNING: no showPhone is configured (no phonekeys set) ..");
      showPhoneIdx = 0;
    }
  }
  
  /* ensure that no entry is NULL */
  
  for (i = 0; i < 19; i++) {
    if (entry[i] == NULL)
      entry[i] = "";
  }
  
  /* pack address */
  
  buffer    = record + 9;
  phoneflag = 0;
  contents  = 0;
  offset    = 0;
  
  for (v = 0; v < 19; v++) {
    NSString *key;
    int slen;
    
    key = entryKeys[v];

    if (entry[v] == NULL)
      continue;
    if ((slen = strlen(entry[v])) == 0)
      continue;
    
    if (v == entryCompany)
      offset = (unsigned char)(buffer - record) - 8;
    
    contents |= (1 << v);
    
    l = slen + 1;
    //NSLog(@"writing value %s(len=%i) for key %@", entry[v], l, key);
    
    memcpy(buffer, entry[v], l);
    buffer += l;
  }
  
  phoneflag  = ((unsigned long)phoneTypeIndices[0]) << 0;
  phoneflag |= ((unsigned long)phoneTypeIndices[1]) << 4;
  phoneflag |= ((unsigned long)phoneTypeIndices[2]) << 8;
  phoneflag |= ((unsigned long)phoneTypeIndices[3]) << 12;
  phoneflag |= ((unsigned long)phoneTypeIndices[4]) << 16;
  phoneflag |= ((unsigned long)showPhoneIdx)        << 20;
  
  set_long(record,     phoneflag);
  set_long(record + 4, contents);
  set_byte(record + 8, offset);
  
  len = (buffer - record);
  
  if ((len >= 65535) || (len == 0)) {
    NSLog(@"ERROR: Resulting size of address pack is %i bytes !!", len);
    return nil;
  }
  
  return [NSData dataWithBytes:record length:len];
}

static NSString *mkString(const char *_cstr) {
  if (_cstr == NULL)
    return nil;
  if (_cstr == (void*)0xFFFF)
    return nil;
  if (strlen(_cstr) == 0)
    return nil;

  return [[NSString alloc] initWithCString:_cstr];
}

/*
  Format of an Address record:
    - a longword, split into nybbles:
        0, 0
	phone # entry to show in list
	phone #4 type
	phone #3 type
	phone #2 type
	phone #1 type
	phone #0 type
    - a longword field mask
    - a pad byte of 0x00
    - fields: only the fields actually used appear in the data; each is
        null terminated.  If a field is used, its corresponding bit
	(last name = bit 0, first name = bit 1, etc.) is set in the
	field mask.  (Notice that the format is easily extensible to
	32 fields from the current 19, at no cost to existing records...
	although observe some strange things in the AppInfo regarding
	field names.)
*/

- (int)unpackWithDatabase:(PPRecordDatabase *)_db data:(NSData *)_data {
  int           phoneTypeIndices[5];
  int           showPhoneIdx;
  char          *entry[19];
  NSString      *values[19];
  NSString      *phoneLabels[5];
  NSString      *showPhone;
  NSMutableSet  *processedKeys;
  int           i, len;
  void          (*takeValue)(id,SEL,id,NSString*);
  SEL           takeValueSel;
  unsigned long contents;
  int           v;
  unsigned char *start, *buffer;

  buffer = (void *)[_data bytes];
  start  = buffer;
  len    = [_data length];
  
  if (len < 9) {
    NSLog(@"ERROR: buffer too short for address unpack (len=%i) !", len);
    return 0;
  }
  
  takeValueSel = @selector(takeStoredValue:forKey:);
  takeValue = (void *)[self->eo methodForSelector:takeValueSel];
  
  /* get_byte(buffer); pad-byte */
  showPhoneIdx        = hi(get_byte(buffer + 1));
  phoneTypeIndices[4] = lo(get_byte(buffer + 1));
  phoneTypeIndices[3] = hi(get_byte(buffer + 2));
  phoneTypeIndices[2] = lo(get_byte(buffer + 2));
  phoneTypeIndices[1] = hi(get_byte(buffer + 3));
  phoneTypeIndices[0] = lo(get_byte(buffer + 3));
  contents         = get_long(buffer + 4);
  /* get_byte(buffer+8) offset */
  buffer += 9;
  len    -= 9;
  
#if 0 // was commented out
  if(flag & 0x1) { 
     lastname = strdup(buffer);
     buffer += strlen(buffer) + 1;
  } else {
    lastname = 0;
  }
#endif

  for (v = 0; v < 19; v++) {
    if (contents & (1 << v)) {
      int slen;
      
      if (len < 1)
        return 0;

      entry[v] =  (char*)buffer;
      slen     =  strlen(entry[v]);
      buffer   += slen + 1;
      len      -= slen + 1;

      values[v] = mkString(entry[v]);
    }
    else {
      entry[v]  = NULL;
      values[v] = nil;
    }
  }
  len = buffer - start;
  
  /* assign values */
  takeValue(self->eo, takeValueSel, values[entryLastname],  @"lastName");
  takeValue(self->eo, takeValueSel, values[entryFirstname], @"firstName");
  takeValue(self->eo, takeValueSel, values[entryCompany],   @"company");
  takeValue(self->eo, takeValueSel, values[entryAddress],   @"address");
  takeValue(self->eo, takeValueSel, values[entryCity],      @"city");
  takeValue(self->eo, takeValueSel, values[entryState],     @"state");
  takeValue(self->eo, takeValueSel, values[entryZip],       @"zip");
  takeValue(self->eo, takeValueSel, values[entryCountry],   @"country");
  takeValue(self->eo, takeValueSel, values[entryTitle],     @"title");
  takeValue(self->eo, takeValueSel, values[entryNote],      @"note");
  takeValue(self->eo, takeValueSel, values[entryCustom1],   @"custom1");
  takeValue(self->eo, takeValueSel, values[entryCustom2],   @"custom2");
  takeValue(self->eo, takeValueSel, values[entryCustom3],   @"custom3");
  takeValue(self->eo, takeValueSel, values[entryCustom4],   @"custom4");
  
  /* assign phone labels */

  processedKeys = [NSMutableSet setWithCapacity:6];
  for (i = 0; i < 5; i++) {
    id       value;
    NSString *label;
    NSString *key;
    
    label = [(PPAddressDatabase *)_db phoneLabelForType:phoneTypeIndices[i]];
    key   = phoneTypeKeys[phoneTypeIndices[i]];

    phoneLabels[i] = label;
    value = values[3 + i];

#if 0
    NSLog(@"%s: %@ phone key %@ values %@", __PRETTY_FUNCTION__,
          values[entryLastname], key, value);
#endif

    if ([processedKeys containsObject:key]) {
      if (value != null) {
        if ([value length] > 0) {
          NSLog(@"%s: WARNING: duplicate entries for key "
                @"%@ (set='%@', dup='%s')",
                __PRETTY_FUNCTION__,
                key, [self->eo valueForKey:key], value);
        }
      }
      continue;
    }
    
    takeValue(self->eo, takeValueSel, value, key);

    if (value != null) {
      if ([value length] > 0)
        [processedKeys addObject:key];
    }
  }
  
  /* assign show phone */
  
  showPhone = phoneTypeKeys[phoneTypeIndices[showPhoneIdx]];
#if 0
  NSLog(@"unpack %@/%@: %i is %@",
        values[entryCompany],
        values[entryLastname],
        showPhoneIdx,
        showPhone);
#endif
  takeValue(self->eo, takeValueSel, showPhone, @"showPhone");

#if 0 && DEBUG
  NSLog(@"decoded 'show label': %@ (idx=%i, labels=%@)",
        showPhone,
        showPhoneIdx,
        [_db phoneLabels]);
#endif
  
  /* release values */
  for (i = 0; i < 19; i++)
    RELEASE(values[i]);
  
#if 0
  NSLog(@"unpacked: %@, snapshot=%@", self->eo, [self->eo snapshot]);
#endif
  
  return len;
}

@end /* PPAddressPacker */
