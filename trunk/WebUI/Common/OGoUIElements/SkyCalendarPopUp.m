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

#include <OGoFoundation/OGoComponent.h>

@interface SkyCalendarPopUp : OGoComponent
{
  NSString *elementName;  //  > elementName
  NSString *elementLabel; //  > optional: elementLabel, default: elementName
  NSString *formName;     //  > optional: formName, default: #0
  NSString *dateFormat;   //  > optional: dateFormat, default: 'yyyy-mm-dd'
                          // must contain yyyy, mm and dd somewhere
}

@end /* SkyCalendarPopUp */

#include "common.h"

@implementation SkyCalendarPopUp

- (void)dealloc {
  [self->elementName  release];
  [self->elementLabel release];
  [self->formName     release];
  [self->dateFormat   release];
  [super dealloc];
}

/* accessors */

- (void)setElementName:(NSString *)_elem {
  ASSIGNCOPY(self->elementName,_elem);
}
- (NSString *)elementName {
  return self->elementName;
}

- (void)setElementLabel:(NSString *)_elem {
  ASSIGNCOPY(self->elementLabel,_elem);
}
- (NSString *)elementLabel {
  return self->elementLabel;
}

- (void)setFormName:(NSString *)_formName {
  ASSIGNCOPY(self->formName,_formName);
}
- (NSString *)formName {
  return self->formName;
}

- (void)setDateFormat:(NSString *)_format {
  ASSIGNCOPY(self->dateFormat,_format);
}
- (NSString *)dateFormat {
  return self->dateFormat;
}
  

/* wod support */

- (NSString *)elementLabelString {
  NSString *label, *key;
  
  if (self->elementLabel)
    return self->elementLabel;
  
  key   = [@"cal_" stringByAppendingString:[self elementName]];
  label = [[self labels] valueForKey:key];
  return [key isEqualToString:label] ? [self elementName] : label;
}

- (NSString *)browseLabel {
  return [NSString stringWithFormat:@"%@ %@",
                   [[self labels] valueForKey:@"cal_browse"],
                   [self elementLabelString]];
}
- (NSString *)onMouseOverScript {
  return [NSString stringWithFormat:@"window.status='%@'; return true",
                   [self browseLabel]];
}

- (NSString *)calendarPageURL {
  WOResourceManager *rm;
  NSString *url;

  WOSession *s;

  s = [self session];
  
  rm = [[WOApplication application] resourceManager];
  
  url = [rm urlForResourceNamed:@"skycalendar.html"
            inFramework:nil
            languages:[s languages]
            request:[[self context] request]];
  
  if (url == nil) {
    [self logWithFormat:@"ERROR(%s): could not locate calendar page!",
            __PRETTY_FUNCTION__];
    url = @"/OpenGroupware.woa/WebServerResources/"
          @"English.lproj/skycalendar.html";
  }

  return url;
}
- (NSString *)popupScript {
  NSString *fullName;
  NSString *dFormat = self->dateFormat;

  if (self->formName == nil) {
    fullName = [NSString stringWithFormat:@"document.forms[0].elements['%@']",
                         self->elementName];
  }
  else {
    fullName = [NSString stringWithFormat:@"document.forms['%@']."
                         @"elements['%@']",
                         self->formName, self->elementName];
  }
  
  if (dFormat == nil) dFormat = @"yyyy-mm-dd";
  
  return [NSString stringWithFormat:
                   @"<!--\n"
                   @" var calendar_%@ = new skycalendar(%@);\n"
                   @" calendar_%@.setCalendarPage('%@');\n"
                   @" calendar_%@.setDateFormat('%@');\n"
                   @"// -->",
                   self->elementName, fullName,
                   self->elementName, [self calendarPageURL],
                   self->elementName, dFormat];
}

- (NSString *)popupLink {
  return [NSString stringWithFormat:@"javascript:calendar_%@.popup()",
                     self->elementName];
}

@end /* SkyCalendarPopUp */
