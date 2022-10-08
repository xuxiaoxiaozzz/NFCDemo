//
//  ViewController.m
//  NFCDemo
//
//  Created by NO NAME on 2022/10/8.
//

#import "ViewController.h"
#import "NFCManager.h"
#import "NFCTools.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)read:(id)sender {
    NFCSupportsStatus status = [NFCManager isSupportsNFCReading];
    if (status == NFCSupportStatusYes) {
        [[NFCManager sharedInstance] scanTagWithSuccessBlock:^(NFCNDEFMessage * _Nonnull message, NSData * _Nullable tagId) {
            for (NFCNDEFPayload *record in message.records) {
                
                /*
                 部分    信息项    字节长度    格式
                 码头    码头    6    ASCII
                 码体    企业号    5    BCD编码的数字，最长支持10，左补0
                     设备类型    2    BCD编码的数字，0001:巡更，0002:数字门牌
                     编号    4    BCD编码的数字，最长支持8，左补0
                     签名    29    签名值( c长度 | c | s )
                 */
                //解析
                //编码类型长度
                NSData *encodeLen = [record.payload subdataWithRange:NSMakeRange(0, 1)];
                //编码类型
                NSData *encodeType = [record.payload subdataWithRange:NSMakeRange(1, 2)]; //65 6E = “en”即编码表示US-ASCII码
                //码头
                NSString *qhead = [[NSString alloc] initWithData:[record.payload subdataWithRange:NSMakeRange(3, 6)] encoding:NSASCIIStringEncoding];
                NSLog(@"码头 ：%@", qhead);
                if (![qhead isEqualToString:@"0A0000"]) {
                    NSLog(@"非中城NFC");
                    return;
                }
                //码体
                NSData *qbody = [record.payload subdataWithRange:NSMakeRange(9, record.payload.length - 9)];
                //企业号
                NSString *company = [NFCTools bcdToDec:[qbody subdataWithRange:NSMakeRange(0, 5)]];
                NSLog(@"企业号 ：%@", company);
                //设备类型
                NSString *deviceType = [NFCTools bcdToDec:[qbody subdataWithRange:NSMakeRange(5, 2)]];
                NSLog(@"设备类型 ：%@", deviceType);
                if (![qhead isEqualToString:@"0001"]) {
                    NSLog(@"非巡更设备");
                    return;
                }
                //编号
                NSString *identifier = [NFCTools bcdToDec:[qbody subdataWithRange:NSMakeRange(7, 4)]];
                NSLog(@"编号 ：%@", identifier);
                //签名
                NSData *sign = [qbody subdataWithRange:NSMakeRange(11, qbody.length - 11)];
                NSLog(@"签名 ：%@", [NFCTools hexStringFromData:sign]);
                //签名数据：码头|企业号|设备类型|码编号（CCKSID?）|UID?
                NSString *uid = [NFCTools hexStringFromData:tagId];
                NSLog(@"uid : %@", uid);
                NSString *plain = [NSString stringWithFormat:@"%@%@%@%@%@", qhead,company,deviceType,identifier,uid];
                NSData *plainData = [plain dataUsingEncoding:NSUTF8StringEncoding];
                NSLog(@"签名数据 ： %@", plain);
                //验签
                //sign plainData
            }
        } andErrorBlock:^(NSError * _Nonnull error) {
            
        }];
    } else {
        
    }
    
}

- (IBAction)write:(id)sender {
    
}

@end
