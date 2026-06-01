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

// Patch: fix legacy Android libraries (e.g. isar_flutter_libs 3.1.0+1) that:
//   1. Don't declare 'namespace' (required by AGP 8+)
//   2. Use compileSdk < 33 (required by modern AndroidX deps)
// We skip ":app" because it is already evaluated via evaluationDependsOn above.
subprojects {
    if (path != ":app") {
        afterEvaluate {
            extensions
                .findByType(com.android.build.gradle.LibraryExtension::class.java)
                ?.apply {
                    if (namespace == null) {
                        namespace = group.toString().ifEmpty { "dev.isar.${name}" }
                    }
                    if ((compileSdk ?: 0) < 35) {
                        compileSdk = 35
                    }
                }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
