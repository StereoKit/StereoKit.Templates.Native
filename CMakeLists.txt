#[[ Quick usage guide!

- Update project() with the name of your app!
- Update add_skapp() with your own PACKAGE_NAME and APP_NAME!
- Add your code to `target_sources` further down this file!

See the readme for more extensive build instructions.

########################
# For Windows or Linux #
########################

# Configure the build
cmake -B build
# Build and run
cmake --build build -j8 --target run

########################
# For Android          #
########################

# Shaders are compiled by a tool that only runs on your desktop, so do a
# desktop build at least once before building for Android!

# Configure the build, I'll often make a .bat file for this configure command
# just to make it easier to do!
cmake -B build-android ^
  -G Ninja ^
  -DCMAKE_TOOLCHAIN_FILE=%ANDROID_NDK_HOME%/build/cmake/android.toolchain.cmake ^
  -DANDROID_ABI=arm64-v8a ^
  -DANDROID_PLATFORM=android-32
# Build an APK, install it, and run it
cmake --build build-android -j8 --target run
# Or just build the APK
cmake --build build-android -j8
]]

#######################################
## Project                           ##
#######################################

# 3.21 for TARGET_RUNTIME_DLLS, which we use to find StereoKit's .dll
cmake_minimum_required(VERSION 3.21)
project(SKNativeTemplate VERSION "0.1.0" LANGUAGES CXX C)

# If you need a custom OpenXR loader for a non-conformant runtime such as
# Snapdragon Spaces, uncomment this and point it at the loader you want!
#set(OPENXR_CUSTOM_LOADER "${CMAKE_CURRENT_SOURCE_DIR}/loader/snapdragon/libopenxr_loader.so")

#######################################
## StereoKit                         ##
#######################################

include(FetchContent)

# APKs get signed with a debug key. Keeping it here, rather than in the build
# folder, means a clean rebuild won't change the signature, which would make
# devices refuse to update an already installed app.
set(KEYSTORE "${CMAKE_CURRENT_SOURCE_DIR}/debug.keystore" CACHE STRING "Path to the keystore")

set(SK_BUILD_TESTS       OFF CACHE INTERNAL "") # We just want the library.
set(SK_BUILD_SHARED_LIBS ON  CACHE INTERNAL "") # Shared libraries build faster!
set(SK_USE_SVSL          ON  CACHE INTERNAL "") # Compile shaders with SVSL, it drops glslang from the build.
if (ANDROID AND DEFINED OPENXR_CUSTOM_LOADER)
	set(SK_DYNAMIC_OPENXR ON CACHE INTERNAL "") # Don't bake in the OpenXR loader.
endif()

# Grab and build StereoKit from the GitHub repository. StereoKit brings its own
# dependencies along, including the sk_app and skshaderc CMake helpers used
# further down this file.
FetchContent_Declare(
	StereoKitC
	GIT_REPOSITORY https://github.com/StereoKit/StereoKit.git
	GIT_TAG        develop # Branch name, could also be a tag like "v0.3.11", or a git hash.
	GIT_SHALLOW    1)
FetchContent_MakeAvailable(StereoKitC)

# StereoKit's warnings aren't our problem, quiet them down.
target_compile_options(StereoKitC PRIVATE
	$<$<CXX_COMPILER_ID:GNU,Clang>:-w -Wno-dev>
	$<$<CXX_COMPILER_ID:MSVC>:/W0>)

#######################################
## App                               ##
#######################################

# add_skapp comes from StereoKit's sk_app dependency! It creates an executable
# on desktop, and a shared library plus an APK on Android. The Android-only
# arguments are ignored on desktop.
add_skapp(${PROJECT_NAME}
	PACKAGE_NAME com.example.sknativetemplate # Android app id, make this yours!
	APP_NAME     "SK Native Template"         # Name shown on the device
	MIN_SDK      32                           # Needs a matching SDK Platform installed
	TARGET_SDK   33
	# Declares the XR permissions and features headsets look for, see the file!
	MANIFEST     android/AndroidManifest.xml)

target_link_libraries(${PROJECT_NAME} PRIVATE StereoKitC)

# Add source files to the app!
target_sources(${PROJECT_NAME} PRIVATE
	src/main.cpp
)

# Hide shader compile metadata unless we're in verbose mode.
set(SHADER_VERBOSITY "-si")
if (CMAKE_VERBOSE_MAKEFILE)
	set(SHADER_VERBOSITY "")
endif()

# Compile shaders into .h files that the app can #include. Parameter docs for
# the shader compiler are here:
# https://github.com/StereoKit/sk_renderer/blob/main/skshaderc/main.cpp
skshaderc_compile_headers(${PROJECT_NAME}
	${CMAKE_BINARY_DIR}/generated/shaders
	"-e -O3 ${SHADER_VERBOSITY} -i ${stereokitc_SOURCE_DIR}/tools/include"
	src/shaders/floor.hlsl
)

# Everything in Assets/ gets bundled with the app: copied next to the
# executable on desktop, and packed into the APK on Android.
target_skapp_assets(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/Assets)

# If a custom OpenXR loader was specified above, link it in as a shared library
# so it gets packed into the APK alongside StereoKit.
if (ANDROID AND DEFINED OPENXR_CUSTOM_LOADER)
	add_library          (custom_openxr_loader SHARED IMPORTED)
	set_target_properties(custom_openxr_loader PROPERTIES IMPORTED_LOCATION ${OPENXR_CUSTOM_LOADER})
	target_link_libraries(${PROJECT_NAME} PRIVATE custom_openxr_loader)
endif()

#######################################
## Build and run with one command    ##
#######################################

# A `run` target so both platforms build and launch the same way. Handy from
# the CLI, but not necessary for VS Code.
if (ANDROID)
	# add_skapp already made a target that installs the APK and starts it.
	add_custom_target(run)
	add_dependencies (run ${PROJECT_NAME}-run)
else()
	# Windows needs StereoKit's .dll sitting next to the .exe to run it. The
	# $<IF:...> keeps this working if SK_BUILD_SHARED_LIBS is switched off,
	# which leaves TARGET_RUNTIME_DLLS empty and would error the copy command.
	if (WIN32)
		add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E
				$<IF:$<BOOL:$<TARGET_RUNTIME_DLLS:${PROJECT_NAME}>>,copy_if_different,true>
				$<$<BOOL:$<TARGET_RUNTIME_DLLS:${PROJECT_NAME}>>:$<TARGET_RUNTIME_DLLS:${PROJECT_NAME}>>
				$<$<BOOL:$<TARGET_RUNTIME_DLLS:${PROJECT_NAME}>>:$<TARGET_FILE_DIR:${PROJECT_NAME}>>
			COMMAND_EXPAND_LISTS)
	endif()

	# macOS gets Vulkan via MoltenVK, which also needs to sit next to the
	# executable. This one is a no-op on other platforms.
	skr_copy_moltenvk(${PROJECT_NAME})

	add_custom_target(run
		COMMAND           $<TARGET_FILE:${PROJECT_NAME}>
		WORKING_DIRECTORY $<TARGET_FILE_DIR:${PROJECT_NAME}>
		USES_TERMINAL)
	# -package is add_skapp's target for syncing Assets to the output folder.
	add_dependencies(run ${PROJECT_NAME}-package)
endif()
