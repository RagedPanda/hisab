package com.ragedpanda.hisab.backup

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Keeps the scheduled-backup passphrase so a backup can run without asking.
 * The passphrase is encrypted with an AES key that lives in the Android
 * Keystore and never leaves it; only the ciphertext is stored in a private
 * prefs file. A copy of that file on another phone (device-to-device
 * restore) cannot be decrypted there, which reads as "no passphrase".
 */
object BackupPassphraseVault {
    private const val KEYSTORE = "AndroidKeyStore"
    private const val KEY_ALIAS = "hisab_scheduled_backup"
    private const val PREFS = "hisab_backup_vault"
    private const val PREF_CIPHERTEXT = "passphrase"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val TAG_BITS = 128

    fun read(context: Context): String? {
        val stored = prefs(context).getString(PREF_CIPHERTEXT, null) ?: return null
        return try {
            val bytes = Base64.decode(stored, Base64.NO_WRAP)
            val ivLength = bytes[0].toInt()
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, existingKey() ?: return null, GCMParameterSpec(TAG_BITS, bytes, 1, ivLength))
            String(cipher.doFinal(bytes, 1 + ivLength, bytes.size - 1 - ivLength), Charsets.UTF_8)
        } catch (_: Exception) {
            null
        }
    }

    fun write(context: Context, passphrase: String) {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, existingKey() ?: newKey())
        val iv = cipher.iv
        val sealed = cipher.doFinal(passphrase.toByteArray(Charsets.UTF_8))
        val stored = byteArrayOf(iv.size.toByte()) + iv + sealed
        prefs(context).edit().putString(PREF_CIPHERTEXT, Base64.encodeToString(stored, Base64.NO_WRAP)).apply()
    }

    fun delete(context: Context) {
        prefs(context).edit().remove(PREF_CIPHERTEXT).apply()
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun existingKey(): SecretKey? {
        val store = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        return (store.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.secretKey
    }

    private fun newKey(): SecretKey {
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return generator.generateKey()
    }
}
