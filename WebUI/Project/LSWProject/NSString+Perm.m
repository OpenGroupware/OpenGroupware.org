
#include "NSString+Perm.h"
#include "common.h"

@implementation NSString(Perm)

static NSNumber *yesNum = nil;

- (NSMutableDictionary *)splitAccessPermissionString {
  /* this turns: 'rwx' into ' {r:YES,w:YES,x:YES} */
  NSMutableDictionary *dict;
  int charCnt;
  int charIdx;
  
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  
  if ((charCnt = [self length]) == 0)
    return [NSMutableDictionary dictionaryWithCapacity:1];
  
  dict = [NSMutableDictionary dictionaryWithCapacity:charCnt];

  for (charIdx = 0; charIdx < charCnt; charIdx++) {
    unichar c;
    
    c = [self characterAtIndex:charIdx];
    switch (c) {
    case 'r': [dict setObject:yesNum forKey:@"r"]; break;
    case 'w': [dict setObject:yesNum forKey:@"w"]; break;
    case 'd': [dict setObject:yesNum forKey:@"d"]; break;
    case 'f': [dict setObject:yesNum forKey:@"f"]; break;
    case 'i': [dict setObject:yesNum forKey:@"i"]; break;
    case 'm': [dict setObject:yesNum forKey:@"m"]; break;
    default: {
      NSString *s;
      
      s = [[NSString alloc] initWithCharacters:&c length:1];
      [dict setObject:yesNum forKey:s];
      [s release]; 
      break;}
    }
  }
  return dict;
}

@end /* NSString(Perm) */
