package com.xetawallet.xetafilemanager

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.media.ThumbnailUtils
import android.net.Uri
import android.os.CancellationSignal
import android.os.Environment
import android.os.storage.StorageManager
import android.provider.Settings
import android.util.Size
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.file.Files
import java.nio.file.attribute.BasicFileAttributes
import java.util.Locale
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "com.xeta.file_manager/storage"
    private val permissionRequest = 4282
    private val worker = Executors.newSingleThreadExecutor()
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "storageAccess" -> result.success(Environment.isExternalStorageManager())
                "openUrl" -> {
                    val uri = Uri.parse(call.argument<String>("url") ?: "")
                    if (uri.scheme != "https") {
                        result.error("INVALID_URL", "Only HTTPS links can be opened", null)
                    } else {
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, uri))
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("OPEN_URL_ERROR", error.message, null)
                        }
                    }
                }
                "requestStorageAccess" -> requestStorageAccess(result)
                "openStorageSettings" -> launchStorageSettings(result)
                "onboardingDone" -> result.success(prefs().getBoolean("onboarding_done", false))
                "darkMode" -> result.success(prefs().getBoolean("dark_mode", true))
                "setDarkMode" -> {
                    prefs().edit().putBoolean("dark_mode", call.argument<Boolean>("value") ?: true).apply()
                    result.success(true)
                }
                "finishOnboarding" -> {
                    prefs().edit().putBoolean("onboarding_done", true).apply()
                    result.success(true)
                }
                "volumes" -> onWorker(result) { volumes() }
                "removableWritable" -> result.success(prefs().getBoolean("removable_writable", false))
                "setRemovableWritable" -> {
                    prefs().edit().putBoolean("removable_writable", call.argument<Boolean>("value") ?: false).apply()
                    result.success(true)
                }
                "list" -> onWorker(result) { listDirectory(pathArg(call.argument<String>("path"))) }
                "scan" -> onWorker(result) { scan(pathArg(call.argument<String>("path"))) }
                "thumbnail" -> onWorker(result) { videoThumbnail(pathArg(call.argument<String>("path"))) }
                "open" -> result.success(openFile(pathArg(call.argument<String>("path"))))
                "rename" -> onWorker(result) {
                    val source = pathArg(call.argument<String>("source"))
                    val target = File(source.parentFile, safeName(call.argument<String>("name")))
                    requireNewTarget(target)
                    ensureCanWrite(source)
                    Files.move(source.toPath(), target.toPath())
                    target.absolutePath
                }
                "delete" -> onWorker(result) {
                    val target = pathArg(call.argument<String>("path"))
                    ensureCanWrite(target)
                    if (Files.isSymbolicLink(target.toPath())) Files.delete(target.toPath())
                    else if (target.isDirectory) target.deleteRecursively() else target.delete()
                    if (target.exists()) throw IllegalStateException("Could not delete ${target.name}")
                    true
                }
                "createFolder" -> onWorker(result) {
                    val parent = pathArg(call.argument<String>("parent"))
                    ensureCanWrite(parent)
                    val folder = File(parent, safeName(call.argument<String>("name")))
                    requireNewTarget(folder)
                    if (!folder.mkdir()) throw IllegalStateException("Could not create folder")
                    folder.absolutePath
                }
                "copy", "move" -> onWorker(result) {
                    val source = pathArg(call.argument<String>("source"))
                    val parent = pathArg(call.argument<String>("target"))
                    if (!source.exists()) throw IllegalStateException("The source file is no longer available")
                    if (call.method == "move") ensureCanWrite(source)
                    ensureCanWrite(parent)
                    val target = File(parent, source.name)
                    requireNewTarget(target)
                    copyRecursivelyWithoutOverwrite(source, target)
                    if (call.method == "move") {
                        if (source.isDirectory) source.deleteRecursively() else source.delete()
                        if (source.exists()) throw IllegalStateException("Copied, but could not remove the original")
                    }
                    true
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun prefs() = getSharedPreferences("xeta_file_manager", MODE_PRIVATE)

    private fun requestStorageAccess(result: MethodChannel.Result) {
        if (Environment.isExternalStorageManager()) {
            result.success(true)
            return
        }
        launchStorageSettings(result)
    }

    private fun launchStorageSettings(result: MethodChannel.Result) {
        if (permissionResult != null) {
            result.error("BUSY", "Storage settings are already open", null)
            return
        }
        permissionResult = result
        try {
            startActivityForResult(
                Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:$packageName")),
                permissionRequest,
            )
        } catch (error: Exception) {
            permissionResult = null
            result.error("SETTINGS_ERROR", error.message ?: "Could not open storage access settings", null)
        }
    }

    @Deprecated("Permission settings return through the activity result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == permissionRequest) {
            permissionResult?.success(Environment.isExternalStorageManager())
            permissionResult = null
        }
    }

    private fun <T> onWorker(result: MethodChannel.Result, task: () -> T) {
        worker.execute {
            try {
                val value = task()
                runOnUiThread { result.success(value) }
            } catch (error: Exception) {
                runOnUiThread { result.error("STORAGE_ERROR", error.message ?: "Storage operation failed", null) }
            }
        }
    }

    private fun volumes(): List<Map<String, Any?>> {
        val manager = getSystemService(STORAGE_SERVICE) as StorageManager
        val found = manager.storageVolumes.mapNotNull { volume ->
            val directory = volume.directory ?: return@mapNotNull null
            val description = volume.getDescription(this) ?: directory.name
            val label = description.lowercase(Locale.ROOT)
            val isSdCard = !volume.isPrimary && (label.contains("sd card") || label.contains("memory card") || label == "sd")
            val kind = when {
                volume.isPrimary -> "internal"
                isSdCard -> "sd"
                !volume.isPrimary && (label.contains("usb") || label.contains("otg") || usbStorageAttached()) -> "otg"
                !volume.isPrimary -> "sd"
                else -> "other"
            }
            mapOf(
                "name" to description,
                "path" to directory.absolutePath,
                "kind" to kind,
                "primary" to volume.isPrimary,
                "removable" to volume.isRemovable,
                "mounted" to (volume.state == Environment.MEDIA_MOUNTED && directory.exists() && directory.isDirectory),
            )
        }
        val internalPath = Environment.getExternalStorageDirectory().absolutePath
        if (found.none { it["kind"] == "internal" }) {
            return listOf(mapOf("name" to "Internal storage", "path" to internalPath, "kind" to "internal", "primary" to true, "removable" to false, "mounted" to File(internalPath).isDirectory)) + found
        }
        return found
    }

    private fun usbStorageAttached(): Boolean {
        val manager = getSystemService(USB_SERVICE) as android.hardware.usb.UsbManager
        return manager.deviceList.isNotEmpty()
    }

    private fun pathArg(value: String?): File {
        val path = value ?: throw IllegalArgumentException("Storage path is missing")
        val requested = File(path).absoluteFile
        if (Files.isSymbolicLink(requested.toPath())) throw SecurityException("Symbolic links are not opened")
        val file = requested.canonicalFile
        val roots = volumes().mapNotNull { it["path"] as? String }.map { File(it).canonicalFile }
        if (roots.none { file == it || file.toPath().startsWith(it.toPath()) }) {
            throw SecurityException("This path is outside connected storage")
        }
        if (!Environment.isExternalStorageManager()) throw SecurityException("Allow storage access in Settings to browse files")
        return file
    }

    private fun listDirectory(directory: File): List<Map<String, Any?>> {
        if (!directory.exists() || !directory.isDirectory) throw IllegalStateException("This storage is not connected")
        val files = directory.listFiles() ?: throw IllegalStateException("Could not read ${directory.name}")
        return files.filterNot { Files.isSymbolicLink(it.toPath()) }.map { item -> itemMap(item) }.sortedWith(
            compareBy<Map<String, Any?>> { it["directory"] != true }
                .thenBy { (it["name"] as String).lowercase(Locale.ROOT) },
        )
    }

    private fun itemMap(file: File): Map<String, Any?> {
        val extension = file.extension.lowercase(Locale.ROOT)
        val mime = android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: "application/octet-stream"
        return mapOf(
            "name" to file.name,
            "path" to file.absolutePath,
            "directory" to file.isDirectory,
            "mime" to mime,
            "size" to file.length(),
            "modified" to file.lastModified(),
            "created" to try {
                Files.readAttributes(file.toPath(), BasicFileAttributes::class.java).creationTime().toMillis()
            } catch (_: Exception) {
                0L
            },
        )
    }

    private fun scan(root: File): List<Map<String, Any?>> {
        if (!root.exists() || !root.isDirectory) throw IllegalStateException("This storage is not connected")
        val output = mutableListOf<Map<String, Any?>>()
        val queue = ArrayDeque<File>()
        val rootCanonical = root.canonicalFile.toPath()
        val visitedDirectories = mutableSetOf<String>()
        queue.add(root.canonicalFile)
        var visited = 0
        while (queue.isNotEmpty()) {
            val directory = queue.removeFirst()
            if (!visitedDirectories.add(directory.path)) continue
            val children = directory.listFiles() ?: continue
            for (child in children) {
                visited++
                if (visited > 100_000) throw IllegalStateException("This drive contains too many files to index")
                val canonical = child.canonicalFile
                if (!canonical.toPath().startsWith(rootCanonical)) continue
                if (Files.isSymbolicLink(child.toPath())) continue
                if (child.isDirectory) queue.add(canonical) else output.add(itemMap(child))
            }
        }
        return output.sortedBy { (it["name"] as String).lowercase(Locale.ROOT) }
    }

    private fun isUnderOtgStorage(file: File): Boolean {
        val canonical = file.canonicalFile
        return volumes().any { volume ->
            if (volume["kind"] != "otg") return@any false
            val root = File(volume["path"] as String).canonicalFile
            canonical == root || canonical.toPath().startsWith(root.toPath())
        }
    }

    private fun ensureCanWrite(file: File) {
        if (isUnderOtgStorage(file) && !prefs().getBoolean("removable_writable", false)) {
            throw SecurityException("OTG is read-only. Enable OTG writing in Settings to make changes.")
        }
    }

    private fun requireNewTarget(file: File) {
        if (file.exists()) throw IllegalStateException("A file or folder named '${file.name}' already exists. Nothing was overwritten.")
    }

    private fun safeName(value: String?): String {
        val name = value?.trim() ?: throw IllegalArgumentException("Name is required")
        if (name.isEmpty() || name == "." || name == ".." || name.contains('/') || name.contains('\\')) {
            throw IllegalArgumentException("Enter a valid name without a folder separator")
        }
        return name
    }

    private fun copyRecursivelyWithoutOverwrite(source: File, target: File) {
        if (Files.isSymbolicLink(source.toPath())) throw IllegalArgumentException("Symbolic links cannot be copied")
        if (source.isDirectory && target.canonicalFile.toPath().startsWith(source.canonicalFile.toPath())) {
            throw IllegalArgumentException("A folder cannot be copied inside itself")
        }
        requireNewTarget(target)
        if (source.isDirectory) {
            if (!target.mkdir()) throw IllegalStateException("Could not create ${target.name}")
            val children = source.listFiles() ?: throw IllegalStateException("Could not read ${source.name}")
            for (child in children) copyRecursivelyWithoutOverwrite(child, File(target, child.name))
        } else {
            Files.copy(source.toPath(), target.toPath())
        }
    }

    private fun videoThumbnail(file: File): ByteArray? {
        if (!file.exists() || !file.isFile) return null
        val bitmap = ThumbnailUtils.createVideoThumbnail(file, Size(240, 240), CancellationSignal()) ?: return null
        return ByteArrayOutputStream().use { output ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 78, output)
            bitmap.recycle()
            output.toByteArray()
        }
    }

    private fun openFile(file: File): Boolean {
        return try {
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val mime = android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension.lowercase(Locale.ROOT))
                ?: "application/octet-stream"
            val intent = Intent(Intent.ACTION_VIEW).setDataAndType(uri, mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
