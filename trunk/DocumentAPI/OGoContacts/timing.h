
#if 0
#define TIME_START(_timeDescription) { struct timeval tv; double ti; NSString *timeDescription = nil; *(&ti) = 0; *(&timeDescription) = nil;timeDescription = [_timeDescription copy]; gettimeofday(&tv, NULL); ti =  (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0); printf("{\n");

#define TIME_END() gettimeofday(&tv, NULL); ti = (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0) - ti; printf("} [%s] <%s> : time needed: %4.4fs\n", __PRETTY_FUNCTION__, [timeDescription cString], ti < 0.0 ? -1.0 : ti); RELEASE(timeDescription); timeDescription = nil;  } 

#else

#define TIME_START(_timeDescription) ;
#define TIME_END() ;

#endif
