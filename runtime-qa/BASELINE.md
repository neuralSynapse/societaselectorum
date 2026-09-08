# CHRONICA HARUN · Runtime QA Baseline

- Godot: `4.3.stable.official.77dcf97d8`
- pytest exit: `1`
- import exit: `0`
- boot exit: `0`

## Import errors
```text
SCRIPT ERROR: Parse Error: Cannot infer the type of "d" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "index" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "payload" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "kind" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "total" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "completed" variable because the value doesn't have a set type.
SCRIPT ERROR: Compile Error: 
SCRIPT ERROR: Compile Error: 
ERROR: Failed to load script "res://scripts/boot/Main.gd" with error "Parse error".
SCRIPT ERROR: Parse Error: Cannot infer the type of "host_id" variable because the value doesn't have a set type.
ERROR: Failed to load script "res://scripts/generation/StageFloorBuilder.gd" with error "Parse error".
SCRIPT ERROR: Parse Error: Cannot infer the type of "d" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "index" variable because the value doesn't have a set type.
SCRIPT ERROR: Compile Error: 
SCRIPT ERROR: Compile Error: 
ERROR: Failed to load script "res://scripts/narrative/NarrativePresentationController.gd" with error "Parse error".
```

## Boot errors
```text
SCRIPT ERROR: Parse Error: Cannot infer the type of "d" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "index" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "payload" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "kind" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "total" variable because the value doesn't have a set type.
SCRIPT ERROR: Parse Error: Cannot infer the type of "completed" variable because the value doesn't have a set type.
SCRIPT ERROR: Compile Error: 
SCRIPT ERROR: Compile Error: 
ERROR: Failed to load script "res://scripts/boot/Main.gd" with error "Compilation failed".
SCRIPT ERROR: Trying to assign value of type 'Node' to a variable of type 'TemporalRiftDirector.gd'.
SCRIPT ERROR: Trying to assign value of type 'Node' to a variable of type 'StageDirector.gd'.
SCRIPT ERROR: Invalid access to property or key 'stage_completed' on a base object of type 'Nil'.
```

## pytest tail
```text
.........................F.............................................. [ 82%]
...............                                                          [100%]
=================================== FAILURES ===================================
________ test_every_enemy_and_boss_has_unique_nonempty_glb_and_manifest ________

    def test_every_enemy_and_boss_has_unique_nonempty_glb_and_manifest():
        enemies = load('data/enemies/student_enemies.json')
        bosses = load('data/bosses/student_bosses.json')
>       enemy_manifest = load('art/generated/enemies/manifest.json')
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

tests/test_generated_models.py:18: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
tests/test_generated_models.py:8: in load
    return json.loads((ROOT / rel).read_text())
                      ^^^^^^^^^^^^^^^^^^^^^^^^
/opt/hostedtoolcache/Python/3.12.14/x64/lib/python3.12/pathlib.py:1027: in read_text
    with self.open(mode='r', encoding=encoding, errors=errors) as f:
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

self = PosixPath('/home/runner/work/societaselectorum/societaselectorum/game/chronica-harun/art/generated/enemies/manifest.json')
mode = 'r', buffering = -1, encoding = 'locale', errors = None, newline = None

    def open(self, mode='r', buffering=-1, encoding=None,
             errors=None, newline=None):
        """
        Open the file pointed to by this path and return a file object, as
        the built-in open() function does.
        """
        if "b" not in mode:
            encoding = io.text_encoding(encoding)
>       return io.open(self, mode, buffering, encoding, errors, newline)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
E       FileNotFoundError: [Errno 2] No such file or directory: '/home/runner/work/societaselectorum/societaselectorum/game/chronica-harun/art/generated/enemies/manifest.json'

/opt/hostedtoolcache/Python/3.12.14/x64/lib/python3.12/pathlib.py:1013: FileNotFoundError
=========================== short test summary info ============================
FAILED tests/test_generated_models.py::test_every_enemy_and_boss_has_unique_nonempty_glb_and_manifest - FileNotFoundError: [Errno 2] No such file or directory: '/home/runner/work/societaselectorum/societaselectorum/game/chronica-harun/art/generated/enemies/manifest.json'
1 failed, 86 passed in 0.32s

```