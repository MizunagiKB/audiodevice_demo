extends Node
class_name CMiniSynth


const BASE_FREQ: float = 440.0
const CENTER_NOTE: int = 69
const NOTE_RANGE = 128
const VOLUME = 0.25
const V_NOTE_W = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17]
const V_NOTE_B = [-1, 1, 3, -1, 6, 8, 10, -1, 13, 15, -1, -1]

enum E_NOTE_STATUS {
    KON,
    KON_KEEP,
    KOF_KEEP,
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


var adsr_atk: float = 0.1
var adsr_rel: float = 0.5
var tone_curr: int = 0
var v_note_curr: int = -1
var v_note_on: bool = false
var dict_note_status: Dictionary = {}
var stream_playback: AudioStreamGeneratorPlayback = null


class CAudioBuffer:

    var buffer: PoolVector2Array = PoolVector2Array()

    func resize(new_size: int) -> void:
        self.buffer.resize(new_size)


class CGenerator:
    func generate(_deg: float) -> float:
        assert(false)
        return 0.0

class CGeneratorCos:
    extends CGenerator
    func generate(deg: float) -> float:
        return cos(deg2rad(deg))

class CGeneratorSaw:
    extends CGenerator
    func generate(deg: float) -> float:
        return (((int(deg) % 180) / 180.0) - 0.5) * 2

class CGeneratorSquare:
    extends CGenerator
    func generate(deg: float) -> float:
        var v = (((int(deg) % 180) / 180.0) - 0.5) * 2
        if v > 0:
            v = 1.0
        elif v < 0:
            v = -1.0
        else:
            v = 0
        return v 


class CVoice:

    var e_status: int = E_NOTE_STATUS.KOF
    var note: int = 0
    var step: int = 0
    var elapse_time: float = 0.0
    var release_time: float = 0.0
    
    var attack: float = 0.2
    var release: float = 0.5

    func _init(new_note: int):
        self.note = new_note

    func is_play() -> bool:
        return self.e_status in [E_NOTE_STATUS.KON, E_NOTE_STATUS.KON_KEEP]

    func is_complete() -> bool:
        return self.e_status == E_NOTE_STATUS.KOF

    func calc():
        if self.e_status == E_NOTE_STATUS.KOF_KEEP:
            return 1.0 - min(self.release_time / self.release, 1.0)
        elif self.e_status == E_NOTE_STATUS.KOF:
            return 0.0
        else:
            return min(self.elapse_time / self.attack, 1.0)

    func kon():
        if self.e_status == E_NOTE_STATUS.KOF:
            self.e_status = E_NOTE_STATUS.KON
            self.release_time = 0.0
            self.elapse_time = 0.0
            self.step = 0

    func kof():
        if self.e_status != E_NOTE_STATUS.KOF:
            self.e_status = E_NOTE_STATUS.KOF_KEEP

    func update(dtime: float, buf: CAudioBuffer, o_generator: CGenerator) -> void:

        if self.is_complete() == true:
            return
        else:
            if self.e_status == E_NOTE_STATUS.KOF_KEEP:
                self.release_time += dtime
                if self.release_time > self.release:
                    self.e_status = E_NOTE_STATUS.KOF
            
        if self.e_status == E_NOTE_STATUS.KON:
            self.e_status = E_NOTE_STATUS.KON_KEEP

        var freq: float = BASE_FREQ * pow(2, (self.note - CENTER_NOTE) / 12.0)
        var deg: float = (360.0 / 44000.0) * freq

        var v: float = 0.0
        for n in range(buf.buffer.size()):
            v = o_generator.generate(deg * self.step)
            v *= self.calc()
            v *= VOLUME
            buf.buffer[n] += Vector2(v, v)
            self.step += 1

        self.elapse_time += dtime


func write_note_status(note_v: int, note_trig: bool) -> void:

    var target_note: int = ($spin_octave.value * 12) + note_v

    assert(target_note > -1)
    assert(target_note < 128)

    if note_trig == true:
        if dict_note_status.has(target_note) == true:
            if dict_note_status[target_note].is_play():
                return

        var o_voice: CVoice = CVoice.new(target_note)
        o_voice.kon()
        dict_note_status[target_note] = o_voice
    else:
        if dict_note_status.has(target_note) != true:
            return

        var o_voice: CVoice = dict_note_status[target_note]
        o_voice.kof()


func change_octave(e_octave_order: int) -> void:

    if dict_note_status.size() > 0:
        return

    var v = $spin_octave.value

    match e_octave_order:
        E_OCTAVE_ORDER.INC:
            v += 1
        E_OCTAVE_ORDER.DEC:
            v -= 1

    $spin_octave.value = clamp(v, -1, 6)


func update(dtime: float, buf: CAudioBuffer):

    var o_generator: CGenerator = null

    match tone_curr:
        E_TONE.COS:
            o_generator = CGeneratorCos.new()
        E_TONE.SAW:
            o_generator = CGeneratorSaw.new()
        E_TONE.SQUARE:
            o_generator = CGeneratorSquare.new()

    var list_k: Array = []

    for o in dict_note_status.values():
        var o_voice: CVoice = o
        if o_voice.is_complete() == true:
            list_k.append(o_voice.note)
        else:
            o_voice.attack = adsr_atk
            o_voice.release = adsr_rel
            o_voice.update(dtime, buf, o_generator)

    for note in list_k:
        var _v = dict_note_status.erase(note)


func _ready():

    stream_playback = $stream_player.get_stream_playback()

    adsr_atk = $slider_atk.value
    adsr_rel = $slider_rel.value

    $stream_player.play()


func _process(delta):

    var frame_size = stream_playback.get_frames_available()
    var buf = CAudioBuffer.new()

    buf.resize(frame_size)

    update(delta, buf)

    var _v = stream_playback.push_buffer(buf.buffer)


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


func get_note_position(position: Vector2) -> int:

    var ary_index: int = 0
    var note: int = -1

    if position.y < 64:
        ary_index = int((position.x + 24) / 48)
        if ary_index < V_NOTE_B.size():
            note = V_NOTE_B[ary_index]

    if note == -1:
        ary_index = int(position.x / 48)
        if ary_index < V_NOTE_W.size():
            note = V_NOTE_W[ary_index]

    return note


func _on_img_keyboard_gui_input(event):

    var note: int = -1

    if event is InputEventMouseButton:
        note = get_note_position(event.position)
        if note != -1:
            if event.button_index == BUTTON_LEFT:
                write_note_status(note, event.pressed)
                v_note_curr = note
                v_note_on = event.pressed

    elif event is InputEventMouseMotion:
        if v_note_on == true:
            note = get_note_position(event.position)
            if note != v_note_curr:
                write_note_status(v_note_curr, false)
                if note != -1:
                    write_note_status(note, true)
                    v_note_curr = note


func _on_btn_tone_item_selected(id):
    tone_curr = id


func _on_slider_atk_value_changed(value):
    adsr_atk = value


func _on_slider_rel_value_changed(value):
    adsr_rel = value