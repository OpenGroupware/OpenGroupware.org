// $Id$
//
//  SOPEXAuthPanel.m SxCallTest
//
//  Created by Helge Hess on Sun Jun 30 2002.
//  Copyright (c) 2002 SKYRIX Software AG. All rights reserved.

#import "SOPEXAuthPanel.h"

@implementation SOPEXAuthPanel

- (void)dealloc {
  [super dealloc];
}

/* accessors */

/* modal delegate */

- (void)authSheetDidEnd:(NSWindow *)_sheet
  returnCode:(int)_returnCode
  contextInfo:(void *)_info 
{
}

/* operations */

- (void)doLoginForWindow:(NSWindow *)_win {
  [NSApp beginSheet:self->window
         modalForWindow:_win
         modalDelegate:self
         didEndSelector:@selector(authSheetDidEnd:returnCode:contextInfo:)
         contextInfo:NULL];
  [NSApp runModalForWindow:_win];
  //[NSApp runModalForWindow:self->window];

  [NSApp endSheet:self->window];
  [self->window orderOut:self];
}

- (IBAction)login:(id)sender {
  [NSApp stopModal];
}

- (IBAction)cancel:(id)sender {
  [NSApp stopModal];
}

@end /* SOPEXAuthPanel */
