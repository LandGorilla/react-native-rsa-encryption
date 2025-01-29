package com.rsaencryption

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise
import org.bouncycastle.jce.provider.BouncyCastleProvider
import java.security.KeyFactory
import java.security.PublicKey
import java.security.PrivateKey
import java.security.Security
import java.security.spec.X509EncodedKeySpec
import java.security.spec.PKCS8EncodedKeySpec
import javax.crypto.Cipher
import android.util.Base64
import org.json.JSONObject
import java.security.KeyPairGenerator
import java.io.File
import java.security.Signature


class RsaEncryptionModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String {
    return NAME
  }

  @ReactMethod
  fun encrypt(pk: String, txt: String, promise: Promise) {
    try {
        Security.addProvider(BouncyCastleProvider())
        val publicKeyPEM = pk.replace("-----BEGIN PUBLIC KEY-----", "").replace(System.lineSeparator(), "").replace("-----END PUBLIC KEY-----", "").replace("\n", "")
        val publicBytes: ByteArray = Base64.decode(publicKeyPEM, Base64.DEFAULT)
        val keySpec = X509EncodedKeySpec(publicBytes)
        val keyFactory: KeyFactory = KeyFactory.getInstance("RSA")
        val pubKey: PublicKey = keyFactory.generatePublic(keySpec)
        val cipher: Cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding", "BC")
        cipher.init(Cipher.ENCRYPT_MODE, pubKey)
        var encrypted = cipher.doFinal(txt.toByteArray())
        var encoded = Base64.encodeToString(encrypted, Base64.DEFAULT)

        promise.resolve(encoded)
    } catch (e: Exception) {
        promise.reject(e.toString(), e)
    }
  }

  @ReactMethod
  fun decrypt(pk: String, txt: String, promise: Promise) {
    try {
        Security.addProvider(BouncyCastleProvider())
        val privateKeyPEM = pk.replace("-----BEGIN RSA PRIVATE KEY-----", "").replace(System.lineSeparator(), "").replace("-----END RSA PRIVATE KEY-----", "")
        val privateBytes: ByteArray = Base64.decode(privateKeyPEM, Base64.DEFAULT)
        val keySpec = PKCS8EncodedKeySpec(privateBytes)
        val keyFactory: KeyFactory = KeyFactory.getInstance("RSA")
        val privKey: PrivateKey = keyFactory.generatePrivate(keySpec)
        val cipher: Cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding", "BC")
        cipher.init(Cipher.DECRYPT_MODE, privKey)
        val encryptedBytes = Base64.decode(txt, Base64.DEFAULT)
        var decrypted = cipher.doFinal(encryptedBytes)
        var decoded = String(decrypted)

        promise.resolve(decoded)
    } catch (e: Exception) {
        promise.reject(e.toString(), e)
    }
  }


    @ReactMethod
    fun generateKeyPair(promise: Promise) {
        try {

            val keyPairGenerator = KeyPairGenerator.getInstance("RSA")
            keyPairGenerator.initialize(4096)
            val keyPair = keyPairGenerator.generateKeyPair()


            val publicKey = keyPair.public
            val privateKey = keyPair.private


            val publicKeyBase64 = Base64.encodeToString(publicKey.encoded, Base64.DEFAULT)
            val privateKeyBase64 = Base64.encodeToString(privateKey.encoded, Base64.DEFAULT)


            val publicKeyPEM = "-----BEGIN PUBLIC KEY-----\n${publicKeyBase64.trim()}\n-----END PUBLIC KEY-----"
            val privateKeyPEM = "-----BEGIN PRIVATE KEY-----\n${privateKeyBase64.trim()}\n-----END PRIVATE KEY-----"


            val result = mapOf("privateKey" to privateKeyPEM, "publicKey" to publicKeyPEM)


            promise.resolve(JSONObject(result).toString())
        } catch (e: Exception) {
            promise.reject("KeyGenerationError", "Error-generateKeyPair", e)
        }
    }

    @ReactMethod
    fun generateImageSignature(path: String, privateKeyPEM: String, promise: Promise) {
        try {
            // Leer los bytes de la imagen
            val imageBytes = File(path).readBytes()

            // Convertir clave privada PEM a PrivateKey
            val cleanedKey = privateKeyPEM.replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replace("\\s".toRegex(), "")
            val keyBytes = Base64.decode(cleanedKey, Base64.DEFAULT)
            val keySpec = PKCS8EncodedKeySpec(keyBytes)
            val keyFactory = KeyFactory.getInstance("RSA")
            val privateKey = keyFactory.generatePrivate(keySpec)

            // Firmar los datos
            val signature = Signature.getInstance("SHA256withRSA")
            signature.initSign(privateKey)
            signature.update(imageBytes)
            val signedData = signature.sign()

            // Codificar en Base64 y resolver la promesa
            val signatureBase64 = Base64.encodeToString(signedData, Base64.DEFAULT)
            promise.resolve(signatureBase64)
        } catch (e: Exception) {
            promise.reject("ImageSignatureError", "Error generating image signature", e)
        }
    }

  companion object {
    const val NAME = "RsaEncryption"
  }
}
