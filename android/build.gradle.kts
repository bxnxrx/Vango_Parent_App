buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 1. Android Gradle Plugin (Required)
        classpath("com.android.tools.build:gradle:8.2.1") 

        // 2. Kotlin Gradle Plugin (Required)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0") 

        // 3. Google Services Plugin
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
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

    if (project.name != "app") {
        afterEvaluate {
            // Force the underlying Android Library options to Java 17
            if (project.plugins.hasPlugin("com.android.library")) {
                val androidExt = project.extensions.getByName("android") as com.android.build.gradle.LibraryExtension
                androidExt.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                androidExt.compileOptions.targetCompatibility = JavaVersion.VERSION_17
            }
            
            tasks.withType<JavaCompile>().configureEach {
                sourceCompatibility = "17"
                targetCompatibility = "17"
            }
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "17"
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}