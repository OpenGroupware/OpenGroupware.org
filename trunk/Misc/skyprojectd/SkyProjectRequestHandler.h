
#ifndef __SkyProjectServer__SkyProjectRequestHandler_H__
#define __SkyProjectServer__SkyProjectRequestHandler_H__

#include <NGObjWeb/WORequestHandler.h>

@interface SkyProjectRequestHandler : WORequestHandler
{
  NSMutableDictionary   *sessionIds4Auth;
}

@end

#endif /* __SkyProjectServer__SkyProjectRequestHandler_H__ */
