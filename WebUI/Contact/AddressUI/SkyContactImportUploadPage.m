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

// TODO: clean up this messy file

/*
 * Format of the generated property list files:
 *
 *
 * {
 * type         = Person|Enterprise
 * private      = YES | NO;
 * importCnt    = x; // number of imported entries
 * ignoreCnt    = x; // number of ignored entries
 * duplicateCnt = x; // number of entries marked as duplicates
 * errorCnt     = x; // number of failed imports
 * #next         = x; // position of the next entry to be processed
 *
 * entries = (
 * // Person:
 * { firstname = ""; middlename = ""; name = ""; number = ""; nickname = "";
 *   salutation = ""; degree = ""; url = ""; gender = ""; birthday = "";
 *   addresses = { // je nach dem wie konfiguriert
 *     <addressType> = { name1 = ""; name2 = ""; name3 = "";
 *                       street = ""; zip = ""; city = ""; country = "";
 *                       state = ""; };
 *   };
 *   phones = { <phoneType> =  ""; };
 *   comment = "";
 *   keywords = "keyword, keyword, keyword";
 *   <extraAttribute> = "";
 *   ...
 *  },
 * // Enterprise:
 * { number = ""; name = ""; priority = ""; salutation = ""; url = "";
 *   bank = ""; bankCode = ""; account = ""; email = ""; 
 *   addresses = { // je nach dem wie konfiguriert
 *     <addressType> = { name1 = ""; name2 = ""; name3 = "";
 *                       street = ""; zip = ""; city = ""; country = "";
 *                       state = ""; };
 *   };
 *   phones = { <phoneType> =  ""; };
 *   comment = "";
 *   keywords = "keyword, keyword, keyword";
 *   <extraAttribute> = "";
 *   ...
 *  },
 */

#include "common.h"
#include <ctype.h>

// TODO: cleanup this mess
// TODO: I guess all this parsing stuff belongs into a separate class

// TODO: what the ????
static NSString *lastError = nil;
static inline void setLastError(const char *function, NSString *_str) {
  ASSIGN(lastError, _str);
  NSLog(@"error occured[%s]: %@", function, _str);
}

static inline BOOL consumeUntilCharacter(char *buffer,
                                         unsigned *pos,
                                         unsigned length,
                                         char     stop,
                                         BOOL     stopAfterNewLine,
                                         BOOL     *reachedNewLine)
{
  BOOL isEscaped = NO;
  char c;
  while (((*pos) < length) && // reached end of buffer
         ((!isEscaped) && ((c = buffer[*pos]) != stop))) { // found stop char
    (*pos)++;
    if (isEscaped) // ignore this character
      isEscaped = NO;
    else if (c == '\\') // ignore next character
      isEscaped = YES;
    else if ((stopAfterNewLine) && (c == '\n')) {
      if (reachedNewLine != NULL) *reachedNewLine = YES;
      return NO;
    }
  }
  return (*pos == length) ? NO : YES;
}

#define TOLERATE_NON_TERMINATED 0x01

static inline NSString *parseValue(char     *buffer,
                                   unsigned *pos,
                                   unsigned length,
                                   char     separator,
                                   BOOL     *reachedNewLine,
                                   unsigned options)
{
  char c;
  BOOL tolerant = options & TOLERATE_NON_TERMINATED;
  
  if (reachedNewLine != NULL) *reachedNewLine = NO;
  // ignore leading spaces
  while (((*pos) < length) && (isspace(c = buffer[*pos]))) {
    if (c == separator) // might by tab-separated
      break;
    (*pos)++;
    if (c == '\n') { // new line
      if (reachedNewLine != NULL) *reachedNewLine = YES;
      return @"";
    }
  }
  // reached end of buffer?
  if ((*pos) == length) return @"";
  
  // reached value separator?
  if (c == separator) {
    (*pos)++;
    return @"";
  }

  // reached string separator " or ' ?
  if ((c == '\"') || (c == '\'')) {
    unsigned start = ++(*pos);
    NSString *str;
    // only stop at new line, if tolerant-flag is checked
    if (consumeUntilCharacter(buffer, pos, length, c, // stop character
                              tolerant, // stop at new line
                              reachedNewLine // reached new line
                              )) {
      // consume 1 char
      (*pos)++;
      str = [NSString stringWithCString:buffer+start length:(*pos)-start-1];
      // go to next separator or endOfLine
      if (consumeUntilCharacter(buffer, pos, length, separator, YES,
                                reachedNewLine))
        // found separator
        (*pos)++;
      return str;
    }
    else if (tolerant) {
      // didn't find closing c (" or '), search for separator
      (*pos) = start;
      (*reachedNewLine) = NO;
      if (consumeUntilCharacter(buffer, pos, length, separator,
                                YES, reachedNewLine))
        // found separator
        (*pos)++;
      return [NSString stringWithCString:buffer+start length:(*pos)-start-1];
    }
    else {
      // didnt find closing c and don't be tolerant
      setLastError(__PRETTY_FUNCTION__,
                   [NSString stringWithFormat:
                             @"found non-terminated value"
                             @" at pos %d", *pos]);
      return nil;
    }
  }
  // is a normal string
  {
    unsigned start = *pos;
    if (consumeUntilCharacter(buffer, pos, length, separator, YES,
                              reachedNewLine)) {
      // found separator
      (*pos)++;
    }
    return [NSString stringWithCString:buffer+start length:(*pos)-start-1];
  }
}

static inline NSArray *_parseCSV(char     *buffer,
                                 char     separator,
                                 unsigned length,
                                 BOOL     stopOnError,
                                 NSArray  **columnKeys,
                                 unsigned options)
{
  unsigned            pos            = 0;
  BOOL                reachedNewLine = NO;
  NSMutableArray      *lines         = [NSMutableArray array];
  NSMutableDictionary *line          =
    [NSMutableDictionary dictionaryWithCapacity:16];
  NSString            *value;
  NSMutableArray      *columns       = [NSMutableArray array];
  unsigned            valuesPerLine  = 0;
  unsigned            lineCnt        = 1;
  unsigned            valueIdx       = 0;

  *columnKeys = columns;

  while (pos < length) {
    value = parseValue(buffer, &pos, length, separator, &reachedNewLine,
                       options);
    if (value == nil) {
      if (stopOnError) {
        setLastError(__PRETTY_FUNCTION__,
                     [NSString stringWithFormat:
                               @"error occured in line %d: %@",
                               lineCnt, lastError]);
        return nil;
      }
      value = @"";
    }
    while ([columns count] <= valueIdx)
      [columns addObject:[NSString stringWithFormat:@"column%d",
                                   [columns count]]];
    [line setObject:value forKey:[columns objectAtIndex:valueIdx]];
    valueIdx++;
    if (reachedNewLine) {
      if (!valuesPerLine) 
	valuesPerLine = [line count];
      else if (valuesPerLine > [line count]) {
        while (valuesPerLine > [line count])
          [line setObject:@"" forKey:[columns objectAtIndex:[line count]]];
      }
      else if (valuesPerLine != [line count]) {
        setLastError(__PRETTY_FUNCTION__,
                     [NSString stringWithFormat:
                               @"got differen value count in line %d: "
                               @"first:%d current:%d",
                               lineCnt, 
                               valuesPerLine, [line count]]);
        if (stopOnError) {
          setLastError(__PRETTY_FUNCTION__,
                       [NSString stringWithFormat:
                                 @"error occured in line %d: %@",
                                 lineCnt, lastError]);
          return nil;
        }
      }
      // ignore empty lines
      if ([line count]) [lines addObject:line];
      // start a new line
      line = [NSMutableDictionary dictionaryWithCapacity:valueIdx];
      lineCnt++;      
      reachedNewLine = NO;
      valueIdx = 0;
    }
  }
  
  // add last line ?
  if ([line count] > 0) {
    if (!valuesPerLine) 
      valuesPerLine = [line count];
    else if (valuesPerLine > [line count]) {
      while (valuesPerLine > [line count])
        [line setObject:@"" forKey:[columns objectAtIndex:[line count]]];
    }
    else if (valuesPerLine != [line count]) {
      setLastError(__PRETTY_FUNCTION__,
                   [NSString stringWithFormat:
                             @"got differen value count in line %d: "
                             @"first:%d current:%d", lineCnt,
                             valuesPerLine, [line count]]);
      if (stopOnError) {
        setLastError(__PRETTY_FUNCTION__,
                     [NSString stringWithFormat:
                               @"error occured in line %d: %@",
                               lineCnt, lastError]);
        return nil;
      }
    }
    [lines addObject:line];
  }
  return lines;
}

static id _emptyMappingDummy = nil;
static inline id emptyMappingDummy() {
  if (_emptyMappingDummy == nil)
    _emptyMappingDummy = RETAIN(@"__no_mapping__");
  return _emptyMappingDummy;
}


static inline NSArray *createImportEntries(NSArray      *values,
                                           NSArray      *attributes,
                                           NSDictionary *mapping)
{
  NSMutableArray *entries;
  NSEnumerator   *e;
  id             one;

  entries = [NSMutableArray arrayWithCapacity:[values count]];
  e       = [values objectEnumerator];

  while ((one = [e nextObject])) {
    // going to the values
    // one is an dictionary
    NSEnumerator        *attrE;
    id                  attr;
    id                  mapped;
    id                  val;
    NSMutableDictionary *entry =
      [NSMutableDictionary dictionaryWithCapacity:[one count]];

    attrE = [attributes objectEnumerator];
    while ((attr = [attrE nextObject])) {
      /*
        attr is a key of one
        if mapping contains a mapped value for attr, add value to new entry
      */
      mapped = [mapping objectForKey:attr];
      if ([mapped length] == 0)
        continue;
      
      /* no mapping? */
      if (mapped == emptyMappingDummy()) continue;

      /* found mapping */
      if ((val = [(NSDictionary *)one objectForKey:attr]) == nil)
        continue;

      [entry setObject:val forKey:mapped];
    }

    [entries addObject:entry];
  }

  return entries;
}

#include <OGoFoundation/OGoContentPage.h>

@interface SkyContactImportUploadPage : OGoContentPage
{
  NSString       *importType;  // file type / file format
  NSString       *contactType; // Person | Enterprise
  
  NSMutableDictionary *mapping;     // mapped attributes
  NSArray             *values;      // parsed values
  NSArray             *attributes;  // the attributes of the parsed values
                                    // to keep the ordering
  NSData         *importData;
  NSString       *importFilePath;
  NSString       *fileName;
  BOOL           importPrivate;

  BOOL           beTolerantAtNonTerminated;

  NSString *item;
  NSString *attribute;
}

@end /* SkyContactImportUploadPage */

#include <OGoFoundation/OGoFoundation.h>

@implementation SkyContactImportUploadPage

static NSDictionary *defaultCfg = nil;
static NSArray      *availPersAttr = nil;
static NSArray      *availEntAttr = nil;

+ (void)initialize {
  // TODO: clean that up and move to some plist file!
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  defaultCfg = [[ud dictionaryForKey:@"contactimport_upload_defaultcfg"] copy];
  if (defaultCfg == nil)
    NSLog(@"ERROR: missing default configuration!");
  
  if (availPersAttr == nil) {
    NSMutableArray *ma;
    NSArray *defaultAttributes;
    NSArray *addressAttributes;
    NSArray *addresses;
    NSArray *phones;
    NSArray *privateExtended;
    NSArray *publicExtended;
    NSEnumerator *e;
    id           one;
    
    ma = [NSMutableArray arrayWithCapacity:4];
    defaultAttributes = 
      [ud arrayForKey:@"contactimport_upload_defaultpersonattrs"];
    addressAttributes = [ud arrayForKey:@"contactimport_upload_addressattrs"];
    
    addresses = 
      [[ud dictionaryForKey:@"LSAddressType"] objectForKey:@"Person"];
    phones    = [[ud dictionaryForKey:@"LSTeleType"] objectForKey:@"Person"];
    privateExtended =
      [ud objectForKey:@"SkyPrivateExtendedPersonAttributes"];
    publicExtended =
      [ud objectForKey:@"SkyPublicExtendedPersonAttributes"];
    
    [ma addObjectsFromArray:defaultAttributes];
    e = [addresses objectEnumerator];
    while ((one = [e nextObject])) {
      NSEnumerator *addrE;
      id           attr;
      
      addrE = [addressAttributes objectEnumerator];
      while ((attr = [addrE nextObject])) {
        NSString *s;

        s = [[NSString alloc] initWithFormat:@"address.%@.%@", one, attr];
        [ma addObject:s];
        [s release];
      }
    }
    e = [phones objectEnumerator];
    while ((one = [e nextObject]))
      [ma addObject:[@"phone." stringByAppendingString:[one stringValue]]];
    
    e = [privateExtended objectEnumerator];
    while ((one = [e nextObject]))
      [ma addObject:[(NSDictionary *)one objectForKey:@"key"]];
    
    e = [publicExtended objectEnumerator];
    while ((one = [e nextObject]))
      [ma addObject:[(NSDictionary *)one objectForKey:@"key"]];
    
    availPersAttr = [ma copy];
  }
  // TODO: this is almost a DUP to the above code!
  if (availEntAttr == nil) {
    NSMutableArray *ma;
    NSArray *defaultAttributes;
    NSArray *addressAttributes;
    NSArray *addresses;
    NSArray *phones;
    NSArray *privateExtended;
    NSArray *publicExtended;
    NSEnumerator *e;
    id           one;
    
    ma = [NSMutableArray arrayWithCapacity:4];
    
    defaultAttributes = 
      [ud arrayForKey:@"contactimport_upload_defaultenterpriseattrs"];
    addressAttributes = [ud arrayForKey:@"contactimport_upload_addressattrs"];
    
    addresses = 
      [[ud dictionaryForKey:@"LSAddressType"] objectForKey:@"Enterprise"];
    phones    = 
      [[ud dictionaryForKey:@"LSTeleType"] objectForKey:@"Enterprise"];
    privateExtended =
      [ud objectForKey:@"SkyPrivateExtendedEnterpriseAttributes"];
    publicExtended =
      [ud objectForKey:@"SkyPublicExtendedEnterpriseAttributes"];
    
    [ma addObjectsFromArray:defaultAttributes];
    e = [addresses objectEnumerator];
    while ((one = [e nextObject])) {
      NSEnumerator *addrE;
      id           attr;
      
      addrE = [addressAttributes objectEnumerator];
      while ((attr = [addrE nextObject])) 
        [ma addObject:[NSString stringWithFormat:@"address.%@.%@",
                                one, attr]];
    }
    
    e = [phones objectEnumerator];
    while ((one = [e nextObject])) {
      [ma addObject:[NSString stringWithFormat:@"phone.%@", one]];
    }
    e = [privateExtended objectEnumerator];
    while ((one = [e nextObject]))
      [ma addObject:[(NSDictionary *)one objectForKey:@"key"]];
    
    e = [publicExtended objectEnumerator];
    while ((one = [e nextObject]))
      [ma addObject:[(NSDictionary *)one objectForKey:@"key"]];
    
    availEntAttr = [ma copy];
  }
}

- (id)init {
  if ((self = [super init])) {
    self->contactType   = @"Person";
    self->importPrivate = YES;
  }
  return self;
}

- (void)dealloc {
  [self->importType     release];
  [self->mapping        release];
  [self->values         release];
  [self->attributes     release];
  [self->importData     release];
  [self->importFilePath release];
  [self->contactType    release];
  [self->item           release];
  [self->attribute      release];
  [self->fileName       release];
  [super dealloc];
}

/* accessors */

- (void)setImportType:(NSString *)_type {
  ASSIGN(self->importType,_type);
}
- (NSString *)importType {
  return self->importType;
}

- (void)setImportData:(NSData *)_data {
  ASSIGN(self->importData,_data);
}
- (NSData *)importData {
  return self->importData;
}
- (BOOL)hasImportData {
  return [self->values count];
}

- (void)setImportFilePath:(NSString *)_path {
  ASSIGN(self->importFilePath,_path);
}
- (NSString *)importFilePath {
  return self->importFilePath;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (void)setImportPrivate:(BOOL)_flag {
  self->importPrivate = _flag;
}
- (BOOL)importPrivate {
  return self->importPrivate;
}

- (NSArray *)attributes { return self->attributes; }
- (void)setAttribute:(id)_attr {
  ASSIGN(self->attribute,_attr);
}
- (id)attribute {
  return self->attribute;
}

- (void)setBeTolerantAtNonTerminated:(BOOL)_flag {
  self->beTolerantAtNonTerminated = _flag;
}
- (BOOL)beTolerantAtNonTerminated {
  return self->beTolerantAtNonTerminated;
}

- (void)setMappedAttribute:(NSString *)_mapped {
  if (_mapped == nil) _mapped = emptyMappingDummy();
  [self->mapping setObject:_mapped forKey:self->attribute];
}
- (NSString *)mappedAttribute {
  id mapped = [self->mapping objectForKey:self->attribute];
  if (mapped == emptyMappingDummy()) return nil;
  return mapped;
}

- (unsigned)options {
  unsigned opt = 0x0;
  if (self->beTolerantAtNonTerminated)
    opt |= TOLERATE_NON_TERMINATED;
  return opt;
}

/* wod support */

- (BOOL)isEditorPage { 
  return YES; 
}

- (NSString *)attributeLabel {
  NSString *l;
  
  if ([self->attribute hasPrefix:@"column"]) {
    l = [self->attribute substringFromIndex:6];
    return [NSString stringWithFormat:@"%@ %@",
                     [[self labels] valueForKey:@"import_attribute_column"],
                     l];
  }
  l = [NSString stringWithFormat:@"import_attribute_%@",self->attribute];
  return [[self labels] valueForKey:l];
}

- (NSString *)windowTitle {
  NSString *l;

  l = [NSString stringWithFormat:@"import_label_import%@", self->contactType];
  return [[self labels] valueForKey:l];
}
- (NSString *)fileTypeLabel {
  NSString *l;
  
  l = [NSString stringWithFormat:@"import_type_%@", self->item];
  return [[self labels] valueForKey:l];
}

- (NSString *)mappedAttributeLabel {
  if (self->item == nil) 
    return @"--";
  
  if ([self->item hasPrefix:@"phone."])
    return [[self labels] valueForKey:[self->item substringFromIndex:6]];
    
  if ([self->item hasPrefix:@"address."]) {
    NSString *str;
    NSRange  r;
    
    str = [self->item substringFromIndex:8];
    r   = [str rangeOfString:@"."];
    if (r.length > 0) {
      NSString *addr = [str substringToIndex:r.location];
      addr = [@"addresstype_" stringByAppendingString:addr];
      str  = [@"address_" stringByAppendingString:
		 [str substringFromIndex:(r.location + r.length)]];
      return [NSString stringWithFormat:@"%@ (%@)",
                       [[self labels] valueForKey:str],
                       [[self labels] valueForKey:addr]];
    }
  }
  
  return [[self labels] valueForKey:self->item];
}

- (NSString *)exampleValue {
  if ([self->values count] == 0) return @"";
  return [(NSDictionary *)[self->values objectAtIndex:0] 
                          objectForKey:self->attribute];
}

- (NSArray *)availablePersonAttributes {
  return availPersAttr;
}

- (NSArray *)availableEnterpriseAttributes {
  return availEntAttr;
}

- (NSArray *)availableSkyrixAttributes {
  if ([self->contactType isEqualToString:@"Person"])
    return [self availablePersonAttributes];
  if ([self->contactType isEqualToString:@"Enterprise"])
    return [self availableEnterpriseAttributes];
  NSLog(@"WARNING[%s]: unknown contact type %@",
        __PRETTY_FUNCTION__, self->contactType);
  return [NSArray array];
}

/* parsing */

- (BOOL)parseCSV:(NSDictionary *)_config {
  NSString *separator = [_config objectForKey:@"separator"];
  char     sepChar    = ',';
  unsigned lineOffset = 0;
  char     *buffer;
  BOOL     freeBuffer = NO;

  if ([separator length] > 1) {
    [self setErrorString:@"only single character separators supported so far"];
    return NO;
  }
  if ([separator length] == 1)
    sepChar = [separator characterAtIndex:0];
  lineOffset = [[_config objectForKey:@"firstLine"] intValue];

  if ([self->importData isKindOfClass:[NSString class]]) {
    unsigned len = [self->importData length]+1;
    buffer = malloc(len * sizeof(char));
    freeBuffer = YES;
    [(NSString *)self->importData getCString:buffer maxLength:len];
    buffer[len-1] = '\0';
  }
  else if ([self->importData isKindOfClass:[NSData class]]) {
    buffer = (char *)[self->importData bytes];
  }
  else {
    [self setErrorString:@"unkown data type"];
    return NO;
  }

  self->values = _parseCSV(buffer, sepChar,
                           [self->importData length], YES,
                           &self->attributes,
                           [self options]);

  if (freeBuffer && buffer != NULL) free(buffer);
  
  if (self->attributes) 
    [self->attributes retain];
  
  if (self->values == nil) {
    [self setErrorString:lastError];
    return NO;
  }
  
  if ([self->values count] <= lineOffset) {
    [self setErrorString:[[self labels] valueForKey:@"import_error_noData"]];
    self->values = nil; // still not retained
    return NO;
  }

  if (lineOffset) {
    unsigned len = [self->values count] - lineOffset;
    self->values = [self->values subarrayWithRange:
			  NSMakeRange(lineOffset,len)];
  }
  
  self->values = [self->values retain];
  return YES;
}

/* actions */

- (NSString *)tryToGetImportFileType {
  NSString *str;
  NSRange r1, r2, r3;
  
  if ([self->importData isKindOfClass:[NSString class]])
    str  = (NSString *)self->importData;
  else {
    str = [[NSString alloc] initWithCStringNoCopy:
			      (char *)[self->importData bytes]
			    length:[self->importData length]
			    freeWhenDone:NO];
  }
  
  r1 = [str rangeOfString:@","];
  r2 = [str rangeOfString:@";"];
  r3 = [str rangeOfString:@"\t"];
  
  if (str != (id)self->importData) { /* release temporary string */
    [str release];
    str = nil;
  }
  
  if (r1.length > 0) {
    if ((r2.length == 0) || (r1.location < r2.location)) {
      if ((r3.length == 0) || (r1.location < r3.location))
        return @"msoutlookcsv";
    }
  }
  if (r3.length > 0) {
    if ((r1.length == 0) || (r3.location < r1.location)) {
      if ((r2.length == 0) || (r3.location < r2.location))
        return @"netscapetsv";
    }
  }
  if (r2.length > 0) {
    if ((r1.length == 0) || (r2.location < r1.location)) {
      if ((r3.length) || (r2.location < r3.location))
        return @"msoutlookexpcsv";
    }
  }
  return nil;
}

- (id)upload {
  /* TODO: split up */
  NSDictionary *importCfg;
  NSString     *tmp;

  if (![self->importFilePath length]) {
    [self setErrorString:
          [[self labels] valueForKey:@"import_error_missingFile"]];
    [self->importData release]; self->importData = nil;
    return nil;
  }
  if (![self->importData length]) {
    [self setErrorString:
          [[self labels] valueForKey:@"import_error_missingData"]];
    [self->importData release]; self->importData = nil;
    return nil;
  }

  if (![self->importType length]) 
    [self setImportType:@"default"];
  else if ([self->importType isEqualToString:@"auto"]) {
    id type;
    
    if ((type = [self tryToGetImportFileType])) {
      ASSIGN(self->importType,type);
    }
    else {
      [self setErrorString:
            [[self labels] valueForKey:@"import_error_unableToGetFileType"]];
      return nil;
    }
  }

  tmp = [NSString stringWithFormat:@"skycontacts_%@_importcfg_%@",
		  self->contactType, self->importType];
  importCfg = [[[self session] userDefaults] dictionaryForKey:tmp];
  if (importCfg == nil) {
    [self logWithFormat:
	    @"WARNING[%s]: taking default cfg", __PRETTY_FUNCTION__];
    importCfg = defaultCfg;
  }
  
  [self->values     release]; self->values     = nil;
  [self->attributes release]; self->attributes = nil;
  [self->mapping    release]; self->mapping    = nil;

  {
    NSString *format;
    BOOL     result;
    
    format = [importCfg objectForKey:@"format"];
    if ([format isEqualToString:@"csv"]) {
      result = [self parseCSV:importCfg];
    }
    else {
      [self setErrorString:@"only csv format supported so far"];
      result = NO;
    }

    // look for preconfigured mapping
    self->mapping = [importCfg objectForKey:@"mapping"];
    if (self->mapping) 
      self->mapping = [self->mapping mutableCopy];
    else {
      self->mapping = [[NSMutableDictionary alloc] initWithCapacity:
                                           [self->attributes count]];
    }
    
    if (!result) 
      return nil;
  }
  return nil;
}

- (NSString *)fileName {
  if (self->fileName == nil) {
    self->fileName =
      [NSString stringWithFormat:@"%@_import.%@.plist",
                self->contactType,
                [[[self session] activeAccount] valueForKey:@"companyId"]];

    self->fileName = [[[[[self session] userDefaults]
                               objectForKey:@"LSAttachmentPath"]
                               stringByAppendingPathComponent:fileName]
		               copy];
  }
  return self->fileName;
}

- (BOOL)hasOldImportData {
  NSFileManager *fm = [NSFileManager defaultManager];
  return [fm fileExistsAtPath:[self fileName]];
}

- (id)proceedImport {
  id page;
  // got to import page
  [[[self session] navigation] leavePage];
  page = [self pageWithName:@"SkyContactImportPage"];
  [page takeValue:self->contactType forKey:@"contactType"];
  
  [[[self session] navigation] enterPage:page]; // this should be implicit?!
  return page;
}

- (id)abortImport {
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *l;
  
  if (![fm fileExistsAtPath:[self fileName]])
    return nil;
  
  if ([fm removeFileAtPath:[self fileName] handler:nil])
    return nil;
    
  l = [[self labels] valueForKey:@"import_error_failedRemovingImportFile"];
  [self setErrorString:l];
  return nil;
}

- (id)createImportRule {
  // attributes, values and mapping must be non nil
  NSDictionary *importRules;
  NSString     *fName;
  NSString     *es;
  
  if ([self->attributes count] == 0) {
    es = [[self labels] valueForKey:@"import_error_missingAttributes"];
    [self setErrorString:es];
    return nil;
  }
  if ([self->values count] == 0) {
    es = [[self labels] valueForKey:@"import_error_noData"];
    [self setErrorString:es];
    return nil;
  }
  if ([self->mapping count] == 0) {
    es = [[self labels] valueForKey:@"import_error_missingMapping"];
    [self setErrorString:es];
    return nil;
  }
  
  importRules = [NSDictionary dictionaryWithObjectsAndKeys:
                              createImportEntries(self->values,
                                                  self->attributes,
                                                  self->mapping), @"entries",
                              self->contactType, @"type",
                              [NSNumber numberWithBool:self->importPrivate],
                              @"private",
                              nil];

  fName = [self fileName];

  if ([importRules writeToFile:fName atomically:YES]) {
    id page;
    // success
    // got to import page
    [[[self session] navigation] leavePage];
    page = [self pageWithName:@"SkyContactImportPage"];
    [page takeValue:self->contactType forKey:@"contactType"];
    [[[self session] navigation] enterPage:page];
    return page;
  }
  
  es = [[self labels] valueForKey:@"import_error_failedWritingImportRule"];
  [self setErrorString:es];
  return nil;
}

- (id)cancel {
  return [[[self session] navigation] leavePage];
}

/* KVC */

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"contactType"]) {
    ASSIGN(self->contactType,_val);
  }
  else
    [super takeValue:_val forKey:_key];
}

@end /* SkyContactImportUploadPage */
