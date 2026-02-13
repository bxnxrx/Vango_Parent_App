buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 1. Android Gradle Plugin (Required)
        // If your build fails, try changing "8.2.1" to "7.6.3" or check your original file.
        classpath("com.android.tools.build:gradle:8.2.1") 

        // 2. Kotlin Gradle Plugin (Required)
        // If your build fails, try "1.7.10" or "1.8.20".
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0") 

        // 3. Google Services Plugin (Your addition)
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}