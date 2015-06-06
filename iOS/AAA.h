//
//  AAA.h
//  OCRuntime
//
//  Created by Nicolas Seriot on 07/05/15.
//  Copyright (c) 2015 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct CStruct {
    struct CGImage *x;
} MyCStruct;

@protocol AAAProtocol <NSObject>

- (void)x:(id <NSCoding>)x;

@end

@interface AAA : NSObject <AAAProtocol> {
    struct dispatch_queue_s { }* _ipcQueue;
}

@property (retain) NSString *_retain;
@property (atomic, retain) NSMutableArray *_atomic_retain;
@property (nonatomic) MyCStruct myStruct;

+ (NSString *)myClassMethod;

- (NSString *)a:(NSString *)argA b:(NSString *)argB;
- (MyCStruct)sayHello;

@end
