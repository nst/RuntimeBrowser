//
//  MyIP.h
//  ip
//
//  Created by Nicolas Seriot on 12.11.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RTBMyIP : NSObject {

}

+ (RTBMyIP *)sharedInstance;
- (NSDictionary *)ipsForInterfaces;

@end
