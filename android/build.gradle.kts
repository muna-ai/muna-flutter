plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "ai.muna.muna"
version = "1.0"

android {
    namespace = "ai.muna.muna"
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        minSdk = 24
    }
}
