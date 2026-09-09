# CHRONICA real playability gate · latest diagnostic

- head: 31ff28321059fb5ce5b7f69cd80b22daddd41e81
- workflow run: 34297192416
- runtime exit code: 124

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

SCRIPT ERROR: Compile Error: Identifier not found: GameState
          at: GDScript::reload (res://scripts/player/PlayerController.gd:144)
SCRIPT ERROR: Compile Error: 
          at: GDScript::reload (res://scripts/generation/RoomShell.gd:-1)
ERROR: Failed to load script "res://scripts/generation/RoomShell.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript.cpp:2936)
SCRIPT ERROR: Compile Error: Identifier not found: ContentRegistry
          at: GDScript::reload (res://scripts/generation/SpecialRoomDirector.gd:10)
SCRIPT ERROR: Compile Error: 
          at: GDScript::reload (res://scripts/generation/StageFloorBuilder.gd:-1)
SCRIPT ERROR: Compile Error: Identifier not found: GameState
          at: GDScript::reload (res://scripts/player/PlayerController.gd:144)
SCRIPT ERROR: Compile Error: 
          at: GDScript::reload (res://tests/runtime_playability_gate.gd:-1)
ERROR: Failed to load script "res://tests/runtime_playability_gate.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript.cpp:2936)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
          at: build (res://scripts/generation/StageFloorBuilder.gd:50)
ERROR: Parameter "p_child" is null.
   at: add_child (scene/main/node.cpp:1566)
SCRIPT ERROR: Cannot call method 'get_node_or_null' on a null value.
          at: _run_gate (res://tests/runtime_playability_gate.gd:25)
```
