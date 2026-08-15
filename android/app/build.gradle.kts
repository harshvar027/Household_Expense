import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val admobPropertiesFile = rootProject.file("admob.properties")
val admobProperties = Properties()
if (admobPropertiesFile.exists()) {
    admobProperties.load(FileInputStream(admobPropertiesFile))
}
val admobAppId = admobProperties.getProperty(
    "appId",
    "ca-app-pub-3940256099942544~3347511713",
)
val admobTestAppId = "ca-app-pub-3940256099942544~3347511713"

android {
    namespace = "com.householdexpense.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.householdexpense.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = admobAppId
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            isDebuggable = true
        }
        release {
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles("proguard-rules.pro")
            // Only configure release signing when keystore exists.
            // Keystore check runs in whenReady so debug builds are not blocked.
            if (hasReleaseKeystore) {
                if (admobAppId == admobTestAppId) {
                    logger.warn(
                        "WARNING: AdMob is using Google's TEST app ID. " +
                            "Create android/admob.properties with your production appId before Play upload.",
                    )
                }
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Fail only when a release task is actually requested (not during debug configure).
gradle.taskGraph.whenReady {
    val isReleaseTask = allTasks.any { it.name.contains("Release", ignoreCase = true) }
    if (isReleaseTask && !hasReleaseKeystore) {
        throw GradleException(
            "Release build requires android/key.properties and upload keystore. " +
                "Run: .\\scripts\\android-release-setup.ps1",
        )
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

dependencies {
    implementation("androidx.activity:activity-ktx:1.10.1")
}
