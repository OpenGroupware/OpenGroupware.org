// $Id$

#include "NSMutableString+EscStr.h"
#include "common.h"

@implementation NSMutableString(EscStr)

- (void)appendEscStr:(NSString *)_value {
  // TODO: UNICODE!
  void (*addBytes)(id,SEL,const char *,unsigned);
  id            dummy = nil;
  unsigned      clen;
  unsigned char *cbuf;
  unsigned char *cstr;

  if ([_value length] == 0) return;

  clen = [_value cStringLength];
  if (clen == 0) return; /* nothing to add .. */
  
  cbuf = cstr = malloc(clen + 1);
  [_value getCString:cbuf]; cbuf[clen] = '\0';
  dummy = [[NSMutableData alloc] initWithCapacity:2*clen];

  addBytes = (void*)[dummy methodForSelector:@selector(appendBytes:length:)];
  NSAssert(addBytes != NULL, @"could not get appendBytes:length: ..");
  
  while (*cstr) {
    switch (*cstr) {
      /* note that static WOString's do their encoding themselves */
      case '&':
        addBytes(dummy, @selector(appendBytes:length:), "&amp;", 5);
        break;
      case '<':
        addBytes(dummy, @selector(appendBytes:length:), "&lt;", 4);
        break;
      case '>':
        addBytes(dummy, @selector(appendBytes:length:), "&gt;", 4);
        break;
      case '"':
        addBytes(dummy, @selector(appendBytes:length:), "&quot;", 6);
        break;
      
      default:
        addBytes(dummy, @selector(appendBytes:length:), cstr, 1);
        break;
    }
    cstr++;
  }
  free(cbuf);
  {
    NSString *tmp = nil;
    
    tmp = [[NSString alloc] initWithData:dummy
                            encoding:[NSString defaultCStringEncoding]];
    [self appendString:tmp];
    RELEASE(tmp);
  }              
}

@end /* NSMutableString(XmlSchemaDecoder) */
