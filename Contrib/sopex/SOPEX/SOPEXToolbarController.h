// $Id$

#ifndef __SOPEXToolbarController_H__
#define __SOPEXToolbarController_H__

#import <Foundation/Foundation.h>

@class NSString, NSArray, NSDictionary;
@class NSToolbar, NSWindow;

@interface SOPEXToolbarController : NSObject
{
    NSString     *toolbarID;
    NSDictionary *idToInfo;
    NSMutableDictionary *cachedItems;
    NSToolbar    *toolbar;

    id	       target;        /* non-retained ! */
}

- (id)initWithIdentifier:(NSString *)_id target:(id)_target;

/* operations */

- (void)applyOnWindow:(NSWindow *)_window;

@end

#endif /* SOPEXToolbarController */
