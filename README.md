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

    if (Platform.OS === 'ios') {
      const tag = `signerID_${UserID}`; // This tag is just an identifier
      const publicKeyPEM = await getPublicKeyPEM(tag);
      const signature = await generateImageSignature("/path/to/image", tag);
      console.log('publicKeyPEM: ' + publicKeyPEM);
      console.log('signature: ' + signature);
    }

    if (Platform.OS === 'android') {
      const keyPair = await generateKeyPair(); //android return a JSON
      const keyPairObject = JSON.parse(keyPair as unknown as string);
      const signature = await generateImageSignature("/path/to/image", keyPair.privateKey);
      console.log('privateKey-android: ' + keyPairObject.privateKey);
      console.log('publicKey-android: ' + keyPairObject.publicKey);
    }
    
} catch (error) {
    console.error("Error in encryption/decryption process", error);
}
```

The tag serves as an identifier for retrieving the public key or signing. Please use a tag formatted like this:

```js
const tag = `signerID_${UserID}`;
```

This is important to avoid using the same key for multiple users.

## Example app

The example app only shows how to encrypt and decrypt data.

- Go to the `example` folder and run `yarn install`.
- Go to the `ios` folder and run `pod install`.
- Run the app with `react-native run-ios` or by opening `RsaEncryptionExample.xcworkspace` with Xcode.

<br/>
