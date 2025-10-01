plugins {
    // Alinhado com a versão declarada em settings.gradle.kts (4.3.15)
    id("com.google.gms.google-services") version "4.3.15" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

/* 
// Custom build directory logic removed to avoid breaking Gradle's internal tasks.
// If you need to change the build directory, do so with caution and test thoroughly.
*/
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
