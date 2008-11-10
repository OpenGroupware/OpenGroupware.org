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

#include <LSFoundation/LSBaseCommand.h>
#include <OGoContacts/SkyAddressDocument.h>

@interface LSGetGeoCoordinatesForAddressCommand : LSBaseCommand
{
  id address;
}

- (id)address;
- (id)_cachedCoordinatesForAddress:(id)_address inContext:(id)_context;
- (void)_cacheCoordinates:(NSString *)_coords forAddress:(id)_address inContext:(id)_context;
@end

#include "common.h"

@implementation LSGetGeoCoordinatesForAddressCommand

static NSString     *GoogleGeocodingURL;
static NSString     *LSAttachmentPath;

+ (void)initialize {
  // TODO: should check parent class version
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  GoogleGeocodingURL = [[ud objectForKey:@"GoogleGeocodingURL"] copy];
  LSAttachmentPath = [ud stringForKey:@"LSAttachmentPath"];
}

- (void)dealloc {
  [super dealloc];
}

// command methods

- (void)_executeInContext:(id)_context {
  NSDictionary *bindings;
  NSString *coordinates;
  NSArray *coordItems;
  NSString *GoogleURLString;
  NSURL *url;
  NSMutableDictionary *coordinateDict;

  coordinates = [self _cachedCoordinatesForAddress:[self address] inContext:_context];
  if (coordinates != nil) {
    //valid cached coordinates found, use them.
    coordinateDict = [[NSMutableDictionary alloc] init];
    coordItems = [coordinates componentsSeparatedByString:@","];
    [coordinateDict takeValue:[coordItems objectAtIndex:2] forKey:@"latitude"];
    [coordinateDict takeValue:[coordItems objectAtIndex:3] forKey:@"longitude"];
  } else {
    coordinateDict = [[NSMutableDictionary alloc] init];
    if ([address respondsToSelector:@selector(city)]) {
      bindings =
        [[NSDictionary alloc] initWithObjectsAndKeys:
                    [[[self address] country] stringByEscapingURL],     @"COUNTRY",
                    [[[self address] zip] stringByEscapingURL], @"ZIP",
                    [[[self address] city] stringByEscapingURL],        @"CITY",
                    [[[self address] street] stringByEscapingURL],      @"STREET",
                  nil];
    } else {
      bindings =
        [[NSDictionary alloc] initWithObjectsAndKeys:
                    [[[self address] valueForKey:@"country"] stringByEscapingURL],     @"COUNTRY",
                    [[[self address] valueForKey:@"zip"] stringByEscapingURL], @"ZIP",
                    [[[self address] valueForKey:@"city"] stringByEscapingURL],        @"CITY",
                    [[[self address] valueForKey:@"street"] stringByEscapingURL],      @"STREET",
                  nil];
    }
    GoogleURLString = [GoogleGeocodingURL copy];
    GoogleURLString = [GoogleURLString stringByReplacingVariablesWithBindings:bindings
              stringForUnknownBindings:@""];
    url = [NSURL URLWithString:GoogleURLString];
    coordinates = [NSString stringWithContentsOfURL:url];
    coordItems = [coordinates componentsSeparatedByString:@","];
    if ([[coordItems objectAtIndex:0] intValue] == 200) {      
      // The coordinates retrieved will be saved
      [coordinateDict takeValue:[coordItems objectAtIndex:2] forKey:@"latitude"];
      [coordinateDict takeValue:[coordItems objectAtIndex:3] forKey:@"longitude"];
      [self _cacheCoordinates:coordinates forAddress:[self address] inContext:_context]; 
    } else {
      // did not got fine coordinates for the address
      [coordinateDict takeValue:@"" forKey:@"latitude"];
      [coordinateDict takeValue:@"" forKey:@"longitude"];
    }
  }

  [self setReturnValue:coordinateDict]; 
}  

/* caching */
- (id)_cachedCoordinatesForAddress:(id)_address inContext:(id)_context {
  NSString      *path;
  NSString      *file;
  NSFileManager *manager;
  NSString      *aId, *oV;

  [self assert:(_address != nil) reason:@"no record to fetch address for!"];

  if ([_address respondsToSelector:@selector(asDict)]) {
    aId = [[_address asDict] valueForKey:@"addressId"];
    oV  = [[_address objectVersion] stringValue];
  } else {
    aId = [_address valueForKey:@"addressId"];
    oV  = [_address valueForKey:@"objectVersion"];
  }
  if (aId == nil) {
    [self warnWithFormat:
            @"%s: missing addressId in address: %@",
            __PRETTY_FUNCTION__, _address];
    return nil;
  }

  // old addresses may have no objectVersion set, in this case set it to 0
  if (oV == nil) oV = @"0";

  path = LSAttachmentPath;
  file = [[NSString alloc] initWithFormat:@"%@.%@.csv", aId, oV];
  path = [path stringByAppendingPathComponent:file];
  [file release]; file = nil;

  manager = [NSFileManager defaultManager];

  if ([manager fileExistsAtPath:path])
    return [NSString stringWithContentsOfFile:path];
  return nil;
}

- (void)_cacheCoordinates:(NSString *)_coords forAddress:(id)_address
  inContext:(id)_context
{
  NSString       *path;
  NSString       *file;
  NSFileManager  *manager;
  BOOL           ok;
  id aId, oV;

  [self assert:(_coords != nil) reason:@"no coordinates to save!"];
  [self assert:(_address != nil)  reason:@"no address to save coordinates for!"];

  if ([_address respondsToSelector:@selector(asDict)]) {
    aId = [[_address asDict] valueForKey:@"addressId"];
    oV  = [[_address objectVersion] stringValue];
  } else {
    aId = [_address valueForKey:@"addressId"];
    oV  = [_address valueForKey:@"objectVersion"];
  }

  if (aId == nil) {
    [self warnWithFormat:
            @"%s: missing addressId in address: %@",
            __PRETTY_FUNCTION__, _address];
    return;
  }

  // old addresses may have no objectVersion set, in this case set it to 0
  if (oV == nil) oV = @"0";

  path = LSAttachmentPath;
  file = [NSString stringWithFormat:@"%@.%@.csv", aId, oV];
  path = [path stringByAppendingPathComponent:file];

  manager = [NSFileManager defaultManager];

  if ([manager fileExistsAtPath:path])
    [manager removeFileAtPath:path handler:nil];

  ok = [_coords writeToFile:path atomically:YES];
  [self assert:ok reason:@"error during save of coordinates cache file"];
}



/* accessors */

- (void)setAddress:(id)_address {
  ASSIGN(self->address, _address);
}

- (id)address {
  return self->address;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"address"])
    [self setAddress:_value];
  else {
    NSString *s;

    s = [NSString stringWithFormat:
		    @"key: %@ is not valid in domain '%@' for operation '%@'.",
		  _key, [self domain], [self operation]];
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:s];
  }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"address"] )
    return [self address];

  return nil;
}

@end /* LSGetGeoCoordinatesForAddressCommand */
