
#include "common.h"
#include <OGoDatabaseProject/SkyProjectDocument.h>
#include <SaxObjC/SaxMethodCallHandler.h>

@interface SkyProject_PROPPATCH : NSObject
@end /* SkyProject_PROPPATCH */

@interface SkyPropPatchSAXHandler : SaxMethodCallHandler
{
@protected
  SkyProjectDocument *document;
  NSString           *data;
  BOOL               setMode;
  BOOL               remMode;
}

- (id)initWithDocument:(SkyProjectDocument *)_doc;
@end

@implementation SkyProject_PROPPATCH

- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse         *response = nil;
  SkyProjectDocument *document = nil;
  NSString           *path     = nil;

  path = [_request uri];
  path = [path stringByUnescapingURL];
  
  if ([path length] == 0) {
    NSLog(@"ERROR[%@] missing path", __PRETTY_FUNCTION__);
    [response setStatus:404];
    return response;
  }

  if ((document = [_fm documentAtPath:path]) == nil) {
    NSLog(@"WARNING[%s] missing document for path %@", __PRETTY_FUNCTION__, path);
    [response setStatus:404];
    return response;
  }
  {
    id reader  = nil;
    id handler = nil;

    reader  = [[SaxXMLReaderFactory standardXMLReaderFactory] createXMLReader];
    handler = [[SkyPropPatchSAXHandler alloc] initWithDocument:document];

    [reader setErrorHandler:handler];
    [reader setContentHandler:handler];

    [reader parseFromSource:[_request content]];

    RELEASE(handler); handler = nil;
  }
  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);
  [response setContentEncoding:NSUTF8StringEncoding];

  if ([document save] == NO) {
    [response setStatus:500];
  }
  else {
    [response setStatus:200];
  }
  return response;
}
@end /* SkyProject_PROPPATCH */

@implementation SkyPropPatchSAXHandler

- (id)initWithDocument:(SkyProjectDocument *)_doc {
  if ((self = [super init])) {
    ASSIGN(self->document, _doc);
    [self registerNamespace:@"http://www.skyrix.com/NSFileSchema/"
          withKey:@"N"];
    [self registerNamespace:@"DAV" withKey:@"D"];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->document);
  RELEASE(self->data);
  [super dealloc];
}
#endif

- (void)start_DunknownTag:(NSString *)_tagName attributes:(id)_attrs {
}
- (void)end_DunknownTag:(NSString *)_tagName {
}

- (void)start_Dset:(id)_attrs {
  self->setMode = YES;
}
- (void)end_Dset {
  self->setMode = NO;
}
- (void)start_Dremove:(id)_attrs {
  self->remMode = YES;
}
- (void)end_Dremove {
  self->remMode = NO;
}

- (void)start_NunknownTag:(NSString *)_tagName attributes:(id)_attrs {
  RELEASE(self->data); self->data = nil;
}
- (void)end_NunknownTag:(NSString *)_tagName {
  if (self->data == nil)
    self->data = @"";

  if (self->setMode == YES) {
    [self->document takeValue:self->data forKey:_tagName];
  }
  else if (self->remMode == YES) {
    [self->document takeValue:[EONull null] forKey:_tagName];
  }
  RELEASE(self->data); self->data = nil;
}

- (void)characters:(unichar *)_chars length:(int)_len {
  if (self->data == nil)
    self->data = [[NSMutableString alloc] initWithCapacity:128];

  [(id)self->data
       appendString:[NSString stringWithCharacters:_chars length:_len]];
}

- (void)warning:(SaxParseException *)_exception {
  NSLog(@"WARNING[%s]: %@: warning: %@",
        __PRETTY_FUNCTION__, self, [_exception reason]);
}

- (void)error:(SaxParseException *)_exception {
  NSLog(@"ERROR[%s]: %@: error: %@",
        __PRETTY_FUNCTION__, self, [_exception reason]);
}

- (void)fatalError:(SaxParseException *)_exception {
  NSLog(@"FATAL_ERROR[%s]: %@: fatal: %@",
        __PRETTY_FUNCTION__, self, [_exception reason]);
  [_exception raise];
}

@end /* SkyPropPatchSAXHandler */
