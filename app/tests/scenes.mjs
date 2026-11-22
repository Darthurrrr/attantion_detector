import assert from 'node:assert/strict'
import { spawn } from 'node:child_process'
import { existsSync } from 'node:fs'
import { resolve } from 'node:path'
import puppeteer from 'puppeteer-core'

// Нужен установленный Chrome/Chromium; CHROME_BIN позволяет указать другой путь.
const chrome = process.env.CHROME_BIN || ['/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser'].find(existsSync)
if (!chrome) throw new Error('Установите Chrome/Chromium или задайте CHROME_BIN')
const port = process.env.SCENE_TEST_PORT || '5188'
const url = `http://127.0.0.1:${port}/`
const vite = spawn(process.execPath, [resolve('node_modules/vite/bin/vite.js'), '--host', '127.0.0.1', '--port', port, '--strictPort'], {
  stdio: ['ignore', 'pipe', 'pipe'],
})
let viteLog = ''
vite.stdout.on('data', (data) => { viteLog += data })
vite.stderr.on('data', (data) => { viteLog += data })

const delay = (ms) => new Promise((done) => setTimeout(done, ms))
async function ready() {
  await new Promise((done, fail) => {
    const timeout = setTimeout(() => fail(new Error(`Vite не запустился:\n${viteLog}`)), 20000)
    const check = () => {
      if (/Local:\s+http/.test(viteLog)) {
        clearTimeout(timeout)
        done()
      }
    }
    vite.stdout.on('data', check)
    vite.on('error', fail)
    vite.on('exit', (code) => fail(new Error(`Vite завершился (${code}):\n${viteLog}`)))
    check()
  })
}

async function assertClickable(page, selector) {
  const result = await page.$eval(selector, (target) => {
    const box = target.getBoundingClientRect()
    const stage = document.querySelector('.stage').getBoundingClientRect()
    const x = box.left + box.width / 2
    const y = box.top + box.height / 2
    const hit = document.elementFromPoint(x, y)
    return {
      inside: box.width > 0 && box.height > 0 && box.left >= stage.left - 1 && box.right <= stage.right + 1 && box.top >= stage.top - 1 && box.bottom <= stage.bottom + 1,
      hit: hit === target || target.contains(hit),
      blocker: hit?.outerHTML.slice(0, 150),
    }
  })
  assert.ok(result.inside, `${selector} выходит за границы сцены`)
  assert.ok(result.hit, `${selector} перекрыт: ${result.blocker}`)
}

async function loaded(page, selector) {
  await page.waitForFunction((query) => {
    const images = [...document.querySelectorAll(query)]
    return images.length > 0 && images.every((image) => image.complete && image.naturalWidth > 0)
  }, {}, selector)
}

async function runScene(browser, { width, height, reduced = false }) {
  const context = await browser.createBrowserContext()
  const page = await context.newPage()
  const errors = []
  page.on('pageerror', (error) => errors.push(error.message))
  page.on('response', (response) => {
    if (response.status() >= 400 && response.url().includes('/assets/')) errors.push(`${response.status()} ${response.url()}`)
  })
  try {
    await page.setViewport({ width, height, deviceScaleFactor: 1 })
    if (reduced) await page.emulateMediaFeatures([{ name: 'prefers-reduced-motion', value: 'reduce' }])
    await page.goto(url, { waitUntil: 'domcontentloaded' })
    await page.waitForSelector('.home-hero__pet')
    const splash = await page.$('.splash')
    if (splash) await splash.click()
    await page.waitForFunction(() => !document.querySelector('.splash'))
    // Приветствие может появиться на следующем кадре или уже успеть скрыться.
    await page.waitForSelector('.toast', { timeout: 3000 }).catch(() => null)
    await page.evaluate(() => document.querySelectorAll('.toast').forEach((toast) => toast.click()))
    await page.waitForFunction(() => !document.querySelector('.toast'))
    await page.evaluate(() => document.fonts.ready)
    await loaded(page, '.scene-layers__island img, .home-hero__plants, .home-hero__pet img')
    await delay(380) // Закончить переход экрана, прежде чем измерять hit-test.

    const landscape = width > height && width >= 640
    const homeBackground = await page.$eval('.bg-layer--home', (e) => getComputedStyle(e).backgroundImage)
    assert.ok(homeBackground.includes(landscape ? 'meadow_landscape.webp' : 'meadow_portrait.webp'))
    assert.equal(await page.$eval('.scene-layers', (e) => e.getAttribute('aria-hidden')), 'true')
    assert.equal(await page.$eval('.home-hero__foreground', (e) => getComputedStyle(e).pointerEvents), 'none')
    const islandBefore = await page.$eval('.scene-layers__island', (e) => getComputedStyle(e).transform)
    await delay(250)
    const islandAfter = await page.$eval('.scene-layers__island', (e) => getComputedStyle(e).transform)
    if (reduced) assert.equal(islandBefore, islandAfter, 'остров не должен двигаться при reduced motion')
    else assert.notEqual(islandBefore, islandAfter, 'остров должен двигаться независимо')

    await assertClickable(page, '.home-hero__pet')
    await assertClickable(page, '.rail__btn:nth-child(4)')
    await assertClickable(page, '.home-play')
    await page.click('.home-hero__pet')
    await page.waitForSelector('.heart-pop')
    await page.click('.rail__btn:nth-child(4)')
    await page.waitForSelector('.summon-egg__image')
    await loaded(page, '.summon-crystal img, .summon-egg__image')
    await delay(380)

    const summonBackground = await page.$eval('.bg-layer--summon', (e) => getComputedStyle(e).backgroundImage)
    assert.ok(summonBackground.includes(landscape ? 'summon_landscape.webp' : 'summon_portrait.webp'))
    assert.equal(await page.$$eval('.summon-crystal', (els) => els.length), 2)
    assert.equal(await page.$eval('.summon-crystal', (e) => e.getAttribute('aria-hidden')), 'true')
    assert.equal(await page.$eval('.summon-crystal', (e) => getComputedStyle(e).pointerEvents), 'none')
    if (reduced) {
      const before = await page.$eval('.summon-crystal img', (e) => getComputedStyle(e).transform)
      await delay(250)
      const after = await page.$eval('.summon-crystal img', (e) => getComputedStyle(e).transform)
      assert.equal(before, after, 'кристаллы не должны двигаться при reduced motion')
    }
    await assertClickable(page, '.summon-info-btn')
    await assertClickable(page, '.summon-btn')
    await page.click('.summon-info-btn')
    await page.waitForSelector('[role="dialog"]')
    assert.match(await page.$eval('[role="dialog"]', (e) => e.textContent), /Правила призыва/)
    await page.keyboard.press('Escape')
    await page.waitForSelector('[role="dialog"]', { hidden: true })

    // Веб-прототип работает с изолированным localStorage тестового браузера.
    await page.click('.summon-btn')
    await page.waitForSelector('.reveal__skip')
    await page.click('.reveal__skip')
    await page.waitForSelector('.reveal.is-revealed .reveal-actions .btn')
    await delay(400)
    await page.click('.reveal-actions .btn')
    await page.waitForSelector('.reveal', { hidden: true })
    await page.click('.summon-link')
    await page.waitForSelector('[role="dialog"] .history-row')
    await page.keyboard.press('Escape')
    await page.waitForSelector('[role="dialog"]', { hidden: true })
    await page.click('.screen-header__back')
    await page.waitForSelector('.home-play')
    await page.evaluate(() => document.querySelectorAll('.toast').forEach((toast) => toast.click()))
    await delay(350)
    await page.click('.home-play')
    await page.waitForSelector('.screen.play')
    assert.deepEqual(errors, [], `ошибки браузера ${width}x${height}: ${errors.join('; ')}`)
    console.log(`✓ ${width}×${height}${reduced ? ' · reduced motion' : ''}: слои, управление, призыв и тренировка`)
  } finally {
    await context.close()
  }
}

let browser
try {
  await ready()
  browser = await puppeteer.launch({
    executablePath: chrome,
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu'],
  })
  for (const size of [
    { width: 320, height: 568 },
    { width: 390, height: 844 },
    { width: 640, height: 360 },
    { width: 844, height: 390 },
    { width: 1024, height: 768 },
    { width: 390, height: 844, reduced: true },
    { width: 844, height: 390, reduced: true },
  ]) await runScene(browser, size)
} finally {
  if (browser) await browser.close()
  vite.kill('SIGTERM')
}
