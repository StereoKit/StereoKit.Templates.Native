// A StereoKit app! The API reference and guides live at https://stereokit.net.
// Those docs are written against StereoKit's C# API, so expect to do a little
// translation while reading them. The names map over fairly mechanically, for
// example Model.FromFile is model_create_file.
//
// For C++ specifically, StereoKitCTest is a much larger reference project with
// demos for most of StereoKit's features:
// https://github.com/StereoKit/StereoKit/tree/master/Examples/StereoKitCTest

#include <stereokit.h>
#include <stereokit_ui.h>

// Generated at build time from src/shaders/floor.hlsl, see CMakeLists.txt.
#include "floor.hlsl.h"

using namespace sk;

// Variables used by the app.
material_t floor_mat;
mesh_t     floor_mesh;

model_t    model;
pose_t     model_pose = {{0,0,-0.5f}, quat_identity};

// This is the entry point on every platform, Android included!
int main(int argc, char** argv) {

	// Initialize StereoKit.
	sk_settings_t settings = {"SKNativeTemplate"};
	if (!sk_init(settings))
		return 1;

	// Initialize assets.
	shader_t floor_shader = shader_create_mem((void*)sks_floor_hlsl, sizeof(sks_floor_hlsl));
	floor_mesh = mesh_find      (default_id_mesh_cube);
	floor_mat  = material_create(floor_shader);
	material_set_transparency(floor_mat, transparency_blend);
	shader_release(floor_shader);

	// Files in the Assets folder are bundled with the app on every platform.
	model = model_create_file("Watermelon.glb");

	// Main app loop.
	sk_run([](){ // Step
		if (device_display_get_blend() == display_blend_opaque) {
			mesh_draw(floor_mesh, floor_mat, matrix_ts({0,-1.5f,0}, {30,0.1f,30}));
		}

		ui_handle_begin("Cube", model_pose, nullptr, model_get_bounds(model), false);
		render_add_model(model, matrix_identity);
		ui_handle_end();
	}, [](){ // Shutdown
		mesh_release    (floor_mesh);
		material_release(floor_mat);
		model_release   (model);
	});

	// Return based on why StereoKit quit.
	return sk_get_quit_reason() == quit_reason_user ? 0 : 1;
}
