// Headless-Chromium screenshot for visually inspecting local web pages (esp. the
// three.js asset viewer's WebGL canvas, which curl/WebFetch cannot render).
//
// Single:  node shot.mjs --url <URL> --out <PNG> [--width N --height N --wait MS --selector CSS --full]
// Batch:   node shot.mjs --batch <jobs.json>   # [{ "url": "...", "out": "...png" }, ...]  (one browser, fast skim)
//
// WebGL is forced through ANGLE/SwiftShader so it renders in headless mode.
import { chromium } from 'playwright'
import { parseArgs } from 'node:util'
import { readFileSync } from 'node:fs'

const { values } = parseArgs({
  options: {
    url: { type: 'string' },
    out: { type: 'string' },
    batch: { type: 'string' }, // JSON file: [{url, out}, ...]
    width: { type: 'string', default: '1600' },
    height: { type: 'string', default: '1000' },
    wait: { type: 'string', default: '3500' }, // ms to settle after load (WebGL needs a few frames)
    selector: { type: 'string' }, // optional element to wait for before the settle
    full: { type: 'boolean', default: false },
    canvas: { type: 'boolean', default: false }, // screenshot only the <canvas> (clean mesh thumb, no UI)
  },
})

const jobs = values.batch
  ? JSON.parse(readFileSync(values.batch, 'utf8'))
  : values.url && values.out
    ? [{ url: values.url, out: values.out }]
    : null

if (!jobs) {
  console.error('usage: node shot.mjs --url <URL> --out <PNG> [opts]   |   --batch <jobs.json>')
  process.exit(2)
}

const browser = await chromium.launch({
  headless: true,
  args: ['--use-gl=angle', '--use-angle=swiftshader', '--ignore-gpu-blocklist', '--enable-webgl', '--no-sandbox'],
})
const page = await browser.newPage({
  viewport: { width: Number(values.width), height: Number(values.height) },
  deviceScaleFactor: 1,
})

for (const job of jobs) {
  const errors = []
  const onErr = (m) => { if (m.type?.() === 'error') errors.push(m.text()) }
  page.on('console', onErr)
  page.on('pageerror', (e) => errors.push(String(e)))
  await page.goto(job.url, { waitUntil: 'networkidle', timeout: 60000 }).catch((e) => console.error('goto warning:', e.message))
  if (values.selector) {
    await page.waitForSelector(values.selector, { timeout: 30000 }).catch(() => console.error('selector not found:', values.selector))
  }
  await page.waitForTimeout(Number(values.wait))
  if (values.canvas) {
    const cv = page.locator('canvas').first()
    await cv.screenshot({ path: job.out }).catch(async () => { await page.screenshot({ path: job.out }) })
  } else {
    await page.screenshot({ path: job.out, fullPage: values.full })
  }
  console.log('wrote', job.out, errors.length ? `(page errors: ${errors.slice(0, 3).join(' | ')})` : '')
  page.removeListener('console', onErr)
}
await browser.close()
