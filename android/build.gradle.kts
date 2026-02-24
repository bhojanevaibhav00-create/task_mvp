plugins {
    // Android Gradle Plugin
    id("com.android.application") version "8.7.3" apply false
    
    // Kotlin Android Plugin
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    
    // 🔥 FIXED: Google Services Plugin (Firebase)
    // Use ONLY 4.3.15 to avoid version conflict
    id("com.google.gms.google-services") version "4.3.15" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory setup (keep as-is)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
