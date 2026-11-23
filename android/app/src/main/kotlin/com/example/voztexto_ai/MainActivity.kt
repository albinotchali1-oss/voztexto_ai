package com.example.voztexto_ai

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.voztexto_ai/output_directory"
    private val requestDirectory = 4201
    private val requestCreateFile = 4202
    private var pendingDirectoryResult: MethodChannel.Result? = null
    private var pendingCreateFileResult: MethodChannel.Result? = null
    private var pendingFileName: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickOutputDirectory" -> pickOutputDirectory(result)
                    "getDirectoryName" -> {
                        val uri = call.argument<String>("uri")
                        if (uri.isNullOrBlank()) {
                            result.error("INVALID_URI", "Pasta inválida", null)
                        } else {
                            result.success(getDocumentName(Uri.parse(uri)))
                        }
                    }
                    "openOutputDocument" -> {
                        val uri = call.argument<String>("uri")
                        if (uri.isNullOrBlank()) {
                            result.error("INVALID_URI", "Arquivo inválido", null)
                        } else {
                            openOutputDocument(Uri.parse(uri), result)
                        }
                    }
                    "createOutputDocument" -> {
                        val fileName = call.argument<String>("fileName")
                        if (fileName.isNullOrBlank()) {
                            result.error("INVALID_NAME", "Nome de arquivo inválido", null)
                        } else {
                            createOutputDocument(fileName, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun pickOutputDirectory(result: MethodChannel.Result) {
        pendingDirectoryResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }
        startActivityForResult(intent, requestDirectory)
    }

    private fun createOutputDocument(fileName: String, result: MethodChannel.Result) {
        val preferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val contentUri = preferences.getString("flutter.converter_output_directory", null)
            ?: run {
                result.error("NO_DIRECTORY", "Nenhuma pasta foi selecionada", null)
                return
            }

        try {
            val treeUri = Uri.parse(contentUri)
            val documentId = DocumentsContract.getTreeDocumentId(treeUri)
            val parentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
            val documentUri = DocumentsContract.createDocument(
                contentResolver,
                parentUri,
                "audio/mpeg",
                fileName,
            )
            result.success(documentUri?.toString())
        } catch (error: Exception) {
            result.error(
                "CREATE_FILE_ERROR",
                "Não foi possível criar o arquivo na pasta selecionada",
                error.message,
            )
        }
    }

    private fun getDocumentName(uri: Uri): String? {
        contentResolver.query(uri, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                    if (nameIndex >= 0) return cursor.getString(nameIndex)
                }
            }
        return null
    }

    private fun openOutputDocument(uri: Uri, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "audio/mpeg")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, "Abrir áudio"))
            result.success(null)
        } catch (error: Exception) {
            result.error("OPEN_FILE_ERROR", "Não foi possível abrir o MP3", error.message)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == requestDirectory) {
            val result = pendingDirectoryResult
            pendingDirectoryResult = null

            if (resultCode == Activity.RESULT_OK) {
                val uri = data?.data
                if (uri != null) {
                    try {
                        val takeFlags = (data.flags
                            and (Intent.FLAG_GRANT_READ_URI_PERMISSION
                                or Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
                        contentResolver.takePersistableUriPermission(uri, takeFlags)
                        result?.success(uri.toString())
                    } catch (_: Exception) {
                        result?.error("PERMISSION_ERROR", "Não foi possível manter acesso à pasta", null)
                    }
                } else {
                    result?.success(null)
                }
            } else {
                result?.success(null)
            }
            return
        }

        if (requestCode == requestCreateFile) {
            val result = pendingCreateFileResult
            pendingCreateFileResult = null
            pendingFileName = null

            if (resultCode == Activity.RESULT_OK) {
                result?.success(data?.data?.toString())
            } else {
                result?.success(null)
            }
            return
        }

        super.onActivityResult(requestCode, resultCode, data)
    }
}
