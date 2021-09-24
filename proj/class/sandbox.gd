extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


class CTest:
    var value_1: int = 0
    var value_2: String = ""
    var ary_test: PoolVector2Array = PoolVector2Array()

    func _init():
        self.ary_test.resize(8)


# Called when the node enters the scene tree for the first time.
func _ready():
    pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func test(o: CTest):

    o.value_1 += 32
    o.ary_test[0].x = 33
    o.ary_test[0].y = 66


func _process(delta):

    var o_test: CTest = CTest.new()
    
    o_test.value_1 = 11
    
    test(o_test)

    print(o_test.value_1)
    print(o_test.ary_test[0])


