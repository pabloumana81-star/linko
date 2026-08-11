import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningFile = rootProject.file("key.properties")
val releaseSigning = Properties()
if (releaseSigningFile.exists()) {
    FileInputStream(releaseSigningFile).use(releaseSigning::load)
}

fun requiredSigningValue(name: String): String =
    releaseSigning.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("La configuración local de firma Android está incompleta.")

android {
    namespace = "com.linko.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Final production identity shared with the Apple runners.
        applicationId = "com.linko.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningFile.exists()) {
            create("release") {
                keyAlias = requiredSigningValue("keyAlias")
                keyPassword = requiredSigningValue("keyPassword")
                storeFile = file(requiredSigningValue("storeFile"))
                storePassword = requiredSigningValue("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // CI may validate an unsigned artifact. Distribution builds are signed
            // only when the untracked android/key.properties is present.
            if (releaseSigningFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
