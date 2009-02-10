/*
  Copyright (C) 2007 Sebastian Reitenbach <sebastia@l00-bugdead-prods.de>

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

#include <NGObjWeb/WODynamicElement.h>
#include <LSFoundation/LSCommandContext.h>

/*
  OGoAddressMapLinks
  
  This dynamic elements is used to render links to external map servers like
  google maps. The URL template is defined via the OGoAddressMapLinks, e.g:
  google maps the default would look like:

  $ Defaults read NSGlobalDomain OGoAddressMapLinks
  {
    GeoCaching = {
        UseGoogleMapsAPI = YES;
        icon = "GeoCaching.png";
        target = "_new";
        url = "http://www.geocaching.com/seek/nearest.aspx?origin_lat=$LATITUDE$&origin_long=$LONGITUDE$";
    };
    GoogleMaps = {
        UseGoogleMapsAPI = NO;
        icon = "GoogleMaps.png";
        target = "_new";
        url = "http://maps.google.de/maps?f=q&output=html&q=$COUNTRY$+$ZIP$+$CITY$+$STREET$&btnG=Maps-Suche";
    };
  }
  

  When the address can be used directly, then as for the GoogleMaps link,
  the variables $COUNTRY$, $ZIP$, $CITY$ and $STREET$ in the URL template 
  will be replaced with the values from the address, and the link is created
  immediately.

  In case the remote service requires the use of latitude and longitude coordinates, instead
  of an address, the attribute UseGoogleMapsAPI can be set to YES. Further the 
  URL template has to contain the placeholders for $LATITUDE$ and $LONGITUDE$.

  Further it is possible to define a target in which the link will be opened, and it is 
  possible to specify custom icons. These are rendered 16x16px in the WebUI. I recommend 
  to use favicons.

  In case in one of the defined AddressLinks UseGoogleMapsAPI is set to YES, then the
  Default GoogleApiURL should be specified, e.g.:
  Defaults read NSGlobalDomain GoogleApiURL
  GoogleGeocodingURL = "http://maps.google.com/maps/geo?q=$STREET$+$CITY$+$ZIP$+$COUNTRY$&output=csv&key=ABQIAAAAgmh9UZwmExPMm0e2HrIZgRSCiDeVvkt_14vVzzjJq3BX-zYa0xRLDNiof_p9E0IwBTsnOYAVZSNEiw";

  Note: you should configure your own key.

  Further the SkyExternalLinkAction Default is used too, if defined
  an external CGI script instead of the OGo built-in redirector is used.

  The OGoAddressMapLinks can be called in webtemplates like this:

  AddressMapLinks: OGoAddressMapLinks {
    address        = address;
  }
  The only attribute is the actual address and is internally used
  to substitute the placeholders in the URL template.

  The link is only created if at least two of the parameters
  have a length > 0.

*/

@interface OGoAddressMapLinks : WODynamicElement
{
  WOAssociation *address;
  WOAssociation *linkId; 
  WOElement     *template;
}
@end

#include "common.h"
#include <NGStreams/NGInternetSocketAddress.h>
#include <OGoContacts/SkyAddressDocument.h>

@implementation OGoAddressMapLinks

static NSString *server             = nil;
static NSDictionary *daAddressMapLinks = nil;
static int useAddressMapLink        = -1;

+ (void)initialize {
  // TODO: should check parent class version
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  daAddressMapLinks = [[ud objectForKey:@"OGoAddressMapLinks"] copy];

  useAddressMapLink = [daAddressMapLinks isNotEmpty] ? 1 : 0;

  if (server == nil)
    server = [[ud stringForKey:@"SkyExternalLinkAction"] copy];

}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->template = [_t retain];
    self->address = [[_config objectForKey:@"address"] retain];
    self->linkId = [[_config objectForKey:@"linkId"] retain];
  }
  return self;
}

- (void)dealloc {
  [self->address release];
  [self->linkId release];
  [self->template release];
  [super dealloc];
}

/* request processing */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_req inContext:_ctx];
}

- (BOOL)useDirectActionOGoAddressMapLinks {
  return useAddressMapLink;
}

- (NSString *)externalLinkAction {
  return server;
}

- (NSString *)mapIconURLInContext:(WOContext *)_ctx forLink:(NSString *)_linkId {
  WOResourceManager *rm;
  NSString *mapIconURL, *mapIconName;
  NSArray *languages;
  NSDictionary *mapObject;
    
  mapIconURL = nil;
  mapObject = [daAddressMapLinks objectForKey:_linkId];
  mapIconName = [[daAddressMapLinks objectForKey:_linkId] objectForKey:@"icon"];    
  
  /** search for map icon */
    
  if ((rm = [[_ctx component] resourceManager]) == nil)
    rm = [[_ctx application] resourceManager];
    
  if (rm == nil)
    return nil;
  
  languages = [_ctx hasSession] ? [[_ctx session] languages] : (NSArray *)nil;
      
  mapIconURL = [rm urlForResourceNamed:mapIconName
                    inFramework:nil
                    languages:languages
                    request:[_ctx request]];
  return mapIconURL;
}

- (void)_appendMapLink:(NSString *)_link
  target:(NSString *)_target
  forLink:(NSString *)_linkId
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSDictionary *qd;
  NSString *mapIconURL;
  NSString *da;
  NSString *label = [_linkId copy];

  [_response appendContentString:@"<a href=\""];

  da = [self externalLinkAction];
  if ([da isNotEmpty]) {
    /// use an external server to redirect links
    da = [da stringByAppendingString:@"?url="];
    da = [da stringByAppendingString:[_link stringByEscapingURL]];
  } else {
    /// build query dictionary for direct action
    qd = [NSDictionary dictionaryWithObjectsAndKeys:
                         _link, @"url",
                       nil];
    /// build direct action
    da = [_ctx directActionURLForActionNamed:@"viewExternalLink"
               queryDictionary:qd];
  }  
  [_response appendContentString:da];
  [_response appendContentCharacter:'\"'];

  if ([_target isNotEmpty]) {
    [_response appendContentString:@"\" target=\""];
    [_response appendContentString:_target];
  }
  [_response appendContentString:@"\">"];

  if ([(mapIconURL = [self mapIconURLInContext:_ctx forLink:_linkId]) isNotEmpty]) {
    /// In case an icon is found, the icon is shown
    [_response appendContentString:@"<img border=\"0\" src=\""];
    [_response appendContentString:mapIconURL];
    [_response appendContentString:@"\" title=\""];
    [_response appendContentHTMLAttributeValue:label];
    [_response appendContentString:@"\" alt=\""];
    [_response appendContentHTMLAttributeValue:label];
    [_response appendContentString:@"\" width=\"16px\" heigth=\"16px\" />"];
  }
  else {
    /// in case no icon can be found, the label is shown
    [_response appendContentString:@"["];
    [_response appendContentHTMLString:label];
    [_response appendContentString:@"]"];
  }
  [_response appendContentString:@"</a>"];
}

- (void)appendURLMapForAddress:(SkyAddressDocument *)_address
  linkId:(NSString *)_linkId
  toResponse:(WOResponse *)_response 
  inContext:(WOContext *)_ctx 
{
  NSString     *link   = [[daAddressMapLinks objectForKey:_linkId] objectForKey:@"url"];
  NSString     *target = [[daAddressMapLinks objectForKey:_linkId] objectForKey:@"target"];
  NSDictionary *bindings;
  BOOL UseGoogleMapsAPI = NO;
  
  
  UseGoogleMapsAPI = [[[daAddressMapLinks objectForKey:_linkId] objectForKey:@"UseGoogleMapsAPI"] boolValue];    

  if (_address != nil) {
    bindings =
      [[NSDictionary alloc] initWithObjectsAndKeys:
                    [[_address country] stringByEscapingURL],	@"COUNTRY",
                    [[_address zip] stringByEscapingURL],	@"ZIP",
                    [[_address city] stringByEscapingURL],	@"CITY",
                    [[_address street] stringByEscapingURL],	@"STREET",
		  nil];
    if (UseGoogleMapsAPI) {
      LSCommandContext *cmdCtx;
      NSDictionary *coordsDict;

      cmdCtx = [[LSCommandContext alloc] init];
      if (![cmdCtx begin]) {
        [self errorWithFormat:@"could not begin cmdctx tx!"];
        [cmdCtx release]; cmdCtx = nil;
        return;
      }


      coordsDict = (NSDictionary *)[cmdCtx runCommand:@"address::get-geocode",
			@"address", _address,
			nil];
      bindings = [NSDictionary dictionaryWithObjectsAndKeys:
		[[coordsDict valueForKey:@"latitude"] stringByEscapingURL], @"LATITUDE",
		[[coordsDict valueForKey:@"longitude"] stringByEscapingURL], @"LONGITUDE",
                nil];
      [cmdCtx release]; cmdCtx = nil;
    }  
  }

  link = [link stringByReplacingVariablesWithBindings:bindings
               stringForUnknownBindings:@""];
  [self _appendMapLink:link target:target forLink:_linkId
        toResponse:_response inContext:_ctx];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  id Address;
  int cnt = 0;
  if ([[_ctx request] isFromClientComponent])
    return;
  
  Address = [self->address valueInComponent:[_ctx component]];
  if ([[Address country] length] > 0) cnt++;
  if ([[Address zip] length] > 0) cnt++;
  if ([[Address city] length] > 0) cnt++;
  if ([[Address street] length] > 0) cnt++;

  if ( cnt < 2 )
    return;

  /* content */
  [self->template appendToResponse:_response inContext:_ctx];



  if ([self useDirectActionOGoAddressMapLinks]) {
    NSEnumerator *e;
    NSArray *keys;
    NSString *key;

    keys = [daAddressMapLinks allKeys];
    e = [keys objectEnumerator];
    while ((key = [e nextObject]) != nil) {

      [self appendURLMapForAddress: Address
                linkId: key
            toResponse:_response inContext:_ctx];
    }
  }
}

@end /* OGoAddressMapLinks */
