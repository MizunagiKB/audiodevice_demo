extends Control



var stream_playback: AudioStreamGeneratorPlayback = null
var mic_device: AudioEffectRecord = null
var recording_data: AudioStreamSample = null

var o_synth: CMiniSynth


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

    stream_playback = $stream_player.get_stream_playback()

    var idx = AudioServer.get_bus_index("Record")
    mic_device = AudioServer.get_bus_effect(idx, 0)

    o_synth = CMiniSynth.new()

    o_synth.adsr_atk = $slider_atk.value
    o_synth.adsr_rel = $slider_rel.value

    $stream_player.play()


func _input(event):

    if event is InputEventKey:
        match event.scancode:
            KEY_A: o_synth.write_note_status(0, event.pressed)
            KEY_W: o_synth.write_note_status(1, event.pressed)
            KEY_S: o_synth.write_note_status(2, event.pressed)
            KEY_E: o_synth.write_note_status(3, event.pressed)
            KEY_D: o_synth.write_note_status(4, event.pressed)
            KEY_F: o_synth.write_note_status(5, event.pressed)
            KEY_T: o_synth.write_note_status(6, event.pressed)
            KEY_G: o_synth.write_note_status(7, event.pressed)
            KEY_Y: o_synth.write_note_status(8, event.pressed)
            KEY_H: o_synth.write_note_status(9, event.pressed)
            KEY_U: o_synth.write_note_status(10, event.pressed)
            KEY_J: o_synth.write_note_status(11, event.pressed)
            KEY_K: o_synth.write_note_status(12, event.pressed)
            KEY_O: o_synth.write_note_status(13, event.pressed)
            KEY_L: o_synth.write_note_status(14, event.pressed)
            KEY_P: o_synth.write_note_status(15, event.pressed)
            KEY_SEMICOLON: o_synth.write_note_status(16, event.pressed)
            KEY_COLON: o_synth.write_note_status(17, event.pressed)

    if event.is_action_released("octave_inc"):
        o_synth.change_octave(CMiniSynth.E_OCTAVE_ORDER.INC)
    if event.is_action_released("octave_dec"):
        o_synth.change_octave(CMiniSynth.E_OCTAVE_ORDER.DEC)


func _process(delta):

    var frame_size = stream_playback.get_frames_available()
    var buf = CMiniSynth.CAudioBuffer.new()

    buf.resize(frame_size)

    o_synth.update(delta, buf)

    stream_playback.push_buffer(buf.buffer)

    $lbl_octave.text = str(o_synth.octave_curr)


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
    o_synth.tone_curr = id


func _on_slider_atk_value_changed(value):
    o_synth.adsr_atk = value


func _on_slider_rel_value_changed(value):
    o_synth.adsr_rel = value
