// $Id: SxTaskFolder+RSS.m 1 2004-08-20 11:17:52Z znek $

#include <SoObjects/Tasks/SxTaskFolder.h>
#include "SxRSSTaskRenderer.h"
#include "common.h"

@implementation SxTaskFolder(RSS)

/* 
   hack: in "real" SOPE this should be a "category-bound" attribute in the
         products.plist! That is, you define an attribute "rss" for the SoClass
         SxTaskFolder and SOPE will create the SxRSSTaskRenderer automagically.
*/
- (id)rssInContext:(id)_ctx {
  // TODO: implement as SoMethod!
  id renderer;
  
  if ((renderer = [SxRSSTaskRenderer renderer]) != nil)
    return [renderer rssResponseForFolder:self inContext:_ctx];
  
  return [NSException exceptionWithHTTPStatus:500
                      reason:@"RSS task rendering failed"];
}

@end /* SxTaskFolder(RSS) */
