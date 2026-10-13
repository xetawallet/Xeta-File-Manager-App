# Xeta File Manager

Flutter Android application, version 1.0.0 (Android version code 8).

## How the app works

- `lib/main.dart` contains the Flutter screens, navigation, storage models, file browsing, search, sorting, previews, and user initiated file actions.
- `android/app/src/main/kotlin/com/xeta/xeta_file_manager/MainActivity.kt` implements the Android method channel. It reads storage volume metadata, lists files, creates video thumbnails, opens files, and performs the requested file operations on a worker thread.
- Flutter and Android communicate through the `com.xeta.file_manager/storage` method channel. App preferences are stored locally with Android `SharedPreferences`.
- There is no account service, analytics SDK, advertising SDK, or network client in the app. Storage paths and browsing activity stay on device. The source link shown in Settings points to the planned public repository.
- The Android manifest requests `MANAGE_EXTERNAL_STORAGE` for the file manager's core function. OTG write operations have a separate opt in setting. File transfers refuse to replace an existing destination, and no drive formatting operation exists.

Most screens and browser behavior are in `lib/main.dart`; the reusable crypto donation screen and QR rendering are isolated in `lib/crypto_donation_page.dart` using the open source `qr_flutter` package. Native behavior is kept in the Android activity and exposed as named method channel operations. Public donation addresses are also listed in `assets/donation_wallets.json` and encoded into matching network QR codes.

The adaptive launcher foreground and raster density assets keep the complete folder mark inside Android's central icon safe area. From the project root, regenerate the master and Android density PNGs with `python3 tool/generate_app_icon.py`; regenerate the website, feature graphic, and tablet screenshot sizes with `python3 tool/generate_playstore_package.py`.

Storage access uses Android's `MANAGE_EXTERNAL_STORAGE` special app access. OTG writes are separately gated by the app's read-only-by-default setting. Existing target files are never replaced, and there is no drive-formatting feature.
