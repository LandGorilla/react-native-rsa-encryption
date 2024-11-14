# react-native-rsa-encryption

Encrypts data using RSA 4096

## Installation

Add the following to `Package.json`
```sh
"react-native-lens": "https://{token}:x-oauth-basic@github.com/Land-Gorilla/react-native-rsa-encryption.git#{version}"
```

Then run 

```sh
yarn install
```

## Usage

```js
import { encrypt, decrypt } from 'react-native-rsa-encryption';

try {
    const encryptedData = await encrypt(publicKey, data);
    const decryptedData = await decrypt(privateKey, encryptedData);

    const keyPair = await generateKeyPair();
    console.log("privateKey: " + keyPair.privateKey);
    console.log("publicKey: " + keyPair.publicKey);
    const signature = await generateImageSignature("/path/to/image", keyPair.privateKey);
} catch (error) {
    console.error("Error in encryption/decryption process", error);
}
```

## Example app

The example app only shows how to encrypt and decrypt data.

- Go to the `example` folder and run `yarn install`.
- Go to the `ios` folder and run `pod install`.
- Run the app with `react-native run-ios` or by opening `RsaEncryptionExample.xcworkspace` with Xcode.

<br/>