//
//  ÇPROJECTNAMEÈ_main.m
//  ÇPROJECTNAMEÈ
//
//  Created by ÇFULLUSERNAMEÈ on ÇDATEÈ.
//  Copyright (c) ÇYEARÈ ÇORGANIZATIONNAMEÈ. All rights reserved.
//

#ifdef WITHOUT_SOPEX
#import <NGObjWeb/NGObjWeb.h>
#define SOPEXMain WOApplicationMain
#else
#import <SOPEX/SOPEX.h>
#endif /* WITHOUT_SOPEX */


int main(int argc, const char *argv[])
{
    return SOPEXMain(@"Application", argc, argv);
}
