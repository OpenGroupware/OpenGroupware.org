// $Id$

#import "common.h"
#import "NGFileManager+DAV.h"

@implementation NGFileManager(WebDAV)

- (BOOL)lockFileAtPath:(NSString *)_path timeout:(NSTimeInterval)_time {
  if (![self supportsFeature:NGFileManagerFeature_Locking atPath:_path])
    return NO;
  
  if (_time > 0) {
    if ([(id<NGFileManagerLocking>)self lockFileAtPath:_path handler:nil]) {
      [NSTimer scheduledTimerWithTimeInterval:_time
               target:self
               selector:@selector(_davUnlockFileTimer:)
               userInfo:_path repeats:NO];
      return YES;
    }
  }
  return NO;
}

- (BOOL)_davUnlockFileTimer:(NSTimer *)_timer {
  NSString *path = nil;
  
  path = [_timer userInfo];
  
  if (![self supportsFeature:NGFileManagerFeature_Locking atPath:path])
    return NO;
  
  if ([(id<NGFileManagerLocking>)self isFileLockedAtPath:path]) {
    if ([(id<NGFileManagerLocking>)self unlockFileAtPath:path handler:nil]) {
      id ctx;
      
      if ([self respondsToSelector:@selector(context)])
        ctx = [(id)self context];
      
      return [ctx commit];
    }
  }
  return YES;
}

@end /* NGFileManager(WebDAV) */
