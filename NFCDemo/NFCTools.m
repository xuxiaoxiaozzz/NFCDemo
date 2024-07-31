//
//  NFCTools.m
//  NFCDemo
//
//  Created by NO NAME on 2022/10/8.
//

#import "NFCTools.h"

@implementation NFCTools

+ (NSString *)hexStringFromData:(NSData *)data
{
    NSAssert(data.length > 0, @"data.length <= 0");
    NSMutableString *hexString = [[NSMutableString alloc] init];
    const Byte *bytes = data.bytes;
    for (NSUInteger i=0; i<data.length; i++) {
        Byte value = bytes[i];
        Byte high = (value & 0xf0) >> 4;
        Byte low = value & 0xf;
        [hexString appendFormat:@"%x%x", high, low];
    }//for
    return hexString;
}

/// BCD解码（保留0）
+ (NSString *)bcdToDec:(NSData *)data {
    char outStr[1024] = {0};
    const unsigned char *bcd = data.bytes;
    
    int i;
    int j = 0;
    for(i = 0; i < data.length; i++) {
        int a = (bcd[i]>>4)&0x0F;
        int b = (bcd[i])&0x0F;
        outStr[j++] = a+'0';
        outStr[j++] = b+'0';
    }
    outStr[j] = '\0';
    
    return [NSString stringWithCString:outStr encoding:NSASCIIStringEncoding];
}

@end
