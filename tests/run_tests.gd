extends SceneTree
## Ajaa kaikki testit ilman näyttöä:
##   godot --headless --script res://tests/run_tests.gd
## Lopettaa koodilla 0, jos kaikki menee läpi, muuten 1.

const TEST_DIR := "res://tests"


func _initialize() -> void:
	var total := 0
	var failed := 0
	var files := DirAccess.get_files_at(TEST_DIR)
	files.sort()
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: GDScript = load(TEST_DIR.path_join(file))
		if script == null or not script.can_instantiate():
			print("FAIL %s: tiedostoa ei voitu ladata" % file)
			failed += 1
			total += 1
			continue
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			var test = script.new()
			test.tree = self
			test.call(name)
			if test.failures.is_empty():
				print("ok   %s :: %s" % [file, name])
			else:
				failed += 1
				for message in test.failures:
					print("FAIL %s :: %s: %s" % [file, name, message])
	print("")
	if total == 0:
		print("TESTEJÄ EI LÖYTYNYT")
		quit(1)
	elif failed > 0:
		print("%d / %d testiä epäonnistui" % [failed, total])
		quit(1)
	else:
		print("KAIKKI TESTIT MENIVÄT LÄPI (%d)" % total)
		quit(0)
