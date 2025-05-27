#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RsaEncryption, NSObject)

RCT_EXTERN_METHOD(encrypt:(nonnull NSString *)pemEncoded withData:(nonnull NSDictionary *)data
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(decrypt:(nonnull NSString *)pemEncoded withEncryptedMessage:(nonnull NSString *)encryptedMessage
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(generateKeyPair:(RCTPromiseResolveBlock)resolve withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(generateImageSignature:(nonnull NSString *)path
                  withPrivateKey:(nonnull NSString *)privateKey
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
