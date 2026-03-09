// android/app/build.gradle
//
// Flutter generates this file automatically. The key settings to verify:
//   - minSdk 21+  (required by google_maps_flutter)
//   - compileSdk 34+
//   - multiDexEnabled true (needed when tree counts grow large)

plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.liberica.map"
    compileSdk 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    defaultConfig {
        applicationId "com.liberica.map"

        // google_maps_flutter requires minSdk 21
        minSdk 21
        targetSdk 34

        versionCode flutter.versionCode
        versionName flutter.versionName

        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug  // replace with release keystore for Play Store
            minifyEnabled false
            shrinkResources false
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    implementation 'androidx.multidex:multidex:2.0.1'
}