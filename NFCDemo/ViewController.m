//
//  ViewController.m
//  NFCDemo
//
//  Created by NO NAME on 2022/10/8.
//

#import "ViewController.h"
#import "NFCManager.h"
#import "NFCTools.h"

@interface ViewController ()<NFCTagReaderSessionDelegate>

@property (nonatomic, strong) NFCTagReaderSession *nfcSession;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}




- (IBAction)read:(id)sender {
    if (![NFCTagReaderSession readingAvailable]) {
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Error"
                                                  message:@"This device doesn't support NFC."
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        
        self.nfcSession = [[NFCTagReaderSession alloc] initWithPollingOption:(NFCPollingISO14443|NFCPollingISO15693|NFCPollingISO18092) delegate:self queue:nil];
        self.nfcSession.alertMessage = @"Hold your iPhone near the NFC tag.";
        [self.nfcSession beginSession];
}

- (void)tagReaderSessionDidBecomeActive:(NFCTagReaderSession *)session{
    
    NSLog(@"tagReaderSessionDidBecomeActive");
}


- (void)tagReaderSession:(NFCTagReaderSession *)session didInvalidateWithError:(NSError *)error {
    if (error.code == NFCReaderSessionInvalidationErrorUserCanceled) {
        NSLog(@"User canceled the session.");
    } else {
        NSLog(@"Session invalidated: %@", error.localizedDescription);
    }
}

- (void)tagReaderSession:(NFCTagReaderSession *)session didDetectTags:(NSArray<__kindof id<NFCTag>> *)tags {
    if (tags.count > 0) {
        id<NFCTag> tag = [tags firstObject];
        
        [session connectToTag:tag completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Connection error: %@", error.localizedDescription);
                [session invalidateSessionWithErrorMessage:@"Connection failed. Please try again."];
                return;
            }
            
            if (@available(iOS 13.0, *)) {
                if (tag.type == NFCTagTypeMiFare) {
                    id<NFCMiFareTag> mifareTag = (id<NFCMiFareTag>)tag;
                    
                    // 发送APDU指令来获取AID
                    NFCISO7816APDU *selectApdu = [[NFCISO7816APDU alloc] initWithInstructionClass:0x00
                                                                                   instructionCode:0xA4
                                                                                      p1Parameter:0x04
                                                                                      p2Parameter:0x00
                                                                                             data:[NSData data]
                                                                              expectedResponseLength:256];
                    [mifareTag sendMiFareISO7816Command:selectApdu completionHandler:^(NSData * _Nonnull responseData, uint8_t sw1, uint8_t sw2, NSError * _Nullable error) {
                                            
                                            
                                            if (error) {
                                                NSLog(@"APDU command error: %@", error.localizedDescription);
                                                [session invalidateSessionWithErrorMessage:@"Failed to send APDU command."];
                                                return;
                                            }
                                            
                                            // 解析响应数据以获取AID
                                            NSString *aid = [self hexStringFromData:responseData];
                                            NSLog(@"AID: %@", aid);
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                UIAlertController *alertController = [UIAlertController
                                                                                      alertControllerWithTitle:@"AID"
                                                                                      message:aid
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                                                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                                                [alertController addAction:okAction];
                                                [self presentViewController:alertController animated:YES completion:nil];
                                            });
                                            
                                            [session invalidateSession];
                                            
                    }];
                    
                }
            }
        }];
    }
}

//- (NSData *)dataFromAPDU:(NFCISO7816APDU *)apdu API_AVAILABLE(ios(11.0)) {
//    NSMutableData *data = [NSMutableData data];
//    [data appendBytes:&(apdu.instructionClass) length:1];
//    [data appendBytes:&(apdu.instructionCode) length:1];
//    [data appendBytes:&(apdu.p1Parameter) length:1];
//    [data appendBytes:&(apdu.p2Parameter) length:1];
//    UInt8 lc = (UInt8)[apdu.data length];
//    [data appendBytes:&lc length:1];
//    [data appendData:apdu.data];
//    return data;
//}

- (NSString *)hexStringFromData:(NSData *)data {
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    if (!dataBuffer) {
        return [NSString string];
    }
    
    NSUInteger dataLength = [data length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    
    return [NSString stringWithString:hexString];
}









//- (IBAction)read:(id)sender {
//    NFCSupportsStatus status = [NFCManager isSupportsNFCReading];
//    if (status == NFCSupportStatusYes) {
//        [[NFCManager sharedInstance] scanTagWithSuccessBlock:^(NFCNDEFMessage * _Nonnull message, NSData * _Nullable tagId) {
//            for (NFCNDEFPayload *record in message.records) {
//                
//                /*
//                 部分    信息项    字节长度    格式
//                 码头    码头    6    ASCII
//                 码体    企业号    5    BCD编码的数字，最长支持10，左补0
//                     设备类型    2    BCD编码的数字，0001:巡更，0002:数字门牌
//                     编号    4    BCD编码的数字，最长支持8，左补0
//                     签名    29    签名值( c长度 | c | s )
//                 */
//                //解析
//                //编码类型长度
//                NSData *encodeLen = [record.payload subdataWithRange:NSMakeRange(0, 1)];
//                //编码类型
//                NSData *encodeType = [record.payload subdataWithRange:NSMakeRange(1, 2)]; //65 6E = “en”即编码表示US-ASCII码
//                //码头
//                NSString *qhead = [[NSString alloc] initWithData:[record.payload subdataWithRange:NSMakeRange(3, 6)] encoding:NSASCIIStringEncoding];
//                NSLog(@"码头 ：%@", qhead);
//                if (![qhead isEqualToString:@"0A0000"]) {
//                    NSLog(@"非中城NFC");
//                    return;
//                }
//                //码体
//                NSData *qbody = [record.payload subdataWithRange:NSMakeRange(9, record.payload.length - 9)];
//                //企业号
//                NSString *company = [NFCTools bcdToDec:[qbody subdataWithRange:NSMakeRange(0, 5)]];
//                NSLog(@"企业号 ：%@", company);
//                //设备类型
//                NSString *deviceType = [NFCTools bcdToDec:[qbody subdataWithRange:NSMakeRange(5, 2)]];
//                NSLog(@"设备类型 ：%@", deviceType);
//                if (![qhead isEqualToString:@"0001"]) {
//                    NSLog(@"非巡更设备");
//                    return;
//                }
//                //编号
//                NSString *identifier = [NFCTools bcdToDec:[qbody subdataWithRange:NSMakeRange(7, 4)]];
//                NSLog(@"编号 ：%@", identifier);
//                //签名
//                NSData *sign = [qbody subdataWithRange:NSMakeRange(11, qbody.length - 11)];
//                NSLog(@"签名 ：%@", [NFCTools hexStringFromData:sign]);
//                //签名数据：码头|企业号|设备类型|码编号（CCKSID?）|UID?
//                NSString *uid = [NFCTools hexStringFromData:tagId];
//                NSLog(@"uid : %@", uid);
//                NSString *plain = [NSString stringWithFormat:@"%@%@%@%@%@", qhead,company,deviceType,identifier,uid];
//                NSData *plainData = [plain dataUsingEncoding:NSUTF8StringEncoding];
//                NSLog(@"签名数据 ： %@", plain);
//                //验签
//                //sign plainData
//            }
//        } andErrorBlock:^(NSError * _Nonnull error) {
//            
//        }];
//    } else {
//        
//    }
//    
//}

- (IBAction)write:(id)sender {
    
}

@end
