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

#include "UIxMailPartViewer.h"

/*
  UIxMailPartLinkViewer
  
  The generic viewer for all kinds of attachments. Renders a link to download
  the attachment.

  TODO: show info based on the 'bodyInfo' dictionary:
        { 
          bodyId = ""; 
          description = ""; 
          encoding = BASE64; 
          parameterList = { 
            "x-unix-mode" = 0666; 
             name = "IncoWEBOpenGroupwarepresentation.pdf"; 
          }; 
          size = 1314916; 
          subtype = PDF; type = application; 
        }
*/

@interface UIxMailPartLinkViewer : UIxMailPartViewer
{
}

@end

#include "common.h"

@implementation UIxMailPartLinkViewer

/* URLs */

- (NSString *)pathToAttachment {
  NSString *url, *n, *pext;

  pext = [self preferredPathExtension];

  /* path to mail controller object */
  
  url = [[self clientObject] baseURLInContext:[self context]];
  if (![url hasSuffix:@"/"]) url = [url stringByAppendingString:@"/"];
  
  /* mail relative path to body-part */
  
  n = [[self partPath] componentsJoinedByString:@"/"];
  url = [url stringByAppendingString:n];
  if ([pext isNotNull] && [pext length] > 0) {
    /* attach extension */
    url = [url stringByAppendingString:@"."];
    url = [url stringByAppendingString:pext];
  }
  
  /* 
     If we have an attachment name, we attach it, this is properly handled by
     SOGoMailBodyPart.
  */
  
  n = [self filenameForDisplay];
  if ([n isNotNull] && [n length] > 0) {
    url = [url stringByAppendingString:@"/"];
    if (isdigit([n characterAtIndex:0]))
      url = [url stringByAppendingString:@"fn-"];
    url = [url stringByAppendingString:[n stringByEscapingURL]];
    
    // TODO: should we check for a proper extension?
  }
  
  return url;
}

@end /* UIxMailPartLinkViewer */
