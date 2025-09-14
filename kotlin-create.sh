#!/usr/bin/env bash
set -e

usage() {
    echo "Usage: $0 -n <app-name>"
    exit 1
}

# --- Parse args ---
while getopts "n:" opt; do
  case $opt in
    n) APP_NAME=$OPTARG ;;
    *) usage ;;
  esac
done

if [ -z "$APP_NAME" ]; then
    usage
fi

PACKAGE_NAME="com.example.${APP_NAME,,}"   # lowercase package
PROJECT_DIR="$APP_NAME"

echo "📦 Creating Kotlin Android project: $APP_NAME"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# --- settings.gradle.kts ---
cat > settings.gradle.kts <<EOF
rootProject.name = "$APP_NAME"
include(":app")
EOF

# --- Root build.gradle.kts ---
cat > build.gradle.kts <<EOF
plugins {
    id("com.android.application") version "8.1.2" apply false
    kotlin("android") version "1.9.20" apply false
}
EOF

# --- app/build.gradle.kts ---
mkdir -p app
cat > app/build.gradle.kts <<EOF
plugins {
    id("com.android.application")
    kotlin("android")
}

android {
    namespace = "$PACKAGE_NAME"
    compileSdk = 34

    defaultConfig {
        applicationId = "$PACKAGE_NAME"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
}
EOF

# --- AndroidManifest.xml ---
mkdir -p app/src/main
cat > app/src/main/AndroidManifest.xml <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE_NAME">

    <application
        android:label="@string/app_name"
        android:theme="@style/Theme.AppCompat.Light.DarkActionBar">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# --- MainActivity.kt ---
mkdir -p app/src/main/java/${PACKAGE_NAME//.//}
cat > app/src/main/java/${PACKAGE_NAME//.//}/MainActivity.kt <<EOF
package $PACKAGE_NAME

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import android.widget.Button
import android.widget.TextView

class MainActivity : AppCompatActivity() {
    private var counter = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val counterText = findViewById<TextView>(R.id.counterText)
        val incrementButton = findViewById<Button>(R.id.incrementButton)

        incrementButton.setOnClickListener {
            counter++
            counterText.text = counter.toString()
        }
    }
}
EOF

# --- Layout XML ---
mkdir -p app/src/main/res/layout
cat > app/src/main/res/layout/activity_main.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:id="@+id/counterText"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="0"
        android:textSize="32sp"
        android:layout_marginBottom="24dp" />

    <Button
        android:id="@+id/incrementButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Increment" />
</LinearLayout>
EOF

# --- Strings XML ---
mkdir -p app/src/main/res/values
cat > app/src/main/res/values/strings.xml <<EOF
<resources>
    <string name="app_name">$APP_NAME</string>
</resources>
EOF

# --- README.md ---
cat > README.md <<EOF
# $APP_NAME

A minimal Kotlin Android app created with \`kotlin-create\`.

This app displays a number and increments it each time you press the button.

---

## 🛠️ Build

```bash
./gradlew assembleDebug

