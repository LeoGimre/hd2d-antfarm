extends SceneTree
## qc_shot.gd — save PNG stills out of a scene at chosen frame numbers.
##
##   godot --path game --resolution 1280x720 --fixed-fps 30 \
##     --script res://tools/qc_shot.gd -- <scene> <out-dir> <frame,frame,...>
##
## farm/capture.sh already produces QC frames, but it gets them by rendering a
## whole clip to .ogv and handing it to ffmpeg. On a machine with no ffmpeg
## that leaves the loop unable to obey its own standing rule about looking at
## the picture before publishing, which is the one rule that cannot be worked
## around by being careful. This does the small half of capture.sh's job with
## nothing but Godot: no video, no encoder, just the frames asked for.
##
## Frame numbers matter more than they look. The bugs this catches — a label
## clipping once a BROKEN suffix makes it longer, a creature sunk into the
## floor — mostly appear mid-fight, and a scene's first frame never shows
## them. Ask for frames deep into the demo.
##
## Not headless: Godot's headless renderer draws nothing, so the image comes
## back blank. This needs a real rendering context, same as Movie Maker mode.

var _want: PackedInt32Array = []
var _out := ""
var _frame := 0
var _last := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("usage: qc_shot.gd -- <scene> <out-dir> <frame,frame,...>")
		quit(2)
		return

	_out = args[1]
	for token in args[2].split(","):
		_want.append(int(token))
	_want.sort()
	_last = _want[_want.size() - 1]

	DirAccess.make_dir_recursive_absolute(_out)
	var scene: PackedScene = load(args[0])
	if scene == null:
		push_error("could not load scene: %s" % args[0])
		quit(2)
		return
	root.add_child(scene.instantiate())


func _process(_delta: float) -> bool:
	_frame += 1
	# get_image() reads back whatever is currently on the viewport, which is
	# the frame drawn *before* this one — near enough for QC, and the
	# alternative (awaiting frame_post_draw) is not available from a MainLoop.
	if _want.has(_frame):
		var image := root.get_texture().get_image()
		var path := "%s/frame-%04d.png" % [_out, _frame]
		image.save_png(path)
		print("qc_shot: wrote %s" % path)
	return _frame > _last
