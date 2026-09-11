import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def load(path: str):
    return json.loads(read(path))


def test_initiatic_path_has_actus_ingressus_student_and_33_degrees():
    data = load("data/progression/initiatic_path.json")
    assert data["pre_student"]["id"] == "actus_ingressus"
    assert data["pre_student"]["is_degree"] is False
    assert [row["id"] for row in data["pre_student"]["scrolls"]] == ["o_olho", "a_chama", "a_obra_fundacao"]
    assert len(data["student"]["scrolls"]) == 12
    assert data["student"]["is_degree"] is False
    assert len(data["degrees"]) == 33
    assert [row["degree"] for row in data["degrees"]] == list(range(1, 34))
    assert data["degrees"][0]["title"] == "INCEPTIO"
    assert data["degrees"][0]["initiatic_title"] == "PEREGRINUS IGNIS"
    assert data["degrees"][22]["tree"] == "ARBOR_DRACONIS"
    assert data["degrees"][22]["hidden_until_degree"] == 22


def test_33_scroll_corpus_is_distributed_without_inventing_a_scroll_per_degree():
    data = load("data/progression/initiatic_path.json")
    scrolls = data["scroll_corpus"]
    assert len(scrolls) == 33
    assert [row["number"] for row in scrolls] == list(range(1, 34))
    assert [row["phase"] for row in scrolls[:3]] == ["ACTUS_INGRESSUS"] * 3
    assert [row["phase"] for row in scrolls[3:15]] == ["STUDENT"] * 12
    advanced = scrolls[15:]
    assert len(advanced) == 18
    assert all(row["phase"] == "DEGREE" for row in advanced)
    assert len({row["degree_unlock"] for row in advanced}) == 18
    assert max(row["degree_unlock"] for row in advanced) == 33


def test_draconis_is_programmatically_hidden_until_mortis_completion():
    service = read("scripts/progression/InitiaticProgressionService.gd")
    assert "hidden_until_degree" in service
    assert "degree_completed >= hidden_until_degree" in service or "degree_completed >= int(row.get(\"hidden_until_degree\"" in service
    assert "ARBOR_DRACONIS" in service


def test_content_registry_exposes_initiatic_path_and_existing_roguelite_catalogs():
    registry = read("autoload/ContentRegistry.gd")
    assert '"initiatic_path"' in registry
    for category in ["tarot", "pharmaka", "special_rooms", "relics", "instrumenta", "talismans", "sigilla", "daimones", "powers", "transformations"]:
        assert f'"{category}"' in registry
    assert len(load("data/roguelite/tarot_thoth.json")) >= 72
    assert len(load("data/roguelite/pharmaka.json")) >= 1
    room_ids = {row["id"] for row in load("data/roguelite/special_rooms.json")}
    assert "arcana" in room_ids
    assert "laboratorium" in room_ids


def test_narrative_choice_ui_uses_structured_rows_and_no_fixed_54px_long_option_contract():
    hud = read("scripts/ui/HUDController.gd")
    narrative = read("scripts/narrative/NarrativeChoiceDirector.gd")
    assert "immediate_cost" in narrative
    assert "story_consequence" in narrative
    assert "_build_choice_row" in hud
    assert "ChoiceModalDimmer" in hud or "choice_modal_dimmer" in hud
    choice_block = hud[hud.index("func show_choice"):]
    assert "custom_minimum_size = Vector2(0, 54)" not in choice_block[:2500]
    assert "InputEventKey" in hud or "KEY_1" in hud


def test_pause_menu_is_a_real_navigation_surface():
    hud = read("scripts/ui/HUDController.gd")
    scene = read("scenes/ui/HUD.tscn")
    for label in ["RETOMAR", "JORNADA", "BUILD", "TAROT", "CODEX", "PERSONAGENS", "CONTROLES", "CONFIGURAÇÕES", "REINICIAR RUN", "VOLTAR AO TÍTULO"]:
        assert label in hud or label in scene
    assert "pause_action_requested" in hud


def test_roster_and_runtime_encounters_are_connected():
    roster = load("data/characters/playable_roster.json")
    assert len(roster) >= 12
    names = {row["name"] for row in roster}
    for expected in ["Frater Harun", "Caim", "Lilith", "Nadir", "Seth", "Sabaoth · Ruptura", "Aspecto de Sophia", "Aspecto de Thoth", "Aspecto de Hórus", "Aspecto de Belial"]:
        assert expected in names
    runtime = read("scripts/narrative/CharacterEncounterDirector.gd")
    assert "playable_roster.json" in runtime or 'ContentRegistry.all("characters")' in runtime
    assert "encounter" in runtime.lower()


def test_special_rooms_secret_rooms_and_pharmaka_remain_live_in_stage_runtime():
    stage = read("scripts/progression/StageDirector.gd")
    for token in ["special_rooms", "secret", "super_secret", "pharmaka", "tarot", "instrumenta", "relics"]:
        assert token in stage
    assert "known_pharmaka" in read("autoload/RogueliteContentService.gd")


def test_enemy_visual_runtime_defines_multiple_occult_silhouette_families():
    art = read("scripts/content/OccultCreaturePresentation.gd")
    for family in ["blind_archon", "mirror_wraith", "ember_tyrant", "stone_witness", "hollow_scribe", "serpentine_authority", "abyssal", "draconic"]:
        assert family in art
    assert "emission" in art.lower()
    assert "boss_phase" in art.lower()
