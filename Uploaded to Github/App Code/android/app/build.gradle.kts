import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    implementation("androidx.core:core-ktx:1.16.0")
}

android {
    namespace = "com.xetawallet.xetafilemanager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.xetawallet.xetafilemanager"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 30
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val keys = Properties().apply {
                val file = rootProject.file("key.properties")
                if (file.exists()) file.inputStream().use { load(it) }
            }
            if (keys.containsKey("storeFile")) {
                require(listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all(keys::containsKey)) {
                    "android/key.properties must define storeFile, storePassword, keyAlias, and keyPassword"
                }
                signingConfigs.create("production") {
                    storeFile = rootProject.file(keys.getProperty("storeFile"))
                    storePassword = keys.getProperty("storePassword")
                    keyAlias = keys.getProperty("keyAlias")
                    keyPassword = keys.getProperty("keyPassword")
                }
                signingConfig = signingConfigs.getByName("production")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
