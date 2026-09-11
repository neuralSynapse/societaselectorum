extends Node

signal narration_started(text: String, channel: StringName, estimated_duration: float)
signal narration_stopped

const LANGUAGE := "pt-BR"
const NARRATIVE_LABEL_NAMES := ["Subtitle", "StoryMessage", "ChoicePrompt", "RevealLabel", "Message"]
const MIN_DURATION := 2.4
const MAX_DURATION := 22.0

var enabled := true
var voice_rate := 0.94
var voice_pitch := 0.86
var voice_volume := 0.82
var _native_voice_id := ""
var _utterance_id := 0
var _last_text_by_path: Dictionary = {}
var _last_spoken_text := ""
var _last_spoken_at_msec := 0
var _scan_accumulator := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _native_voice_id = _select_native_voice()

func _process(delta: float) -> void:
    if not enabled:
        return
    _scan_accumulator += delta
    if _scan_accumulator < 0.12:
        return
    _scan_accumulator = 0.0
    _scan_visible_narrative_labels()

func set_enabled(value: bool) -> void:
    enabled = value
    if not enabled:
        stop()

func speak(text: String, channel: StringName = &"narration", interrupt := true) -> float:
    var normalized := _normalize_text(text)
    if not enabled or normalized.is_empty():
        return 0.0
    var now := Time.get_ticks_msec()
    if normalized == _last_spoken_text and now - _last_spoken_at_msec < 900:
        return estimate_duration(normalized)
    if interrupt:
        stop()
    _last_spoken_text = normalized
    _last_spoken_at_msec = now
    _utterance_id += 1
    var duration := estimate_duration(normalized)
    var spoken := false
    if OS.has_feature("web"):
        spoken = _speak_web(normalized, interrupt)
        if not spoken:
            spoken = _speak_native(normalized, interrupt)
    else:
        spoken = _speak_native(normalized, interrupt)
    narration_started.emit(normalized, channel, duration)
    if not spoken and OS.is_debug_build():
        print("NARRATOR_FALLBACK_SILENT text=", normalized)
    return duration

func stop() -> void:
    if OS.has_feature("web"):
        JavaScriptBridge.eval("(()=>{try{if(window.speechSynthesis){window.speechSynthesis.cancel();return true;}}catch(e){}return false;})()", true)
    DisplayServer.tts_stop()
    narration_stopped.emit()

func estimate_duration(text: String) -> float:
    var normalized := _normalize_text(text)
    if normalized.is_empty():
        return 0.0
    var words := normalized.split(" ", false).size()
    var punctuation_bonus := 0.0
    for mark in [".", ",", ";", ":", "?", "!"]:
        punctuation_bonus += float(normalized.count(mark)) * 0.12
    var seconds := (float(words) * 0.42 / maxf(0.65, voice_rate)) + punctuation_bonus + 0.65
    return clampf(seconds, MIN_DURATION, MAX_DURATION)

func _scan_visible_narrative_labels() -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    for node_name in NARRATIVE_LABEL_NAMES:
        var matches := scene.find_children(node_name, "Label", true, false)
        for candidate in matches:
            if not (candidate is Label):
                continue
            var label := candidate as Label
            var raw_text := label.text
            if node_name == "Message" and "\n" not in raw_text:
                continue
            var path := String(label.get_path())
            var text := _normalize_text(raw_text)
            var previous := String(_last_text_by_path.get(path, ""))
            _last_text_by_path[path] = text
            if text.is_empty() or text == previous or not label.is_visible_in_tree():
                continue
            var duration := speak(text, StringName(node_name.to_lower()), true)
            _extend_visible_duration(label, node_name, duration)

func _extend_visible_duration(label: Label, node_name: String, duration: float) -> void:
    if duration <= 0.0:
        return
    var current: Node = label
    while current != null:
        if node_name == "Subtitle" and current is NarrativePresentationController:
            var presentation := current as NarrativePresentationController
            presentation.line_timer = maxf(presentation.line_timer, duration + 0.25)
            return
        if node_name == "StoryMessage" and current is NarrativePresentationController:
            var presentation := current as NarrativePresentationController
            presentation.message_timer = maxf(presentation.message_timer, duration + 0.25)
            return
        if node_name == "Message" and current is HUDController:
            var hud := current as HUDController
            hud.hide_timer = maxf(hud.hide_timer, duration + 0.25)
            return
        current = current.get_parent()

func _select_native_voice() -> String:
    var voices := DisplayServer.tts_get_voices()
    var fallback := ""
    for voice_value in voices:
        if not (voice_value is Dictionary):
            continue
        var voice: Dictionary = voice_value
        var voice_id := String(voice.get("id", voice.get("name", "")))
        if fallback.is_empty() and not voice_id.is_empty():
            fallback = voice_id
        var language := String(voice.get("language", "")).to_lower()
        var name := String(voice.get("name", "")).to_lower()
        if language.begins_with("pt") or "portugu" in name:
            return voice_id
    return fallback

func _speak_native(text: String, interrupt: bool) -> bool:
    if _native_voice_id.is_empty():
        _native_voice_id = _select_native_voice()
    if _native_voice_id.is_empty():
        return false
    DisplayServer.tts_speak(
        text,
        _native_voice_id,
        int(round(voice_volume * 100.0)),
        voice_pitch,
        voice_rate,
        _utterance_id,
        interrupt
    )
    return true

func _speak_web(text: String, interrupt: bool) -> bool:
    var js_text := JSON.stringify(text)
    var cancel_code := "s.cancel();" if interrupt else ""
    var script := """
(()=>{
  try {
    const s=window.speechSynthesis;
    if(!s || typeof SpeechSynthesisUtterance==='undefined') return false;
    %s
    const u=new SpeechSynthesisUtterance(%s);
    u.lang='%s';
    u.rate=%s;
    u.pitch=%s;
    u.volume=%s;
    const voices=s.getVoices ? s.getVoices() : [];
    const voice=voices.find(v=>/^pt(-|_)/i.test(v.lang||'')) || voices.find(v=>/portugu/i.test(v.name||''));
    if(voice) u.voice=voice;
    s.speak(u);
    return true;
  } catch(e) {
    console.warn('CHRONICA narrator failed', e);
    return false;
  }
})()
""" % [cancel_code, js_text, LANGUAGE, str(voice_rate), str(voice_pitch), str(voice_volume)]
    var result = JavaScriptBridge.eval(script, true)
    return bool(result)

func _normalize_text(text: String) -> String:
    var normalized := text.strip_edges()
    if normalized.is_empty():
        return ""
    normalized = normalized.replace("\n", ". ")
    while "  " in normalized:
        normalized = normalized.replace("  ", " ")
    return normalized
