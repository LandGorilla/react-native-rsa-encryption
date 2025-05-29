package com.rsaencryption

import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import com.facebook.react.bridge.*
import org.bouncycastle.jce.provider.BouncyCastleProvider
import java.io.File
import java.security.*
import java.security.spec.*
import javax.crypto.Cipher

class RsaEncryptionModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  private val context: Context = reactContext

  override fun getName(): String = "RsaEncryption"

  // ---------- PEM Encryption ----------
  @ReactMethod
  fun encrypt(pk: String, txt: String, promise: Promise) {
    try {
      Security.addProvider(BouncyCastleProvider())

      val publicKeyPEM = pk
        .replace("-----BEGIN PUBLIC KEY-----", "")
        .replace("-----END PUBLIC KEY-----", "")
        .replace("\\s".toRegex(), "")

      val publicBytes = Base64.decode(publicKeyPEM, Base64.DEFAULT)
      val keySpec = X509EncodedKeySpec(publicBytes)
      val keyFactory = KeyFactory.getInstance("RSA")
      val pubKey = keyFactory.generatePublic(keySpec)

      val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding", "BC")
      cipher.init(Cipher.ENCRYPT_MODE, pubKey)

      val encrypted = cipher.doFinal(txt.toByteArray())
      val encoded = Base64.encodeToString(encrypted, Base64.NO_WRAP)

      promise.resolve(encoded)
    } catch (e: Exception) {
      promise.reject("ENCRYPT_ERROR", e)
    }
  }

  @ReactMethod
  fun decrypt(pk: String, txt: String, promise: Promise) {
    try {
      Security.addProvider(BouncyCastleProvider())

      val privateKeyPEM = pk
        .replace("-----BEGIN RSA PRIVATE KEY-----", "")
        .replace("-----BEGIN PRIVATE KEY-----", "")
        .replace("-----END RSA PRIVATE KEY-----", "")
        .replace("-----END PRIVATE KEY-----", "")
        .replace("\\s".toRegex(), "")

      val privateBytes = Base64.decode(privateKeyPEM, Base64.DEFAULT)
      val keySpec = PKCS8EncodedKeySpec(privateBytes)
      val keyFactory = KeyFactory.getInstance("RSA")
      val privKey = keyFactory.generatePrivate(keySpec)

      val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding", "BC")
      cipher.init(Cipher.DECRYPT_MODE, privKey)

      val encryptedBytes = Base64.decode(txt, Base64.DEFAULT)
      val decrypted = cipher.doFinal(encryptedBytes)

      promise.resolve(String(decrypted))
    } catch (e: Exception) {
      promise.reject("DECRYPT_ERROR", e)
    }
  }

  // ---------- Keystore Public Key ----------
  @ReactMethod
  fun getPublicKeyPEM(tag: String, promise: Promise) {
    try {
      val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

      // Intenta recuperar clave existente
      val cert = keyStore.getCertificate(tag)

      if (cert == null) {
        // No existe, generamos una nueva
        generateKeyPairWithFallback(tag)
      }

      val publicKey = keyStore.getCertificate(tag)?.publicKey
        ?: throw Exception("Public key not found for tag: $tag")

      val publicKeyBytes = publicKey.encoded
      val base64PublicKey = Base64.encodeToString(publicKeyBytes, Base64.NO_WRAP)

      val pem = "-----BEGIN PUBLIC KEY-----\n" +
        base64PublicKey.chunked(64).joinToString("\n") +
        "\n-----END PUBLIC KEY-----"

      promise.resolve(pem)
    } catch (e: Exception) {
      promise.reject("PUBLIC_KEY_ERROR", e)
    }
  }

  // ---------- Keystore Firma de Imágenes ----------
  @ReactMethod
  fun generateImageSignature(path: String, tag: String, promise: Promise) {
    try {
      val file = File(path)
      if (!file.exists()) throw Exception("File not found at path: $path")

      val imageBytes = file.readBytes()

      val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
      val privateKey = keyStore.getKey(tag, null) as? PrivateKey
        ?: throw Exception("Private key not found for tag: $tag")

      val signature = Signature.getInstance("SHA256withRSA")
      signature.initSign(privateKey)
      signature.update(imageBytes)

      val signatureBytes = signature.sign()
      val signatureBase64 = Base64.encodeToString(signatureBytes, Base64.NO_WRAP)

      promise.resolve(signatureBase64)
    } catch (e: Exception) {
      promise.reject("SIGNATURE_ERROR", e)
    }
  }

  // ---------- StrongBox KeyPair Fallback ----------
  private fun generateKeyPairWithFallback(tag: String) {
    val keyPairGenerator = KeyPairGenerator.getInstance(
      KeyProperties.KEY_ALGORITHM_RSA,
      "AndroidKeyStore"
    )

    val builder = KeyGenParameterSpec.Builder(
      tag,
      KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
    )
      .setKeySize(2048)
      .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
      .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
      .setUserAuthenticationRequired(false)

    // Intentar usar StrongBox
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      try {
        builder.setIsStrongBoxBacked(true)
        keyPairGenerator.initialize(builder.build())
        keyPairGenerator.generateKeyPair()
        return
      } catch (e: Exception) {
        // Falló con StrongBox, seguimos sin él
      }
    }

    // Generar sin StrongBox
    builder.setIsStrongBoxBacked(false)
    keyPairGenerator.initialize(builder.build())
    keyPairGenerator.generateKeyPair()
  }
}

