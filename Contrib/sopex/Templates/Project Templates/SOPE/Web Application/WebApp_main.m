//
//  �PROJECTNAME�_main.m
//  �PROJECTNAME�
//
//  Created by �FULLUSERNAME� on �DATE�.
//  Copyright (c) �YEAR� �ORGANIZATIONNAME�. All rights reserved.
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
