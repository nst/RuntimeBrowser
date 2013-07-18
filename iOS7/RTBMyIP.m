//
//  MyIP.m
//  ip
//
//  Created by Nicolas Seriot on 12.11.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

#import "RTBMyIP.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

static RTBMyIP *sharedInstance = nil;

@implementation RTBMyIP

+ (RTBMyIP *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[RTBMyIP alloc] init];
    }
    return sharedInstance;
}

- (NSDictionary *)ipsForInterfaces {
	
	struct ifaddrs *list;
	if(getifaddrs(&list) < 0) {
		perror("getifaddrs");
		return nil;
	}
	
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	struct ifaddrs *cur;        
	for(cur = list; cur != NULL; cur = cur->ifa_next) {
		if(cur->ifa_addr->sa_family != AF_INET)
			continue;
		
		struct sockaddr_in *addrStruct = (struct sockaddr_in *)cur->ifa_addr;
		NSString *name = [NSString stringWithUTF8String:cur->ifa_name];
		NSString *addr = [NSString stringWithUTF8String:inet_ntoa(addrStruct->sin_addr)];
		[d setValue:addr forKey:name];
	}
	
	freeifaddrs(list);
	return d;
}

@end
