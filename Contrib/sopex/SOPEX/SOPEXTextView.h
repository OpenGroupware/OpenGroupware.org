/*
 Copyright (C) 2004 Marcus Mueller <znek@mulle-kybernetik.com>

 This file is part of OGo

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
// $Id$
//  Created by znek on Thu Apr 01 2004.

#ifndef	__SOPEXTextView_H_
#define	__SOPEXTextView_H_

#import <AppKit/AppKit.h>

#define SOPEXTextViewNotifiesAboutResponderState 0

@interface SOPEXTextView : NSTextView
{
    IBOutlet NSTextField *statusField;
#if SOPEXTextViewNotifiesAboutResponderState
    struct {
        unsigned respondsToWillBecomeFirstResponder: 1;
        unsigned respondsToWillResignFirstResponder: 1;
        unsigned RESERVED: sizeof(int) - 2;
    } delegateFlags;
#endif
}

- (void)setErrorStatus:(NSError *)status;

@end

#if SOPEXTextViewNotifiesAboutResponderState
@interface NSObject (SOPEXTextViewDelegate)
- (void)textViewWillBecomeFirstResponder:(SOPEXTextView *)textView;
- (void)textViewWillResignFirstResponder:(SOPEXTextView *)textView;
@end
#endif

#endif	/* __SOPEXTextView_H_ */
