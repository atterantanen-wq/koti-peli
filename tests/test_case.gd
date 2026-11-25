extends RefCounted
## Testien yhteinen pohja. Testitiedosto: tests/test_*.gd, testi: func test_*().

var failures: Array[String] = []
var tree: SceneTree


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (odotettiin %s, saatiin %s)" % [message, str(expected), str(actual)])
