import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-rsa-encryption' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const RsaEncryption = NativeModules.RsaEncryption
  ? NativeModules.RsaEncryption
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function encrypt(certificate: string, data: any): Promise<string> {
  return RsaEncryption.encrypt(certificate, data);
}

export function decrypt(certificate: string, encrypted: string): Promise<string> {
  return RsaEncryption.decrypt(certificate, encrypted);
}