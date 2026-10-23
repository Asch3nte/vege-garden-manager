import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release key, kept out of version control (android/key.properties).
val proprietesCle = Properties().apply {
    val fichier = rootProject.file("key.properties")
    if (fichier.exists()) fichier.inputStream().use { load(it) }
}
val cleReleaseDisponible = !proprietesCle.isEmpty
if (cleReleaseDisponible) {
    val manquantes = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .filter { proprietesCle.getProperty(it).isNullOrBlank() }
    if (manquantes.isNotEmpty()) {
        throw GradleException("android/key.properties: missing $manquantes")
    }
}

android {
    namespace = "com.potagerer.pot_a_gerer"
    // 36 (≥ Flutter's default 34): file_picker and its lifecycle dependency
    // require consumers to compile against API 36+. Plugin modules are raised
    // to 36 in the root build.gradle.kts; only compileSdk is bumped here.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (uses java.time APIs that need
        // to be desugared on older Android versions).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent once published: changing it makes a different app.
        applicationId = "com.potagerer.pot_a_gerer"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (cleReleaseDisponible) {
            create("release") {
                storeFile = file(
                    proprietesCle.getProperty("storeFile")
                        .replaceFirst(Regex("^~(?=/|$)"), System.getProperty("user.home")),
                )
                storePassword = proprietesCle.getProperty("storePassword")
                keyAlias = proprietesCle.getProperty("keyAlias")
                keyPassword = proprietesCle.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Without android/key.properties, a local release build falls back
            // to the debug key: such a build is never to be distributed.
            signingConfig = if (cleReleaseDisponible) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("android/key.properties absent: release signed with the debug key")
                signingConfigs.getByName("debug")
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

dependencies {
    // Backports java.time (etc.) for flutter_local_notifications on older Android.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
