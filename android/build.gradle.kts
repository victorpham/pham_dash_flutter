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

// Plugin modules inherit compileSdk from the Flutter Gradle plugin, which
// resolves to 37. This SDK installs that platform as "android-37.0" while
// Gradle looks for "android-37", so the build fails to resolve it. Force every
// Android subproject onto 36, the same installed platform the app uses.
//
// Must be registered before the evaluationDependsOn(":app") block below, which
// eagerly evaluates subprojects and would leave this afterEvaluate too late.
subprojects {
    afterEvaluate {
        when (val android = extensions.findByName("android")) {
            is com.android.build.gradle.LibraryExtension -> android.compileSdk = 36
            is com.android.build.gradle.AppExtension -> android.compileSdkVersion(36)
            else -> {}
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
