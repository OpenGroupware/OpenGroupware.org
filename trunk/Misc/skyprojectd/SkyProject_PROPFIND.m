
#include "common.h"
#include <OGoDatabaseProject/SkyProjectDocument.h>

@interface SkyProject_PROPFIND : NSObject
@end /* SkyProject_PROPFIND */

@interface NSString(WebDAV)
- (NSString *)_davCheckXMLContent;
@end

@interface WOResponse(DAVStrings)
- (void)appendDAVProperty:(NSString *)_propName value:(id)_value;
@end

@implementation NSString(WebDAV)

- (NSString *)_davCheckXMLContent {
  self = [self stringByReplacingString:@"&" withString:@"&amp;"];
  self = [self stringByReplacingString:@"<" withString:@"&lt;"];
  self = [self stringByReplacingString:@">" withString:@"&gt;"];
  return self;
}

@end /* NSString(WebDAV) */

@implementation SkyProject_PROPFIND

- (void)_appendPropsForPath:(NSString *)_path
  document:(SkyProjectDocument *)_attrs
  fileManager:(SkyProjectFileManager *)_fm
  onlyFileName:(BOOL)_onlyFileName
  request:(WORequest *)_request
  toResponse:(WOResponse *)_response
{
  NSEnumerator    *keyEnum = nil;
  NSString        *key     = nil;
  id              attrs    = nil;
  BOOL            isDoc    = YES;
  
  if (_attrs != nil) {
    attrs = _attrs;
    isDoc = YES;
  }
  else {
    if (_onlyFileName == YES) {
      attrs = [NSDictionary dictionaryWithObject:_path forKey:@"NSFilePath"];
      isDoc = NO;
    }
    else {
      if ((attrs = [_fm documentAtPath:_path]) == nil) {
        NSLog(@"ERROR[%s]: missing documentAtPath: %@",
              __PRETTY_FUNCTION__, _path);
      }
      isDoc = YES;
    }
  }
  
  [_response appendContentString:@"<D:response>\n"];

  {
    NSString *uri;
    
    uri = [attrs valueForKey:@"NSFilePath"];
    if (![uri hasSuffix:@"/"]) {
      if ([[attrs valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
        uri = [uri stringByAppendingString:@"/"];
    }
    
    [_response appendContentString:@"<D:href>"];
    [_response appendContentString:uri];
    [_response appendContentString:@"</D:href>\n"];
  }
  
  [_response appendContentString:@"<D:propstat>\n"];
  
  if ([[_request headerForKey:@"user-agent"]
                 isEqualToString:@"SKYRiX-FileManager"] == YES) {
    [_response appendContentString:
               @"<D:prop xmlns:N=\"http://www.skyrix.com/NSFileSchema/\">\n"];
    keyEnum = (isDoc == YES)
            ? [[(SkyProjectDocument *)attrs documentKeys] objectEnumerator]
            : [(NSDictionary *)attrs keyEnumerator];
    
    while ((key = [keyEnum nextObject]))
      [_response appendDAVProperty:key value:[attrs valueForKey:key]];
  }
  else {
    id value;
    
    keyEnum = (isDoc == YES)
            ? [[(SkyProjectDocument *)attrs readOnlyDocumentKeys]
                                    objectEnumerator]
            : [(NSDictionary *)_attrs keyEnumerator];
    
    [_response appendContentString:@"<D:prop>\n"];
    
    if ([[attrs valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
      [_response appendContentString:
                   @"<D:resourcetype><D:collection/></D:resourcetype>\n"];
    }
    
    if ((value = [attrs valueForKey:@"NSFileName"])) {
      [_response appendDAVProperty:@"displayname" value:value];
      [_response appendDAVProperty:@"name" value:value];
    }
    if ((value = [attrs valueForKey:NSFileSize]))
      [_response appendDAVProperty:@"getcontentlength" value:value];
    if ((value = [attrs valueForKey:@"NSFileMimeType"]))
      [_response appendDAVProperty:@"getcontenttype" value:value];
    if ((value = [attrs valueForKey:NSFileModificationDate]))
      [_response appendDAVProperty:@"getlastmodified" value:value];

    if ((value = [attrs valueForKey:@"NSFileCreationDate"]))
      [_response appendDAVProperty:@"creationdate" value:value];
    else if ((value = [attrs valueForKey:@"SkyCreationDate"]))
      [_response appendDAVProperty:@"creationdate" value:value];
    
    {
      BOOL canEdit = NO;
      
      if ([[attrs valueForKey:@"SkyStatus"] isEqualToString:@"edited"]) {
        int loginId = 0;
        
        loginId = [[[[_fm context] valueForKey:LSAccountKey]
                          valueForKey:@"companyId"] intValue];
        
        if (loginId == 1000 ||
            [[attrs valueForKey:@"SkyOwnerId"] intValue] == loginId) {
          /* only root or owner can edit file */
          canEdit = YES;
        }
      }
      if (canEdit == NO)
        [_response appendContentString:@"<D:isreadonly/>\n"];
    }
  }
  
  [_response appendContentString:
               @"</D:prop>\n"
               @"<D:status>HTTP/1.1 200 OK</D:status>\n"
               @"</D:propstat>\n"
               @"</D:response>\n"];
}

- (void)appendCollection:(NSString *)_path
  forRequest:(WORequest *)_request
  toResponse:(WOResponse *)_response
  fileManager:(SkyProjectFileManager *)_fm
  onlyFileNames:(BOOL)onlyFileNames
  onlyAttrs:(BOOL)onlyAttrs
  depth:(int)_depth
{
  /*
    Depth:
      0        - only the resource
      1        - the resource and it's immediate children
      infinity - all it's progeny
  */
  NSEnumerator *enumerator = nil;
  id           p           = nil;
  EODataSource *ds         = nil;
  BOOL         addSelf;

  addSelf = YES;
  
  if ((_depth != 0) && [_path isEqualToString:@"/"]) {
    /*
      M$ WebFolders do not like '/' added as the resource of itself at least
      with depth=1 ...
    */
    NSString *ua;
    
    ua = [_request headerForKey:@"user-agent"];

    if ([ua indexOfString:@"Microsoft Data Access"] != NSNotFound &&
        [ua indexOfString:@"DAV"] != NSNotFound)
      addSelf = NO;
  }
  
  /* add the resource */
  
  if (addSelf) {
    [self _appendPropsForPath:_path
          document:nil
          fileManager:_fm
          onlyFileName:onlyFileNames
          request:_request toResponse:_response];
  }
  
  /* add children if depth != 0 */
  
  if ((onlyAttrs == NO) && (_depth != 0)) {
    if ((ds = [_fm dataSourceAtPath:_path]) == nil) {
      NSLog(@"ERROR[%s]: missing dataSourceAtPath: %@",
            __PRETTY_FUNCTION__, _path);
    }
        
    {
      EOQualifier *qual = nil;
      
      qual = [EOQualifier qualifierWithQualifierFormat:
                          @"(NSFileType != 'NSFileTypeSymbolicLink') AND"
                          @"(NSFileType != 'NSFileTypeUnknown')", nil];
      [ds setFetchSpecification:
          [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                qualifier:qual sortOrderings:nil]];
    }
    enumerator = [[ds fetchObjects] objectEnumerator];
    while ((p = [enumerator nextObject])) {
      [self _appendPropsForPath:[p valueForKey:@"NSFileName"]
            document:p
            fileManager:_fm
            onlyFileName:onlyFileNames
            request:_request toResponse:_response];
    }
  }
}

- (WOResponse *)handleRequest:(WORequest *)_request
  fileManager:(SkyProjectFileManager *)_fm
{
  WOResponse *response     = nil;
  NSString   *path         = nil;
  BOOL       isDir         = NO;
  BOOL       onlyFileNames = NO;
  BOOL       onlyAttrs     = NO;
  int        davDepth      = -1;
  
  /* except to got an allprop request */
  response = [(WOResponse *)[WOResponse alloc] initWithRequest:_request];
  AUTORELEASE(response);
  [response setContentEncoding:NSUTF8StringEncoding];

  /* set response encoding to UTF-8 */
  [response setContentEncoding:NSUTF8StringEncoding];
  
  path = [_request uri];
  path = [path stringByUnescapingURL];
  
  if ([path length] == 0) {
    NSLog(@"ERROR[%@] missing path", __PRETTY_FUNCTION__);
    [response setStatus:404];
    return response;
  }
  
  if ([_request headerForKey:@"depth"])
    davDepth = [[_request headerForKey:@"depth"] intValue];
  
  if ([_request content] != nil) {
    NSString *content = nil;
    
    content = [[NSString alloc] initWithData:[_request content]
                                encoding:[NSString defaultCStringEncoding]];
    
    if ([content indexOfString:@"NSFileAttributes"] != NSNotFound)
      onlyAttrs = YES;
    if ([content indexOfString:@"NSFilePath"] != NSNotFound)
      onlyFileNames = YES;
    
    [content release]; content = nil;
  }
  
  if (![_fm fileExistsAtPath:path isDirectory:&isDir]) {
    [self debugWithFormat:@"WARNING[%s] missing file at path %@",
            __PRETTY_FUNCTION__, path];
    [response setStatus:404 /* not found */];
    return response;
  }

  [response setStatus:207];
  [response setHeader:@"SKYRiX skyprojectd DAV/1.0.2" forKey:@"server"];
  [response setHeader:@"text/xml; charset=\"utf-8\"" forKey:@"content-type"];
  [response appendContentString:
              @"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
              @"<D:multistatus xmlns:D=\"DAV:\">\n"];
  
  if (isDir) { /* is dir */
    [self appendCollection:path
          forRequest:_request
          toResponse:response
          fileManager:_fm
          onlyFileNames:onlyFileNames
          onlyAttrs:onlyAttrs
          depth:davDepth];
  }
  else { /* is !dir */
    [self _appendPropsForPath:path
          document:nil
          fileManager:_fm
          onlyFileName:onlyFileNames
          request:_request toResponse:response];
  }
  
  [response appendContentString:@"</D:multistatus>\n"];
  
  return response;
}

@end /* SkyProject_PROPFIND */

//<lp0:getlastmodified>Mon, 07 May 2001 12:19:50 GMT</lp0:getlastmodified>
static NSString *DAV_CAL_FMT = @"%a, %d %b %Y %H:%M:%S GMT";

@implementation WOResponse(DAVStrings)

- (void)appendDAVProperty:(NSString *)_propName value:(id)_value {
  NSString *v;
  
  [self appendContentString:@"<D:"];
  [self appendContentString:_propName];
  [self appendContentString:@">"];
  
  if ([_value isKindOfClass:[NSDate class]]) {
    static NSTimeZone *gmt = nil;
    
    if (gmt == nil)
      gmt = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
    
    _value = [_value descriptionWithCalendarFormat:DAV_CAL_FMT
                     timeZone:gmt
                     locale:nil];
  }
  
  v = [_value stringValue];
  v = [v _davCheckXMLContent];
  [self appendContentString:v];
  
  [self appendContentString:@"</D:"];
  [self appendContentString:_propName];
  [self appendContentString:@">\n"];
}

@end /* NSString(DAVStrings) */
