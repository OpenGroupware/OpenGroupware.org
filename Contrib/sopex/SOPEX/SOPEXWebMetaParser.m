//
//  SOPEXWebMetaParser.m
//  WebKitTest2
//
//  Created by Helge Hess on Thu Nov 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "SOPEXWebMetaParser.h"

@implementation SOPEXWebMetaParser

+ (id)sharedWebMetaParser {
  static id parser = nil;
  if (parser == nil) parser = [[self alloc] init];
  return parser;
}

- (void)reset {
  [self->meta  removeAllObjects];
  [self->links removeAllObjects];
}
- (void)dealloc {
  [self reset];
  [self->meta  release];
  [self->links release];
  [super dealloc];
}

/* setup */

- (void)parserDidStartDocument:(NSXMLParser *)_parser {
  [self reset];
  
  if (self->meta == nil) 
    self->meta = [[NSMutableDictionary alloc] initWithCapacity:32];
  if (self->links == nil) 
    self->links = [[NSMutableArray alloc] initWithCapacity:32];
}

/* tags */

- (void)parser:(NSXMLParser *)_parser 
  didStartElement:(NSString *)_tag
  namespaceURI:(NSString *)_nsuri
  qualifiedName:(NSString *)_qname
  attributes:(NSDictionary *)_attrs
{
  if ([_tag length] == 4) {
    if ([@"meta" caseInsensitiveCompare:_tag] == NSOrderedSame) {
      // TODO: support <meta rev="made" href="..."/>, http-equiv
      NSString *name, *content;
      
      name    = [_attrs objectForKey:@"name"];
      content = [_attrs objectForKey:@"content"];
      if (name) [self->meta setObject:content ? content : @"" forKey:name];
    }
    else if ([@"link" caseInsensitiveCompare:_tag] == NSOrderedSame) {
      // attrs: type(text/css), rel(styleshet), href(...)
      if (_attrs) [self->links addObject:_attrs];
    }
  }
}

- (void)parser:(NSXMLParser *)_parser 
  didEndElement:(NSString *)_tag
  namespaceURI:(NSString *)_nsuri
  qualifiedName:(NSString *)_qname
{
  unichar c;
  
  c = [_tag characterAtIndex:0]; // assume that a tag has at least one char
  if (!(c == 'h' || c == 'H'))
    return;
  if ([_tag length] != 4)
    return;
  if ([_tag isEqualToString:@"head"]) {
    /* only look at HEAD section */
    [_parser abortParsing];
  }
}

/* high level */

- (void)processHTML:(NSString *)_html 
  meta:(NSDictionary **)_meta
  links:(NSArray **)_links
{
  NSAutoreleasePool *pool;
  
  if ([_html length] == 0) {
    if (_meta)  *_meta  = nil;
    if (_links) *_links = nil;
    return;
  }
  
  pool = [[NSAutoreleasePool alloc] init];
  {
    NSXMLParser *parser;
    NSData      *xmlData;
    
    xmlData = [_html dataUsingEncoding:NSUTF8StringEncoding];
    parser  = [[[NSXMLParser alloc] initWithData:xmlData] autorelease];
    [parser setDelegate:self];
    [parser parse];
    
    if (_meta)  *_meta  = [self->meta  copy];
    if (_links) *_links = [self->links copy];
    [self reset];
  }
  [pool release];
  
  if (_meta)  [*_meta  autorelease];
  if (_links) [*_links autorelease];
}

@end /* SOPEXWebMetaParser */
