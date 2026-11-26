extends SceneTree
## Kehittäjän apu: ottaa kuvakaappauksen pelistä (vaatii näytön, esim. xvfb-run).
## Käyttö: xvfb-run godot --rendering-driver opengl3 --script res://tools/shot.gd -- out.png [x y z lx ly lz]
## Ympäristömuuttujat: SHOT_PET=cat/dog valitsee lemmikin, SHOT_NIGHT=1 vaihtaa yöhön.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "shot.png"
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 5:
		await process_frame
	var pet := OS.get_environment("SHOT_PET")
	if pet != "" and main.has_method("choose_pet"):
		var picker: Node = main.get("picker")
		if is_instance_valid(picker):
			picker.queue_free()
		main.choose_pet(pet)
	if OS.get_environment("SHOT_NIGHT") == "1":
		(main.get_node("DayNight") as DayNight).set_night(true)
	for i in 100:
		await process_frame
	if args.size() >= 7:
		var cam := main.get_node("Camera3D") as Camera3D
		cam.set_script(null)
		cam.position = Vector3(float(args[1]), float(args[2]), float(args[3]))
		cam.look_at(Vector3(float(args[4]), float(args[5]), float(args[6])))
		for i in 5:
			await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	quit()
