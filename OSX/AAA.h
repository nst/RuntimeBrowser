//
//  AAA.h
//  runtime_cli
//
//  Created by Nicolas Seriot on 03/04/15.
//
//

#import <Foundation/Foundation.h>

@protocol AAAProtocol <NSObject>
- (void)aaaWithCompletionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))completionHandler;
@end

typedef struct example {
    char *aString;
    int  anInt;
} Example;

@interface AAA : NSObject <AAAProtocol> {
    NSArray *_array;
    NSUInteger _i;
    struct example example;
}

@property (nonatomic, strong) NSDictionary *dictionary;

+ (NSRange)myClassMethod;

- (void)a;
- (void)b:(NSString *)s;
- (void)c:(id)s :(id)s2;

@end
