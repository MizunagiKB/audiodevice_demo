extends Control


var mic_device: AudioEffectRecord = null
var recording_data: AudioStreamSample = null


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

    var idx = AudioServer.get_bus_index("Record")
    mic_device = AudioServer.get_bus_effect(idx, 0)


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

        $stream_sampler.stop()
        $stream_sampler.stream = recording_data
        $stream_sampler.play()

