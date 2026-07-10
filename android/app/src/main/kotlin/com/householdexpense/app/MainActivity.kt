package com.householdexpense.app

import android.os.Bundle
import androidx.core.view.WindowCompat
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.householdexpense.app/file_picker"
    private var pendingResult: MethodChannel.Result? = null

    private val pickStatementLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { activityResult ->
            handlePickResult(activityResult.resultCode, activityResult.data)
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickStatement", "pickCsv" -> {
                        if (pendingResult != null) {
                            result.error("BUSY", "File picker is already open", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        try {
                            pickStatementLauncher.launch(
                                Intent.createChooser(createPickIntent(), "Select bank statement"),
                            )
                        } catch (e: Exception) {
                            pendingResult = null
                            result.error("LAUNCH_ERROR", "Could not open file picker", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun createPickIntent(): Intent {
        return Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "*/*"
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(
                    "text/csv",
                    "text/comma-separated-values",
                    "application/csv",
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    "application/vnd.ms-excel",
                    "application/pdf",
                    "text/plain",
                    "*/*",
                ),
            )
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun handlePickResult(resultCode: Int, data: Intent?) {
        val result = pendingResult
        pendingResult = null

        if (result == null) {
            return
        }

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return
        }

        try {
            val mimeType = contentResolver.getType(uri)
            val name = queryDisplayName(uri) ?: inferNameFromMime(mimeType)
            val bytes = contentResolver.openInputStream(uri)?.use { input -> input.readBytes() }
            if (bytes == null) {
                result.error("READ_ERROR", "Could not read selected file", null)
                return
            }

            val extension = inferExtension(name, mimeType, bytes)
            val cacheFile = File(
                cacheDir,
                "statement_import_${System.currentTimeMillis()}.$extension",
            )
            cacheFile.writeBytes(bytes)

            result.success(
                mapOf(
                    "name" to name,
                    "path" to cacheFile.absolutePath,
                    "mimeType" to mimeType,
                ),
            )
        } catch (e: Exception) {
            result.error("READ_ERROR", "Could not read selected file", null)
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) {
                    return cursor.getString(index)
                }
            }
        }
        return null
    }

    private fun inferNameFromMime(mimeType: String?): String {
        return when {
            mimeType == null -> "statement"
            mimeType.contains("pdf") -> "statement.pdf"
            mimeType.contains("spreadsheetml") -> "statement.xlsx"
            mimeType.contains("ms-excel") -> "statement.xls"
            else -> "statement.csv"
        }
    }

    private fun inferExtension(name: String, mimeType: String?, bytes: ByteArray): String {
        val fromName = name.substringAfterLast('.', "")
        if (fromName.isNotEmpty()) return fromName

        if (mimeType != null) {
            when {
                mimeType.contains("pdf") -> return "pdf"
                mimeType.contains("spreadsheetml") -> return "xlsx"
                mimeType.contains("ms-excel") -> return "xls"
                mimeType.contains("csv") -> return "csv"
            }
        }

        if (bytes.size >= 4 &&
            bytes[0] == 0x25.toByte() &&
            bytes[1] == 0x50.toByte() &&
            bytes[2] == 0x44.toByte() &&
            bytes[3] == 0x46.toByte()
        ) {
            return "pdf"
        }

        if (bytes.size >= 2 &&
            bytes[0] == 0x50.toByte() &&
            bytes[1] == 0x4B.toByte()
        ) {
            return "xlsx"
        }

        return "csv"
    }
}
