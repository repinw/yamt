package de.yamt.app

import android.app.Activity
import androidx.credentials.CreateCredentialResponse
import androidx.credentials.CreatePasswordRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.GetPasswordOption
import androidx.credentials.PasswordCredential
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.DeleteBytesRequest
import com.google.android.gms.auth.blockstore.RetrieveBytesRequest
import com.google.android.gms.auth.blockstore.StoreBytesData
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Backs up the recovery key of the user outside the app.
 *
 * Block Store keeps it in the Google account backup (end-to-end encrypted
 * when the device has a screen lock) and hands it back on a new Android
 * device. Credential Manager saves it as a password in the password manager.
 */
class KeyBackupChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val blockStore = Blockstore.getClient(activity.applicationContext)
    private val credentialManager = CredentialManager.create(activity)

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "save" -> save(call, result)
            "load" -> load(call, result)
            "delete" -> delete(call, result)
            "saveToPasswordManager" -> saveToPasswordManager(call, result)
            "loadFromPasswordManager" -> loadFromPasswordManager(result)
            else -> result.notImplemented()
        }
    }

    private fun save(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key")
        val value = call.argument<String>("value")
        if (key == null || value == null) {
            result.error(INVALID_ARGUMENTS, "Missing key or value.", null)
            return
        }
        val data = StoreBytesData.Builder()
            .setKey(key)
            .setBytes(value.toByteArray(Charsets.UTF_8))
            .setShouldBackupToCloud(true)
            .build()
        blockStore.storeBytes(data)
            .addOnSuccessListener { result.success(null) }
            .addOnFailureListener { result.error(BLOCK_STORE_FAILED, it.message, null) }
    }

    private fun load(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key")
        if (key == null) {
            result.error(INVALID_ARGUMENTS, "Missing key.", null)
            return
        }
        val request = RetrieveBytesRequest.Builder().setKeys(listOf(key)).build()
        blockStore.retrieveBytes(request)
            .addOnSuccessListener { response ->
                result.success(
                    response.blockstoreDataMap[key]?.bytes?.toString(Charsets.UTF_8),
                )
            }
            .addOnFailureListener { result.error(BLOCK_STORE_FAILED, it.message, null) }
    }

    private fun delete(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key")
        if (key == null) {
            result.error(INVALID_ARGUMENTS, "Missing key.", null)
            return
        }
        val request = DeleteBytesRequest.Builder().setKeys(listOf(key)).build()
        blockStore.deleteBytes(request)
            .addOnSuccessListener { result.success(null) }
            .addOnFailureListener { result.error(BLOCK_STORE_FAILED, it.message, null) }
    }

    private fun saveToPasswordManager(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")
        val password = call.argument<String>("password")
        if (id == null || password == null) {
            result.error(INVALID_ARGUMENTS, "Missing id or password.", null)
            return
        }
        credentialManager.createCredentialAsync(
            activity,
            CreatePasswordRequest(id, password),
            null,
            activity.mainExecutor,
            object : CredentialManagerCallback<CreateCredentialResponse, CreateCredentialException> {
                override fun onResult(response: CreateCredentialResponse) {
                    result.success(true)
                }

                override fun onError(e: CreateCredentialException) {
                    if (e is CreateCredentialCancellationException) {
                        result.success(false)
                    } else {
                        result.error(PASSWORD_MANAGER_FAILED, e.message, null)
                    }
                }
            },
        )
    }

    private fun loadFromPasswordManager(result: MethodChannel.Result) {
        credentialManager.getCredentialAsync(
            activity,
            GetCredentialRequest(listOf(GetPasswordOption())),
            null,
            activity.mainExecutor,
            object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                override fun onResult(response: GetCredentialResponse) {
                    val credential = response.credential
                    result.success((credential as? PasswordCredential)?.password)
                }

                override fun onError(e: GetCredentialException) {
                    if (e is GetCredentialCancellationException || e is NoCredentialException) {
                        result.success(null)
                    } else {
                        result.error(PASSWORD_MANAGER_FAILED, e.message, null)
                    }
                }
            },
        )
    }

    companion object {
        const val CHANNEL = "de.yamt.app/key_backup"
        private const val INVALID_ARGUMENTS = "invalid-arguments"
        private const val BLOCK_STORE_FAILED = "block-store-failed"
        private const val PASSWORD_MANAGER_FAILED = "password-manager-failed"
    }
}
