/*
 Copyright (C) 2000-2003 SKYRIX Software AG

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
//  Created by znek on Wed Feb 11 2004.

#ifndef	__SOPEXSNSController_H_
#define	__SOPEXSNSController_H_

#import <Foundation/Foundation.h>


@interface SOPEXSNSController : NSObject
{
    NSFileHandle *serverSocket;
    NSMutableDictionary *connectionLUT;
    id delegate;
    struct {
        unsigned int respondsToUnregisterInstance: 1;
        unsigned int respondsToRegisterInstance: 1;
        unsigned int respondsToRegisterSession: 1;
        unsigned int respondsToExpireSession: 1;
        unsigned int respondsToTerminateSession: 1;
        unsigned int respondsToLookupSession: 1;
        unsigned int respondsToInstanceIsAlive: 1;
        unsigned int RESERVED: 1;
    } dflags;
}

- (void)setDelegate:(id)_delegate;
- (id)delegate;

- (void)start;
- (void)stop;

- (NSString *)socketAddress;

@end

@interface NSObject (SOPEXSNSControllerDelegate)
- (void)snsController:(SOPEXSNSController *)controller unregisterInstance:(NSDictionary *)instanceDescription;
- (void)snsController:(SOPEXSNSController *)controller registerInstance:(NSDictionary *)instanceDescription;
- (void)snsController:(SOPEXSNSController *)controller instanceIsAlive:(NSDictionary *)instanceDescription;
- (void)snsController:(SOPEXSNSController *)controller instance:(NSDictionary *)instanceDescription sessionDidCreate:(NSString *)sessionID;
- (void)snsController:(SOPEXSNSController *)controller instance:(NSDictionary *)instanceDescription sessionDidTerminate:(NSString *)sessionID;
- (void)snsController:(SOPEXSNSController *)controller instance:(NSDictionary *)instanceDescription sessionDidExpire:(NSString *)sessionID;

@end

extern NSString *SNSApplicationNameKey;
extern NSString *SNSApplicationPathKey;
extern NSString *SNSApplicationPIDKey;
extern NSString *SNSApplicationAddressKey;

#endif	/* __SOPEXSNSController_H_ */
