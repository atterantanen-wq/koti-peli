# Ohjeet tekoälyagenteille

- Omistaja (Atte) ei ole tekninen: kirjoita hänelle suomeksi ja yksinkertaisesti.
- Godot 4.5 (versio `.github/workflows/ci.yml`:n `GODOT_VERSION`), GDScript, Compatibility-renderöijä.
- Kohde: selainversio iPhonen Safarissa (web-vienti ilman säikeitä, `export_presets.cfg`).
  Älä ota käyttöön Forward+/Mobile-renderöijää tai säikeitä: ne rikkovat selainversion.
- Testit: `tests/test_*.gd`, pohja `tests/test_case.gd` (`check`, `check_eq`).
  Ajo: `godot --headless --import && godot --headless --script res://tests/run_tests.gd`.
  Lisää testi jokaiselle uudelle toiminnolle.
- Repo voi olla julkinen: älä lisää tänne kuvia perheestä tai kodista, henkilötietoja tai salaisuuksia.
- Suunnitelma ja työpaketit: Aten Claude-dokumentti "Lasten 3D-kotipeli – suunnitelma v1".
