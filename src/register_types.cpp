#include "register_types.h"

#include <gdextension_interface.h>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include "Log.h"

using namespace godot;

void initialize_log_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SERVERS) {
		return;
	}
	GDREGISTER_CLASS(LogStream);
	/*
	GDREGISTER_CLASS(ExampleRef);
	GDREGISTER_CLASS(ExampleMin);
	GDREGISTER_CLASS(Example);
	GDREGISTER_VIRTUAL_CLASS(ExampleVirtual);
	GDREGISTER_ABSTRACT_CLASS(ExampleAbstractBase);
	GDREGISTER_CLASS(ExampleConcrete);
	GDREGISTER_CLASS(ExampleBase);
	GDREGISTER_CLASS(ExampleChild);
	GDREGISTER_RUNTIME_CLASS(ExampleRuntime);
	GDREGISTER_CLASS(ExamplePrzykład);
 	*/
	
}

void uninitialize_log_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SERVERS) {
		return;
	}
}

extern "C" {
// Initialization.
GDExtensionBool GDE_EXPORT log_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(initialize_log_module);
	init_obj.register_terminator(uninitialize_log_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}
