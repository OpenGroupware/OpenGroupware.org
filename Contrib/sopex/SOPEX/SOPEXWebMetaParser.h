//
//  SOPEXWebMetaParser.h
//  WebKitTest2
//
//  Created by Helge Hess on Thu Nov 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSMutableArray, NSMutableDictionary;

@interface SOPEXWebMetaParser : NSObject 
{
  NSMutableDictionary *meta;
  NSMutableArray      *links;
}

+ (id)sharedWebMetaParser;

/* parsing */

- (void)processHTML:(NSString *)_html 
  meta:(NSDictionary **)_meta
  links:(NSArray **)_links;

@end
