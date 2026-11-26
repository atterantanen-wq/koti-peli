# Koti-peli

Satumainen 3D-kotipeli 5-vuotiaalle. Lapsi ohjaa hahmoa napauttamalla ja herättää
kodin esineet eloon. Ensimmäinen huone on lastenhuone.

Peli tehdään [Godot 4](https://godotengine.org) -pelimoottorilla ja pelataan aluksi
selaimessa (iPhonen Safari). Kaikki on ilmaista.

## Pelaaminen iPhonella

1. Avaa pelin osoite Safarissa (osoite näkyy repon etusivulla kohdassa *Deployments*
   / *github-pages*, kun julkaisu on päällä).
2. Käännä puhelin vaakaan.
3. Vinkki: Safarin *Jaa*-valikosta **Lisää Koti-valikkoon**, niin peli aukeaa
   omana kuvakkeenaan koko näytölle ilman Safarin palkkeja.

## Ohjaus

- Napauta lattiaa: hahmo kävelee sinne (kohtaan tulee tähti).
- Napauta huonekalua tai lelua: hahmo kävelee sen viereen ja lelu herää eloon.
  Uusi napautus tekee uuden tempun.
- Napauta sänkyä: hahmo kiipeää sängylle, ja jokainen napautus on uusi pomppu.
- Napauta hahmoa: hahmo hyppää.
- Pidä sormi ruudulla ja liu'uta: hahmo seuraa sormea.

Vasemmassa yläkulmassa näkyy versio, päivämäärä ja kuvanopeus (fps). Siitä näkee,
onko uusin versio auki ja pyöriikö peli sujuvasti (tavoite 60 fps).

## Miten muutokset päätyvät peliin

Jokaisesta muutoksesta ajetaan automaattisesti testit ja tehdään selainversio
(GitHubin *Actions*-välilehti). Kun muutos yhdistetään `main`-haaraan, uusi versio
julkaistaan verkkoon muutamassa minuutissa.

## Kansiot

| Kansio | Sisältö |
| --- | --- |
| `scenes/main/` | Pelin aloituskohtaus |
| `scenes/rooms/` | Huoneet (lastenhuone, myöhemmin muut) |
| `scenes/props/` | Esineet, joihin voi koskea |
| `scenes/player/` | Pelihahmo |
| `scripts/` | Pelin koodi (GDScript); `scripts/core/` on yhteinen ydin |
| `scripts/props/` | Esineiden temput: `Interactable` ja reaktiopalikat |
| `assets/` | 3D-mallit, tekstuurit ja äänet |
| `tests/` | Automaattiset testit |

## Kehittäjälle

```sh
godot --headless --import                              # tuo tiedostot
godot --headless --script res://tests/run_tests.gd     # aja testit
godot --headless --export-release "Web" build/web/index.html  # tee selainversio
# kuvakaappaus pelistä (tarvitsee näytön, esim. xvfb-run):
xvfb-run godot --rendering-driver opengl3 --script res://tools/shot.gd -- kuva.png
```

Grafiikka tehdään koodilla (`scripts/art/`): `ArtKit` tekee pehmeät muodot, putket ja
kiehkurat sekä raita- ja tähtikuviot. Esimerkiksi `bed_art.gd` rakentaa metallisängyn ja
`player_art.gd` hahmon. Näin peli pysyy pienenä eikä tarvitse kuvatiedostoja.

## Uusi esine, joka herää eloon

Esine on `StaticBody3D` ryhmässä `prop`, ja sen kuva on `Visual`-solmun alla.
Lisää sille lapseksi `Interactable` (`scripts/props/interactable.gd`) ja valitse
temput (`variants`) valmiista palikoista `scripts/props/reactions/`:
pomppu, litistys, pyörähdys, siipien lepatus, lento reittiä pitkin, sydämet/tähdet,
piilossa olevan osan esiin ponnahdus, värien vaihto, päivä/yö (ryhmäkutsu)
ja hahmon liike (halaus, hyppy, pomppu). Temput vuorottelevat napautus kerrallaan.
Esimerkit: `scenes/props/` (panda, siipiotus, juna, nukkekoti, viirinauha).
