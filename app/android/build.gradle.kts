import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

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
    project.evaluationDependsOn(":app")

    fun ensureAndroidNamespace() {
        val androidExt = extensions.findByName("android") ?: return
        try {
            val getter = androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" && it.parameterCount == 0 }
            val current = getter?.invoke(androidExt) as? String

            if (current.isNullOrBlank()) {
                val setter = androidExt.javaClass.methods.firstOrNull { it.name == "setNamespace" && it.parameterCount == 1 }
                setter?.invoke(androidExt, project.group.toString())
            }
        } catch (_: Throwable) {
        }
    }

    plugins.withId("com.android.library") { ensureAndroidNamespace() }
    plugins.withId("com.android.application") { ensureAndroidNamespace() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}