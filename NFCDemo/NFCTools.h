//
//  NFCTools.h
//  NFCDemo
//
//  Created by NO NAME on 2022/10/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NFCTools : NSObject

+ (NSString *)hexStringFromData:(NSData *)data;

/// BCD解码（保留0）
+ (NSString *)bcdToDec:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
