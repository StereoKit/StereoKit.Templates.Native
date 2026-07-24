# StereoKit Template for CMake

This is a basic StereoKit template for C/C++ using [CMake](https://cmake.org/). It's straightforward and portable way to build native StereoKit apps on Linux, Windows, and Android! This template works quite well with VS Code, and following the prompts provided there can get you running pretty quickly. CMake can also be used to generate a Visual Studio solution, for those that prefer that workflow.

This template directly references and builds the StereoKit repository rather than using pre-built binaries, so this template could also be great for those that wish to fork and modify StereoKit's code!

## Project Structure

- `/src` - Your application code, including shaders.
- `/Assets` - Assets used by the app, textures, models, etc. Everything in here is bundled with the app on every platform.
- `/android` - The app's Android manifest, which declares the XR permissions and features headsets look for.
- `/bin` - Generated. The shader compiler builds itself here so Android builds can re-use it.

`CMakeLists.txt` is where you'll add source files, rename the app, and pick which version of StereoKit to build against.

## Command line instructions

For those new to CMake, here's a quick example of how to compile and build this using the CLI! If something is going wrong, sometimes adding in a `-v` for verbose will give you some additional info you might not see from VS Code.

```shell
# From the project root directory

# Configure the build
cmake -B build
# Build and run
cmake --build build -j8 --target run
```

The first configure downloads and builds StereoKit and its dependencies, so it takes a while! Later builds are much faster.

# Linux

Linux users will need to install some pre-requisites for this template to compile.

```shell
sudo apt-get update
sudo apt-get install cmake ninja-build libx11-dev libxrandr-dev libxcursor-dev libxfixes-dev libfontconfig-dev
```

Rendering goes through Vulkan, so you'll also need a Vulkan driver for your GPU at runtime. On a desktop install that's usually already there, but `mesa-vulkan-drivers` will cover most hardware if it isn't.

# Android

This template also supports building and running APKs for Android! Setup for this is more complicated, but no code changes are required to make this work: the same `main` function is the entry point on every platform, and StereoKit supplies the Android Activity and manifest for you.

## Android Setup

To build for Android, you need a few SDKs! [Android Studio](https://developer.android.com/studio) has a good interface for grabbing these, and doubles as a nice tool for inspecting APKs.

### Android SDKs
From [Android Studio](https://developer.android.com/studio), go to Tools->SDK Manager.
- Under SDK Platforms, add **API Level 32**
- Under SDK Tools, add **Android SDK Build-Tools**
- Under SDK Tools, add **NDK 25.2.9519653**
- Make note of the **Android SDK Location** at the top of this panel.

> The SDK Platform version must match the `MIN_SDK` in CMakeLists.txt, which is 32 by default. Other NDK versions may work as well, but StereoKit is officially built with 25.2.9519653.

From the Android SDK location you noted, you'll need to supply these variables as environment variables, or as configure parameters to CMake! This is how I would set these on Windows via Powershell.
```shell
# Your path may vary

[Environment]::SetEnvironmentVariable('ANDROID_HOME',     'C:\Users\[user]\AppData\Local\Android\Sdk', 'User')
[Environment]::SetEnvironmentVariable('ANDROID_NDK_HOME', 'C:\Users\[user]\AppData\Local\Android\Sdk\ndk\25.2.9519653', 'User')

# Or just launch the GUI
rundll32 sysdm.cpl,EditEnvironmentVariables
```

### Java SDK (JDK)
The JDK is installed alongside Android Studio, but may not be immediately accessible. In particular, packaging APKs requires `javac` and `keytool` from the JDK! These may be in PATH already, and if so, you're all set!
```
where javac
where keytool
```
But, if neither of these produces a result, you'll have to find the JDK's install directory! Mine was next to Android Studio. You can either add the JDK bin folder to path, or just set JDK's root folder to the JAVA_HOME variable that this template looks for.
```shell
# Your path may vary

# If you don't want to add to PATH
[Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Android\jdk\jdk-8.0.302.8-hotspot\jdk8u302-b08', 'User')

# Or add to path. It's always safest to add via GUI, but here's some powershell
# that'll do fine. Note that this is JDK\bin, and not JDK's root.
[Environment]::SetEnvironmentVariable('PATH', [System.Environment]::GetEnvironmentVariable('PATH', 'User') + ';' + 'C:\Program Files\Android\jdk\jdk-8.0.302.8-hotspot\jdk8u302-b08\bin', 'User')

# Or just launch the GUI
rundll32 sysdm.cpl,EditEnvironmentVariables
```

### Ninja
This is a commonly used build tool that makes builds faster! In theory it's optional, but you may need to do some troubleshooting without it.
Ninja's [site is here](https://ninja-build.org/), but you can install it quite easily via CLI:
- Windows: `winget install Ninja-build.Ninja`
- Linux (Ubuntu): `apt-get install ninja-build`

## Android Build

> Shaders are compiled by a tool that only runs on your desktop, and Android builds re-use the copy in `/bin`. **Do a desktop build first!**

```shell
# From the project root directory

# Configure the build, I'll often make a .bat file for this configure command
# just to make it easier to do!
cmake -B build-android ^
  -G Ninja ^
  -DCMAKE_TOOLCHAIN_FILE=%ANDROID_NDK_HOME%/build/cmake/android.toolchain.cmake ^
  -DANDROID_ABI=arm64-v8a ^
  -DANDROID_PLATFORM=android-32
# Same, but as a single line. Nicer if not using a .bat
cmake -B build-android -G Ninja -DCMAKE_TOOLCHAIN_FILE=%ANDROID_NDK_HOME%/build/cmake/android.toolchain.cmake -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-32
# Build an APK, install it, and run it
cmake --build build-android -j8 --target run
# Or just build the APK
cmake --build build-android -j8
```

The APK lands at `build-android/[YourProject].apk`.

## Android Icon and Manifest

The app's manifest is at `/android/AndroidManifest.xml`, which `add_skapp`'s `MANIFEST` argument points at. It declares the intent categories, permissions, and feature flags that headsets look for, so your app is treated as an immersive XR app. The manifest is commented, and the `@VARIABLES@` in it are filled in by CMake from your `add_skapp` arguments.

The app icon and theme come from StereoKit, so there's nothing to set up there. If you want your own, `add_skapp` also takes a `RESOURCES` argument. StereoKit's copy is a good starting point, and can be found at `build-android/_deps/sk_app-src/android/resources/` after a configure.

## Custom OpenXR Loader

If you need to use a custom OpenXR Loader for a non-conformant runtime such as Snapdragon Spaces, you can specify it with the `OPENXR_CUSTOM_LOADER` variable! See the CMakeLists.txt file for a commented out example. Note that you may need to do a _full_ clean and rebuild if you're switching between the standard and a custom loader. It may be better to have a different build folder per-loader.
