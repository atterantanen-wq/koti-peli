extends "res://tests/test_case.gd"
## Tarkistaa asetukset, joita selainversio iPhonen Safarissa tarvitsee.


func test_renderer_is_compatibility() -> void:
	# Selainversio toimii vain Compatibility-renderöijällä.
	check_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"),
			"gl_compatibility", "renderöijä")
	check_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile"),
			"gl_compatibility", "mobiilirenderöijä")


func test_main_scene_exists() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene")
	check(ResourceLoader.exists(path), "pääkohtaus puuttuu: %s" % path)


func test_landscape_orientation() -> void:
	# 4 = vaakasuunta, kumpaan päin tahansa.
	check_eq(ProjectSettings.get_setting("display/window/handheld/orientation"), 4, "näytön suunta")


func test_web_export_preset() -> void:
	var config := ConfigFile.new()
	check_eq(config.load("res://export_presets.cfg"), OK, "export_presets.cfg latautuu")
	var section := ""
	for s in config.get_sections():
		if s.begins_with("preset.") and s.count(".") == 1 \
				and config.get_value(s, "platform", "") == "Web":
			section = s
	check(section != "", "Web-vientiasetus löytyy")
	if section == "":
		return
	check_eq(config.get_value(section, "export_path", ""), "build/web/index.html", "vientipolku")
	var options := section + ".options"
	# Ilman säikeitä peli toimii GitHub Pagesissa ja Safarissa ilman erikoisotsakkeita.
	check_eq(config.get_value(options, "variant/thread_support", true), false, "säikeet pois")
	check_eq(config.get_value(options, "vram_texture_compression/for_mobile", false), true,
			"mobiilitekstuurit")
	# Offline-välimuisti näytti iPhonella vanhaa versiota päivityksen jälkeen.
	check_eq(config.get_value(options, "progressive_web_app/enabled", true), false,
			"offline-välimuisti pois")


func test_safari_page_zoom_blocked() -> void:
	# Kahden sormen nipistys zoomaa pelin kameraa, ei koko sivua (Safarin gesture-tapahtumat).
	var config := ConfigFile.new()
	config.load("res://export_presets.cfg")
	var head := ""
	for s in config.get_sections():
		if s.ends_with(".options") and config.has_section_key(s, "html/head_include"):
			head = config.get_value(s, "html/head_include", "")
	check(head.contains("gesturestart") and head.contains("preventDefault"),
			"Safarin sivun zoomaus estetty")
