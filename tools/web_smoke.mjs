// Avaa selainversion oikeassa selaimessa (Chromium), ottaa kuvakaappauksen ja
// tarkistaa, että ruudun keskellä näkyy jotain muuta kuin taustaväri.
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
const page = await browser.newPage({ viewport: { width: 844, height: 390 } });
page.on("console", (m) => console.log(`[selain ${m.type()}] ${m.text()}`));
page.on("pageerror", (e) => console.log(`[selain virhe] ${e.message}`));
await page.goto("http://localhost:8060/index.html");
await page.waitForTimeout(12000);
await page.screenshot({ path: out });
await page.mouse.click(422, 195);
await page.waitForTimeout(1000);
await page.screenshot({ path: out.replace(".png", "-tap.png") });
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
console.log("SELAINTESTI OK: 3D-kohtaus piirtyy");
