// $Id$
//
//  SOPEXAuthPanel.h SxCallTest
//
//  Created by Helge Hess on Sun Jun 30 2002.
//  Copyright (c) 2002 SKYRIX Software AG. All rights reserved.

#ifndef __SOPEXAuthPanel_H__
#define __SOPEXAuthPanel_H__

#import <Cocoa/Cocoa.h>

@interface SOPEXAuthPanel : NSObject
{
  IBOutlet NSTextField  *loginField;
  IBOutlet NSTextField  *passwordField;
  IBOutlet NSButton     *rememberPassword;
  IBOutlet NSWindow     *window;
}

/* accessors */

/* operations */

- (void)doLoginForWindow:(NSWindow *)_win;

- (IBAction)login:(id)sender;
- (IBAction)cancel:(id)sender;

@end

#endif /* __SOPEXAuthPanel_H__ */
