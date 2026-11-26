// Avaa selainversion oikeassa selaimessa (Chromium), ottaa kuvakaappauksen ja
// tarkistaa, että ruudun keskellä näkyy jotain muuta kuin taustaväri ja että
// napautus menee peliin asti (peli kirjoittaa konsoliin "napautus N: ...").
// Lopuksi kokeillaan esineiden temppuja iPhonen tapaisella kosketuksella
// (iso sormitunniste): sängyllä pomppiminen, siipiotuksen lento ja lammasyövalo.
// Alussa valitaan kuvista tyttö ja lemmikki (kissa), ja lopuksi silitetään lemmikkiä
// ja vaihdetaan vaatekaapista vaatteet.
// Käyttö: node tools/web_smoke.mjs build/web screenshot.png
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";
import { PNG } from "pngjs";

const root = path.resolve(process.argv[2] || "build/web");
const out = process.argv[3] || "screenshot.png";
const types = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png", ".json": "application/json",
  ".webmanifest": "application/manifest+json", ".svg": "image/svg+xml" };

const server = http.createServer((req, res) => {
  const file = path.join(root, decodeURIComponent(new URL(req.url, "http://x").pathname));
  const target = fs.existsSync(file) && fs.statSync(file).isDirectory() ? path.join(file, "index.html") : file;
  if (!fs.existsSync(target)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { "Content-Type": types[path.extname(target)] || "application/octet-stream" });
  fs.createReadStream(target).pipe(res);
}).listen(8060);

const browser = await chromium.launch({ args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] });
// hasTouch: kokeillaan myös oikeaa kosketusta, kuten iPhonessa.
const page = await browser.newPage({ viewport: { width: 844, height: 390 }, hasTouch: true });
const logs = [];
page.on("console", (m) => { logs.push(m.text()); console.log(`[selain ${m.type()}] ${m.text()}`); });
page.on("pageerror", (e) => console.log(`[selain virhe] ${e.message}`));
await page.goto("http://localhost:8060/index.html");
await page.waitForTimeout(12000);
// Lemmikin valinta: peli kertoo kuvien paikat (Pick_cat, Pick_dog). Valintaruudun
// napautus ei saa liikuttaa hahmoa.
await page.screenshot({ path: out.replace(".png", "-hero.png") });
const vp0 = page.viewportSize();
const pickHero = await page.evaluate(() => (window.kotiPeliProps || {}).Pick_girl);
if (!pickHero) { console.log("VIRHE: hahmon valintaa (tyttö/poika) ei näy"); process.exit(1); }
await page.touchscreen.tap(pickHero[0] * vp0.width, pickHero[1] * vp0.height);
await page.waitForTimeout(1200);
await page.screenshot({ path: out.replace(".png", "-picker.png") });
const pick = await page.evaluate(() => (window.kotiPeliProps || {}).Pick_cat);
if (!pick) { console.log("VIRHE: lemmikin valintaa ei näy"); process.exit(1); }
await page.touchscreen.tap(pick[0] * vp0.width, pick[1] * vp0.height);
await page.waitForTimeout(1500);
const tapsBeforeGame = logs.filter((l) => l.startsWith("napautus ")).length;
await page.screenshot({ path: out });
await page.touchscreen.tap(422, 195);
await page.waitForTimeout(500);
await page.touchscreen.tap(300, 300);
await page.waitForTimeout(500);
// iPhonen Safari antaa sormille isoja tunnisteita. Kokeillaan samaa Chromiumin kautta.
const cdp = await page.context().newCDPSession(page);
const point = { x: 560, y: 300, id: 1730593021 };
await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [point] });
await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
await page.waitForTimeout(1500);
await page.screenshot({ path: out.replace(".png", "-tap.png") });

// Esineiden temput. Peli kertoo esineiden paikat ruudulla (window.kotiPeliProps).
let fingerId = 1730594000;
const iphoneTap = async (x, y) => {
  const p = { x, y, id: fingerId++ };
  await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [p] });
  await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
};
// Kamera liikkuu (seuraa hahmoa, lähikuvat), joten odotetaan että esine pysyy paikallaan
// ruudulla ennen napautusta. Lapsi napauttaa sitä, minkä näkee.
const tapProp = async (name) => {
  let props = {};
  let prev = null;
  for (let i = 0; i < 20; i++) {
    props = await page.evaluate(() => window.kotiPeliProps || {});
    const p = props[name];
    if (p && prev && Math.abs(p[0] - prev[0]) < 0.003 && Math.abs(p[1] - prev[1]) < 0.003) break;
    prev = p || null;
    await page.waitForTimeout(250);
  }
  if (!props[name]) { console.log(`esinettä ${name} ei löytynyt ruudulta`); return; }
  const vp = page.viewportSize();
  await iphoneTap(props[name][0] * vp.width, props[name][1] * vp.height);
};
await tapProp("Bed");          // kävele sängylle ja kiipeä
await page.waitForTimeout(4000);
await tapProp("Bed");          // pomppu
await page.waitForTimeout(350);
await page.screenshot({ path: out.replace(".png", "-bed.png") });
await page.waitForTimeout(1000);
await tapProp("WingCreature"); // alas sängyltä ja otuksen luo: otus herää
await page.waitForTimeout(4000);
await tapProp("WingCreature"); // otus lentää
await page.waitForTimeout(1800);
await page.screenshot({ path: out.replace(".png", "-fly.png") });
await page.waitForTimeout(3000);
// Kamera on lähellä hahmoa, joten yövalo voi olla ruudun ulkopuolella: kävellään ensin oikealle.
await iphoneTap(page.viewportSize().width * 0.85, page.viewportSize().height * 0.7);
await page.waitForTimeout(2500);
await tapProp("SheepLight");   // lammasyövalo: yö
await page.waitForTimeout(4500);
await page.screenshot({ path: out.replace(".png", "-night.png") });
// Aamu takaisin ja lemmikin silitys.
await tapProp("SheepLight");
await page.waitForTimeout(3500);
await tapProp("Pet");
await page.waitForTimeout(3000);
await page.screenshot({ path: out.replace(".png", "-pet.png") });
// Vaatekaappi: paitanappi avaa valikon, pyjaman kuva pukee hahmon, napautus muualle sulkee.
// Mikään näistä napautuksista ei saa liikuttaa hahmoa.
const tapsBeforeWardrobe = logs.filter((l) => l.startsWith("napautus ")).length;
const tapNamed = async (name) => {
  const p = (await page.evaluate(() => window.kotiPeliProps || {}))[name];
  if (!p) { console.log(`VIRHE: ${name} ei näy ruudulla`); return false; }
  const vp = page.viewportSize();
  await iphoneTap(p[0] * vp.width, p[1] * vp.height);
  await page.waitForTimeout(600);
  return true;
};
await tapNamed("Wardrobe");
await tapNamed("Wear_pajamas");
await page.screenshot({ path: out.replace(".png", "-wardrobe.png") });
await iphoneTap(page.viewportSize().width * 0.5, page.viewportSize().height * 0.3);
await page.waitForTimeout(600);
const wardrobeTaps = logs.filter((l) => l.startsWith("napautus ")).length - tapsBeforeWardrobe;
await browser.close();
server.close();

const png = PNG.sync.read(fs.readFileSync(out));
const px = (x, y) => { const i = (png.width * y + x) * 4; return [png.data[i], png.data[i + 1], png.data[i + 2]]; };
const center = px(Math.floor(png.width / 2), Math.floor(png.height / 2));
const corner = px(png.width - 5, 5);
const bottom = px(Math.floor(png.width / 2), png.height - 5);
console.log(`keskikohta ${center}, yläkulma ${corner}, alareuna ${bottom}`);
const diff = (a, b) => a.reduce((s, v, i) => s + Math.abs(v - b[i]), 0);
if (diff(center, corner) < 30) {
  console.log("VIRHE: ruudun keskellä näkyy vain taustaväri, 3D-kohtaus ei piirry");
  process.exit(1);
}
const taps = logs.filter((l) => l.startsWith("napautus "));
if (taps.length < 3) {
  console.log("VIRHE: napautukset eivät menneet peliin asti");
  process.exit(1);
}
const tricks = logs.filter((l) => l.startsWith("temppu "));
const count = (name) => tricks.filter((l) => l.startsWith(`temppu ${name} `)).length;
console.log(`temput: ${tricks.join(", ")}`);
if (!logs.some((l) => l.trim() === "lemmikki valittu cat") || tapsBeforeGame > 0) {
  console.log("VIRHE: lemmikin valinta ei toiminut kosketuksella");
  process.exit(1);
}
if (!logs.some((l) => l.trim() === "hahmo valittu girl")) {
  console.log("VIRHE: hahmon valinta (tyttö) ei toiminut kosketuksella");
  process.exit(1);
}
if (!logs.some((l) => l.trim() === "vaatteet girl pajamas") || wardrobeTaps > 0) {
  console.log(`VIRHE: vaatekaappi ei toiminut kosketuksella (napautuksia peliin ${wardrobeTaps})`);
  process.exit(1);
}
if (!logs.some((l) => l.startsWith("silitys cat"))) {
  console.log("VIRHE: lemmikin silitys ei toiminut");
  process.exit(1);
}
if (count("Bed") < 1 || count("WingCreature") < 2 || count("SheepLight") < 1) {
  console.log("VIRHE: esineiden temput eivät käynnistyneet kosketuksella");
  process.exit(1);
}
console.log("SELAINTESTI OK: 3D-kohtaus piirtyy, hahmon ja lemmikin valinta, vaatekaappi, napautukset, temput ja silitys toimivat");
