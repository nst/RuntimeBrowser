//
//  AAA.h
//  OCRuntime
//
//  Created by Nicolas Seriot on 07/05/15.
//  Copyright (c) 2015 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AAAProtocol <NSObject>

- (void)x:(id <NSCoding>)x;

@end

@interface AAA : NSObject <AAAProtocol>

@property (retain) NSString *_retain;
@property (atomic, retain) NSMutableArray *_atomic_retain;

- (NSString *)a:(NSString *)argA b:(NSString *)argB;
- (NSString *)sayHello;

@end
