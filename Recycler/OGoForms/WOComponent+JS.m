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

#include <NGObjWeb/WOComponent.h>

/*
  JavaScript: WOComponent

    Methods
    
      void            alert([string,...])
      SendMail        SendMail()
      
      String          formatDate(date[,datefmt])
      String          formatNumber(number[,numfmt[,commasep,thousep,min,max]])
      SkyDate         parseDate(string[,datefmt])
      Number          parseNumber(string[,numfmt[,commasep,thousep,min,max]])
*/

#include "SkyJSSendMail.h"
#include <OGoFoundation/OGoSession.h>
#include "common.h"

@implementation WOComponent(SkyJSSupport)

- (id)_jsfunc_alert:(NSArray *)_array {
  NSString *s;
  
  s = [_array componentsJoinedByString:@",\n"];
  if ([s length] > 0) {
    id page;
    NSString *os;

    page = [[self context] page];
    
    if ((os = [page valueForKey:@"errorString"])) {
      if ([os length] > 0) {
        s = [[s stringByAppendingString:@"\n"]
                stringByAppendingString:os];
      }
    }
    
    [page takeValue:s forKey:@"errorString"];
  }
  return nil;
}

- (id)_jsfunc_SendMail:(NSArray *)_array {
  return [[[SkyJSSendMail alloc] init] autorelease];
}

- (id)_jsfunc_formatDate:(NSArray *)_array {
  unsigned count;
  NSString *fmt;
  NSDate   *date;
  
  if ((count = [_array count]) == 0)
    return nil;
  
  fmt = count > 1
    ? [[_array objectAtIndex:1] stringValue]
    : @"%Y-%m-%d %H:%M:%S %z";
  
  date = [_array objectAtIndex:0];
  
  if (![date isKindOfClass:[NSCalendarDate class]])
    return nil;
  
  return [date descriptionWithCalendarFormat:fmt
               timeZone:[(OGoSession *)[self session] timeZone]
               locale:nil];
}

- (id)_jsfunc_parseDate:(NSArray *)_array {
  unsigned count;
  NSString *fmt;
  id       date;
  
  if ((count = [_array count]) == 0)
    return nil;
  
  fmt = count > 1
    ? [[_array objectAtIndex:1] stringValue]
    : @"%Y-%m-%d %H:%M:%S %z";
  
  date = [[NSCalendarDate alloc] initWithString:
                                   [[_array objectAtIndex:0] stringValue]
                                 calendarFormat:fmt];
  if (date == nil)
    return nil;
  
  date = [date autorelease];
  [date setTimeZone:[(OGoSession *)[self session] timeZone]];
  
  return date;
}

static NSNumberFormatter *numFmt = nil; // THREAD

- (id)_jsfunc_formatNumber:(NSArray *)_args {
  unsigned count;
  NSString *fmt;
  NSString *s;
  
  if ((count = [_args count]) == 0)
    return nil;
  
  fmt = count > 1
    ? [[_args objectAtIndex:1] stringValue]
    : @"0";
  
  /* setup formatter */
  
  if (numFmt == nil) numFmt = [[NSNumberFormatter alloc] init];
  [numFmt setFormat:fmt];

  if (count > 2)
    [numFmt setDecimalSeparator:[[_args objectAtIndex:2] stringValue]];
  if (count > 3)
    [numFmt setThousandSeparator:[[_args objectAtIndex:3] stringValue]];
  if (count > 4) [numFmt setMinimum:[_args objectAtIndex:4]];
  if (count > 5) [numFmt setMaximum:[_args objectAtIndex:5]];
  
  s = [numFmt stringForObjectValue:[_args objectAtIndex:0]];

  return s;
}

- (id)_jsfunc_parseNumber:(NSArray *)_args {
  unsigned count;
  NSString *fmt;
  BOOL     ok;
  NSString *error = nil;
  id       value  = nil;
  
  if ((count = [_args count]) == 0)
    return nil;
  
  fmt = count > 1
    ? [[_args objectAtIndex:1] stringValue]
    : @"0";

  /* setup formatter */
  
  if (numFmt == nil) numFmt = [[NSNumberFormatter alloc] init];
  [numFmt setFormat:fmt];
  
  if (count > 2)
    [numFmt setDecimalSeparator:[[_args objectAtIndex:2] stringValue]];
  if (count > 3)
    [numFmt setThousandSeparator:[[_args objectAtIndex:3] stringValue]];
  if (count > 4) [numFmt setMinimum:[_args objectAtIndex:4]];
  if (count > 5) [numFmt setMaximum:[_args objectAtIndex:5]];
  
  ok = [numFmt getObjectValue:&value
               forString:[[_args objectAtIndex:0] stringValue]
               errorDescription:&error];
  if (!ok) {
    [self logWithFormat:@"formatting error (string='%@',fmt='%@'): %@",
            [[_args objectAtIndex:0] stringValue],
            fmt,
            error];
    return nil;
  }
  
  return value;
}

@end /* WOComponent(SkyJSSupport) */
