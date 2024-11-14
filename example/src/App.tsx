import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import { encrypt, decrypt, generateKeyPair, generateImageSignature } from 'react-native-rsa-encryption';

const publicKey = `-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA8V6SmMNGSJAIR9AfBlfe
seVsNdvr+ZG2t12sSYb8xyAWULmxK/pVr4b6Nq9eg2/0GuT/YbtSGyaxNHnJ8rzN
KdXs6iJOFEYRjds5gz3OWcwss4F7TqJgwqhHbvl0kqNkRPNS0+BKM2yEWoWu8Vc7
Uq/B/zvexA7yBzqg9DTKeUKzp1F/zsZZU2vpUEmvktU+TjfTjOYFGCTNOZWiaj+F
x0wdPWYZgc92dCLmKX8r3pS+fomqZ9q/k94zrEE5R5eaKt7U+E6jWHtmWGDNbZyH
CzRcUqMelenznAinTC1didJqYxCWj5CksFbf0b2eEaXNxvq3pLpVuitIqiMHYegK
mcqRChAO4pE01LdkhoWrV8Rt31veRpNSBy8CkcijLyAdcuDp8T0Ax6FUS5fUQH/2
5CctsrW0tIA736vT2J/EXoPrGu9s8cbew/e1KxUpZ39G5RItp7eFAishLFoZgDlm
8PQGaofeov3OsJ/8NLBHGkCL/SRPpvs0e+4p9OUjQy+0PkfQwF1UKRK7buSEsy69
M6a7Wcdva2n2aDOBQYO6QcQM5OvLCDsdZ9HDZeoljFse6VtJrGqdXNozZpD5k/DV
HE02HIDYgQzAwsyXjpNbJKLLxQA54OPvqTdlYtNI4LQYNwOdwqyPp8EyLLmbD9W+
N+dTMdIQXfwXSGbpNQgzAOMCAwEAAQ==
-----END PUBLIC KEY-----`;

const privateKey = `-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----`;

export default function App() {
  const [encrypted, setEncrypted] = React.useState<any | undefined>();
  const [decrypted, setDecrypted] = React.useState<any | undefined>();

  React.useEffect(() => {
    const handleEncryptionDecryption = async () => {
      const data = {
        photo_uuid: '0b2b577d-83c2-47cd-beab-86f58fa4358e',
        latitude: '21.2434252',
        longitude: '14.093483',
      };

      try {
        const encryptedData = await encrypt(publicKey, data);
        setEncrypted(encryptedData);

        const decryptedData = await decrypt(privateKey, encryptedData);
        setDecrypted(decryptedData);
      } catch (error) {
        console.error('Error in encryption/decryption process', error);
      }
    };

    handleEncryptionDecryption();
  }, []);

  return (
    <View style={styles.container}>
      <Text>Encrypted: {encrypted}</Text>
      <Text>Decrypted: {decrypted}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
