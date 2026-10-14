import { readFile } from 'node:fs/promises'
import assert from 'node:assert/strict'
import test from 'node:test'
import ts from 'typescript'

const source = await readFile(new URL('../src/lib/cardViewSettings.ts', import.meta.url), 'utf8')
const { outputText } = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.ESNext } })
const { getCardViewSettings, setCardViewOverride } = await import(`data:text/javascript;base64,${Buffer.from(outputText).toString('base64')}`)
const settings = {
  card_show_size: false, card_show_time: true, card_blur_path: true,
  card_show_path: false, card_show_tags: true, card_show_last_opened: false,
  card_show_play: false, card_show_console: true,
}

test('all views inherit global visibility and privacy settings', () => {
  const expected = { show_size: false, show_time: true, blur_path: true, show_path: false, show_tags: true, show_last_opened: false, show_play: false, show_console: true }
  for (const view of ['list', 'grid', 'kanban']) assert.deepEqual(getCardViewSettings(settings, view), expected)
})

test('a partial override affects only the chosen setting and view', () => {
  const next = setCardViewOverride(settings, 'grid', 'show_size', true)
  assert.equal(getCardViewSettings(next, 'grid').show_size, true)
  assert.equal(getCardViewSettings(next, 'grid').show_path, false)
  assert.equal(getCardViewSettings(next, 'grid').blur_path, true)
  assert.deepEqual(getCardViewSettings(next, 'kanban'), getCardViewSettings(settings, 'kanban'))
  assert.equal(settings.card_view_overrides, undefined)
})

test('editing list defaults preserves per-view overrides', () => {
  const original = setCardViewOverride(settings, 'kanban', 'show_tags', false)
  const next = setCardViewOverride(original, 'list', 'show_play', true)
  assert.equal(getCardViewSettings(next, 'grid').show_play, true)
  assert.equal(getCardViewSettings(next, 'kanban').show_tags, false)
  assert.equal(original.card_show_play, false)
})
