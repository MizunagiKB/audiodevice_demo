extends Node
class_name CMiniSynth


const BASE_FREQ: float = 440.0
const CENTER_NOTE: int = 69
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

var adsr_atk: float = 0.1
var adsr_rel: float = 0.5
var tone_curr: int = 0
var octave_curr: int = 5
var list_note_status: Array = []


class CAudioBuffer:

    var buffer: PoolVector2Array = PoolVector2Array()

    func resize(new_size: int) -> void:
        self.buffer.resize(new_size)


class CGenerator:
    func generate(deg: float) -> float:
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
        else:
            v = -1.0
        return v 


class CSynth:

    var e_status: int = E_NOTE_STATUS.KOF
    var note: int = 0
    var step: int = 0
    var elapse_time: float = 0.0
    var release_time: float = 9999.0
    
    var attack: float = 0.2
    var release: float = 0.5

    func _init(new_note: int):
        self.note = new_note

    func calc():
        if self.e_status == E_NOTE_STATUS.KOF:
            return 1.0 - min(self.release_time / self.release, 1.0)
        else:
            return min(self.elapse_time / self.attack, 1.0)

    func kon():
        if self.e_status == E_NOTE_STATUS.KOF:
            self.e_status = E_NOTE_STATUS.KON_TRIG
            self.release_time = 0.0
            self.elapse_time = 0.0
            self.step = 0

    func kof():
        self.e_status = E_NOTE_STATUS.KOF

    func update(dtime: float, buf: CAudioBuffer, o_generator: CGenerator) -> void:

        if self.e_status == E_NOTE_STATUS.KOF:
            if self.release_time > self.release:
                return
            else:
                self.release_time += dtime
            
        elif self.e_status == E_NOTE_STATUS.KON_TRIG:
            self.e_status = E_NOTE_STATUS.KON_KEEP

        var freq: float = BASE_FREQ * pow(2, (self.note - CENTER_NOTE) / 12.0)
        var deg: float = (360.0 / 44000.0) * freq

        var v: float = 0.0
        for n in range(buf.buffer.size()):
            # var s = self.step + (cos(deg * self.step / 2000) * 90)
            v = o_generator.generate(deg * self.step)
            v *= self.calc()
            v *= VOLUME
            buf.buffer[n] += Vector2(v, v)
            self.step += 1

        self.elapse_time += dtime


func write_note_status(note_v: int, note_trig: bool) -> void:

    var target_note: int = (octave_curr * 12) + note_v

    assert(target_note > -1)
    assert(target_note < 128)

    if note_trig == true:
        list_note_status[target_note].kon()
    else:
        list_note_status[target_note].kof()


func change_octave(e_octave_order: int) -> void:

    for o in list_note_status:
        var o_synth: CSynth = o
        if o_synth.e_status != E_NOTE_STATUS.KOF:
            return

    match e_octave_order:
        E_OCTAVE_ORDER.INC:
            octave_curr += 1
        E_OCTAVE_ORDER.DEC:
            octave_curr -= 1

    octave_curr = clamp(octave_curr, -1, 6)


func update(dtime: float, buf: CAudioBuffer):

    var o_generator: CGenerator = null

    match tone_curr:
        E_TONE.COS:
            o_generator = CGeneratorCos.new()
        E_TONE.SAW:
            o_generator = CGeneratorSaw.new()
        E_TONE.SQUARE:
            o_generator = CGeneratorSquare.new()

    for o in list_note_status:
        var o_synth: CSynth = o
        o_synth.attack = adsr_atk
        o_synth.release = adsr_rel
        o_synth.update(dtime, buf, o_generator)


func _init():

    for n in range(NOTE_RANGE):
        list_note_status.append(CSynth.new(n))
