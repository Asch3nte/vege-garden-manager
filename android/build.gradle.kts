allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Raise the plugin modules to compileSdk 36 (file_picker / its lifecycle
// dependency require API 36+, above this Flutter version's default of 34). The
// app module sets 36 in its own build.gradle.kts; ":app" is skipped here because
// the evaluationDependsOn(":app") above already evaluated it (afterEvaluate then
// throws), and compileSdk must be set *during* evaluation (too late afterwards).
subprojects {
    if (name != "app") {
        afterEvaluate {
            (extensions.findByName("android") as? com.android.build.gradle.BaseExtension)
                ?.compileSdkVersion(36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
