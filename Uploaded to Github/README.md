# Xeta File Manager v1.0.0

This app was built using the [Xeta App Boilerplate](https://github.com/xetawallet/Xeta-App-Boilerplate).

Android file manager with path browsing and two-stage file type browsing, list/grid layouts, photo previews, video thumbnails, sorting, file properties, selection, rename, delete, copy, and move. Onboarding can be completed without storage access; grant it later from Settings to browse files. Dark mode is the default and can be changed in Settings. OTG starts read-only; writing is opt-in in Settings. Writes refuse name collisions, and the app has no format operation.

## Build a test APK

```sh
python3 tool/build_apk.py test
```

This creates the debug-signed ARM64 artifact at `APK's (Test,Uploaded and To be Uploaded)/Test/xeta-file-manager-test-v1.0.0.apk`.

## App and Play Store assets

Run `python3 tool/generate_app_icon.py` to create the 512 px icon master and Android launcher density images. Run `python3 tool/generate_playstore_package.py` to generate the privacy website, feature graphics, and 7-inch and 10-inch tablet screenshots from the current File Manager screenshots.

## Production signing

The production command requires the owner's Play upload key. Configure `App Code/android/key.properties` and the private keystore there, then run `python3 tool/build_apk.py production`. Keep both signing files private. Play submission of all-files access requires the file-management core-function declaration and Play review.

Feel free to submit a Merge Request if any features are needed.
