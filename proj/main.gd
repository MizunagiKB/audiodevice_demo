extends Control


const BASE_FREQ: float = 440.0
const CENTER_NOTE: int = 69
const MIN_AUDIO_BUFFER_SIZE = 44000 * 0.1
const NOTE_RANGE = 128
const VOLUME = 0.25

enum E_NOTE_STATUS {
    KON_TRIG,
    KON_KEEP,
    KOF
}

enum E_TONE {
    COS,
    SAW,
    SQUARE    
}

enum E_OCTAVE_ORDER {
    INC,
    DEC
}

var list_note_status: Array = []
var octave_curr: int = 5
var tone_curr: int = 0


class CNote:

    var e_status = E_NOTE_STATUS.KOF
    var step: int = 0
    var note: int = 0
    
    func _init(new_note: int):
        self.note = new_note

    func kon():
        self.e_status = E_NOTE_STATUS.KON_TRIG

    func kof():
        self.e_status = E_NOTE_STATUS.KOF
        self.step = 0

    func gen_cos(r: float) -> float:
        return cos(deg2rad(r))

    func gen_saw(r: float) -> float:
        var v = (((int(r) % 180) / 180.0) - 0.5) * 2

        return v

    func gen_square(r: float) -> float:
        var v = (((int(r) % 180) / 180.0) - 0.5) * 2
        if v > 0:
            v = 1
        else:
            v = -1
        return v 

    func update(tone: int, w_buffer: PoolVector2Array) -> PoolVector2Array:

        if self.e_status == E_NOTE_STATUS.KOF:
            return w_buffer
        elif self.e_status == E_NOTE_STATUS.KON_TRIG:
            self.e_status = E_NOTE_STATUS.KON_KEEP

        var freq: float = BASE_FREQ * pow(2, (self.note - CENTER_NOTE) / 12.0)

        freq = (360.0 / 44000.0) * freq

        var v: float = 0.0
        for n in range(w_buffer.size()):
            match tone:
                E_TONE.COS:
                    v = gen_cos(freq * step)
                E_TONE.SAW:
                    v = gen_saw(freq * step)
                E_TONE.SQUARE:
                    v = gen_square(freq * step)
            w_buffer[n] += Vector2(v * VOLUME, v * VOLUME)
            self.step += 1

        return w_buffer


var stream_playback: AudioStreamGeneratorPlayback = null
var mic_device: AudioEffectRecord = null
var recording_data: AudioStreamSample = null


func write_note_status(note_v: int, note_trig: bool) -> void:

    var e_status = E_NOTE_STATUS.KOF
    var target_note: int = (octave_curr * 12) + note_v

    assert(target_note > -1)
    assert(target_note < 128)

    if note_trig == true:
        list_note_status[target_note].kon()
    else:
        list_note_status[target_note].kof()


func change_octave(e_octave_order: int) -> void:

    for o in list_note_status:
        var o_note: CNote = o
        if o_note.e_status != E_NOTE_STATUS.KOF:
            return

    match e_octave_order:
        E_OCTAVE_ORDER.INC:
            octave_curr += 1
        E_OCTAVE_ORDER.DEC:
            octave_curr -= 1

    octave_curr = clamp(octave_curr, -1, 6)


func _ready():

    var list_item: Array = []

    list_item = AudioServer.get_device_list()
    for idx in list_item.size():
        $btn_audio_o.add_item(list_item[idx], idx)
    $btn_audio_o.select(0)

    list_item = AudioServer.capture_get_device_list()
    for idx in list_item.size():
        $btn_audio_i.add_item(list_item[idx], idx)
    $btn_audio_i.select(0)

    for n in range(NOTE_RANGE):
        list_note_status.append(CNote.new(n))

    stream_playback = $stream_player.get_stream_playback()

    var idx = AudioServer.get_bus_index("Record")
    mic_device = AudioServer.get_bus_effect(idx, 0)


func _input(event):

    if event is InputEventKey:
        match event.scancode:
            KEY_A: write_note_status(0, event.pressed)
            KEY_W: write_note_status(1, event.pressed)
            KEY_S: write_note_status(2, event.pressed)
            KEY_E: write_note_status(3, event.pressed)
            KEY_D: write_note_status(4, event.pressed)
            KEY_F: write_note_status(5, event.pressed)
            KEY_T: write_note_status(6, event.pressed)
            KEY_G: write_note_status(7, event.pressed)
            KEY_Y: write_note_status(8, event.pressed)
            KEY_H: write_note_status(9, event.pressed)
            KEY_U: write_note_status(10, event.pressed)
            KEY_J: write_note_status(11, event.pressed)
            KEY_K: write_note_status(12, event.pressed)
            KEY_O: write_note_status(13, event.pressed)
            KEY_L: write_note_status(14, event.pressed)
            KEY_P: write_note_status(15, event.pressed)
            KEY_SEMICOLON: write_note_status(16, event.pressed)
            KEY_COLON: write_note_status(17, event.pressed)

    if event.is_action_released("octave_inc"):
        change_octave(E_OCTAVE_ORDER.INC)
    if event.is_action_released("octave_dec"):
        change_octave(E_OCTAVE_ORDER.DEC)


func _process(delta):

    var frame_size = stream_playback.get_frames_available()

    if frame_size < MIN_AUDIO_BUFFER_SIZE:
        return
    else:
        frame_size = MIN_AUDIO_BUFFER_SIZE

    var w_buffer = PoolVector2Array()

    w_buffer.resize(frame_size)

    for o in list_note_status:
        var o_note: CNote = o
        w_buffer = o_note.update(tone_curr, w_buffer)

    stream_playback.push_buffer(w_buffer)

    $lbl_octave.text = str(octave_curr)


func _on_btn_audio_o_item_selected(id):
    var device_name = $btn_audio_o.get_item_text(id)
    if device_name.length() > 0:
        AudioServer.set_device(device_name)


func _on_btn_audio_i_item_selected(id):
    var device_name = $btn_audio_i.get_item_text(id)
    if device_name.length() > 0:
        AudioServer.capture_set_device(device_name)


func _on_btn_rec_pressed():

    if mic_device.is_recording_active():
        recording_data = mic_device.get_recording()
        mic_device.set_recording_active(false)
        $btn_play.disabled = false
    else:
        mic_device.set_recording_active(true)
        $btn_play.disabled = true


func _on_btn_play_pressed():

    if recording_data != null:

        var wav_data = recording_data.get_data()

        $stream_sampler.stop()
        $stream_sampler.stream = recording_data
        $stream_sampler.play()


func _on_bnt_tone_item_selected(id):
    tone_curr = id
