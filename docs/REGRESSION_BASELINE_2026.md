# Regression Baseline / Test Strategy 2026

Baseline: `236cbfda11c3b45faba4a6bf8e3c7e30cccd5a31`, 08.09.2026. Документ проектирует доказательство сохранности существующего reusable core. Test framework, fixtures, goldens и runtime tests в этой задаче не добавляются. Наличие стратегии не означает, что проверки уже выполнены.

## Принципы сравнения

1. Сначала фиксируется **одинаковый normalized input**, затем сравниваются CURRENT и изменённый компонент. Нельзя объявить regression результатом изменения входной schema/storage.
2. Pure/structural поведение проверяется unit assertions; raster fidelity — dimensions/metadata плюс perceptual/pixel diff. Exact PNG bytes используются только после доказательства deterministic encoding.
3. Expected baseline не должен закреплять известную ошибку как желаемую спецификацию. Для такого case хранятся два ожидания: `observed baseline` и `target requirement`, а изменение разрешается отдельным решением.
4. External fixtures должны быть copied/synthetic и работать без production Figma/B2/Yandex. Live integration запускается отдельно на test account/root.
5. Каждый golden связывается с source fixture, font hashes, renderer/library/runtime versions и tolerances. Обновление golden требует review причины, а не автоматической перезаписи.
6. Failure paths равноправны success paths: missing asset, corrupt bytes, timeout, stale cache, partial write и повторный запрос должны давать проверяемый результат.

## Reusable Core: characterization map

### 1. Universal renderer

| Аспект | Baseline contract / стратегия |
| --- | --- |
| Что делает сейчас | `renderUniversalTemplate` строит computed layout из Figma-shaped snapshot, рендерит fills/assets/photos/text/masks/opacity и композитит PNG. Есть HUG/FILL/FIXED, constraints и dynamic text containers. |
| Критичные входы | Frame tree/bounds, stable node IDs/names, assetsMap/object keys, fields, richText, textSizeAdjust, prepared photo keys, local Gotham files. |
| Критичные выходы | Ненулевой PNG ожидаемых dimensions; положение/размер/порядок/opacity/mask слоёв; использованные fields/assets; явные ошибки критичных ресурсов. |
| Edge cases | Nested constraints, fractional/negative geometry, transparent fills, rounded masks, missing optional/required asset, unsupported node, several image layers, long text, Cyrillic, debug on/off. |
| Regression risks | Изменение z-order, layout rounding, silent skip, font substitution, crop shift, другое wrapping, IO refactor меняет asset identity. |
| Автоматически | Parse PNG, dimensions/nonzero/alpha bounds; structural LayoutTree/computed boxes; deterministic debug summary; thresholded pixel diff. |
| Visual/golden | Representative template каждого реального layout class, masks/opacity, text+photo composition и missing-asset UI/output decision. |
| External dependencies | CURRENT: B2 snapshot/assets/uploads и local fonts; Figma REST не нужен main universal render после snapshot. |
| Unit tests | Geometry sanitization, alignment, sizing modes, editable lookup, typography resolution, layer ordering helpers после выделения seams. |
| Integration tests | Snapshot/package + fake provider → PNG; затем isolated real-provider read. Golden before/after asset resolver/model adapter. |

### 2. Sharp pipeline и image transforms

| Аспект | Baseline contract / стратегия |
| --- | --- |
| Что делает сейчас | Decode/crop/resize/encode/mask/opacity/composite для local/photobank photos и layers. |
| Критичные входы | MIME/bytes, source dimensions/orientation, normalized crop, target width/height, mask radii, opacity и output format. |
| Критичные выходы | Валидный PNG/JPEG/WebP buffer, точные target dimensions, ожидаемый crop region/alpha и отсутствие пустого результата. |
| Edge cases | 1×N/N×1, huge dimensions, corrupt bytes, MIME mismatch, EXIF orientation, crop boundary/rounding, alpha, extreme aspect ratio, zero/NaN geometry. |
| Regression risks | Crop off-by-one, unintentional upsampling, orientation mismatch preview/original, memory spike, changed encoder pixels/metadata. |
| Автоматически | Metadata/dimensions/channels; sampled pixels; crop mapping; decode rejection; max resource behavior. |
| Visual/golden | Checkerboard/coordinate image, portrait with EXIF, rounded mask, semi-transparent overlap, cover behavior. |
| External dependencies | Нет для synthetic buffers; CURRENT route fetch/storage layer external. |
| Unit tests | Normalized crop→pixel rect, clamp, target fit, MIME normalization and chosen encoder. |
| Integration tests | File/photobank prepared photo → provider object → renderer layer; resource/error limits on isolated data. |

### 3. Text layout

| Аспект | Baseline contract / стратегия |
| --- | --- |
| Что делает сейчас | Загружает TTF через opentype, измеряет text, переносит words/long words, считает metrics и строит SVG glyph paths. Engine применяет template/base size и line height. |
| Критичные входы | Font bytes/path/weight, Cyrillic string, fontSize, lineHeight, letterSpacing, maxWidth/maxLines/alignment. |
| Критичные выходы | Lines, widths/metrics, glyph path positions, block bounds и overflow decision. |
| Edge cases | Empty/whitespace, newline, one long word, punctuation, non-breaking spaces, emoji/missing glyph, Cyrillic, combining marks, narrow width, fractional size. |
| Regression risks | Measurement differs from rendered paths, kerning changes at rich boundaries, wrap changes, clipping/truncation accepted silently, font Promise caches failure. |
| Автоматически | Expected line arrays and numeric metrics with tolerance; overflow flag; path bounding box; no NaN. |
| Visual/golden | Cyrillic headings, long word, multi-line alignments, nonzero letterSpacing, different weights and dynamic pill. |
| External dependencies | Local approved TTF only; no B2/Figma for pure functions. |
| Unit tests | `measureTextPx`, `getFontMetricsPx`, `wrapTextByWords`, `truncateLines`, typography mapping. |
| Integration tests | Same normalized text passed to validator and renderer; font registry/package loading; PNG text region diff. |

### 4. Rich text

| Аспект | Baseline contract / стратегия |
| --- | --- |
| Что делает сейчас | Pure helpers normalize/slice/color/replace/reconcile `{text,color}` runs; UI uses contenteditable/plain paste; renderer wraps colored segments. |
| Критичные входы | Plain text, runs, selection start/end, insertion color, fallback/allowed color, edits across run boundaries. |
| Критичные выходы | Plain text identity, normalized adjacent runs, preserved unaffected colors, correct colored glyph groups/wrapping. |
| Edge cases | No selection, full selection, boundary selection, delete/paste, empty runs, invalid colors, surrogate pairs/emoji, IME/composition, undo, run inside word. |
| Regression risks | UTF-16 offsets split glyphs, color moves after edit, adjacent runs change kerning/wrap, validator sees plain text while renderer sees longer runs. |
| Автоматически | Table-driven run transformations, invariants `join(runs.text)==plain`, idempotent normalization, allowed palette rejection. |
| Visual/golden | One word with two colors, run boundary at wrap, whole-string recolor, mixed Cyrillic/punctuation. |
| External dependencies | Нет для pure helpers; DOM behavior требует browser; font rendering uses local font. |
| Unit tests | Все exports `richTextSegments.ts` и token/wrap logic `richTextLayout.ts`. |
| Integration tests | Editor DOM edit→request payload→validator→renderer; composition/selection browser cases. |

### 5. Crop state и geometry

| Аспект | Baseline contract / стратегия |
| --- | --- |
| Что делает сейчас | Client хранит local draft и confirmed normalized crop; source replacement сбрасывает crop своего slot; server converts normalized region and extracts via sharp. |
| Критичные входы | Source identity/dimensions/orientation, photoBox aspect, zoom/position, cropNorm, active field. |
| Критичные выходы | Crop относится к правильному source/slot, cancel восстанавливает state, confirmed rect совпадает на preview и original. |
| Edge cases | Replace source, cancel/reopen, several slots, extreme zoom, edges, resize viewport, preview and original different resolution/orientation. |
| Regression risks | Crop другого slot, stale crop после replace, normalized drift/rounding, optimized preview differs from original. |
| Автоматически | Pure coordinate conversions, state transition table, per-slot reset rules, rect bounds. |
| Visual/golden | Coordinate-grid source в template mask; reopen/cancel; portrait EXIF; rounded slot. |
| External dependencies | react-easy-crop/browser; photobank preview/original and server sharp for end-to-end. |
| Unit tests | Crop rect math/state reducer после выделения pure boundary. |
| Integration tests | Browser crop confirmation + server output on synthetic file; photobank on isolated fixture server. |

### 6. Schema extraction и layout normalization

| Аспект | Baseline contract / стратегия |
| --- | --- |
| Что делает сейчас | Recursive visible traversal; `text*`/`photo*` identification; fields ordering и photoBounds. `buildLayoutTree` нормализует Figma-shaped nodes/styles/constraints. |
| Критичные входы | Node visibility/type/name/id/bounds, parent hierarchy, fills/radii/constraints/sizing, duplicate names/missing IDs. |
| Критичные выходы | Stable fields/kinds/order/geometry и LayoutTree/byId без потери required nodes. |
| Edge cases | Hidden parent, hidden child, duplicate keys, nested editable node, missing bounds/id, unsupported fill/type, fractional geometry. |
| Regression risks | Field исчезает/меняет key/order, geometry forms расходятся, random ID делает fixture nondeterministic, unsupported node silently downgraded. |
| Автоматически | Structural JSON snapshots, explicit validation errors, tree invariants, deterministic IDs for fixtures. |
| Visual/golden | Только когда normalized tree идёт в renderer; сам extractor сравнивать structural JSON. |
| External dependencies | Нет для copied JSON; live Figma только для exporter/inventory POC. |
| Unit tests | `extractSchemaFields`, `buildLayoutTree`, editable-kind and container helpers. |
| Integration tests | Exported/copied design JSON → package schema → runtime normalized model → representative render. |

### 7. Generation logic

| Аспект | Baseline contract / стратегия |
| --- | --- |
| Что делает сейчас | Route parse→validate→resolve sources→crop→upload prepared images→render→store result→signed URL; имеет JSON/multipart и legacy/universal branches. |
| Критичные входы | templateId, fields/richText/textSizeAdjust, files/photoRefs/photoEdits, schema/frame snapshots, env flags. |
| Критичные выходы | Stable success/error API shape, one valid nonzero PNG reference, correct source-slot mapping, no success before complete write. |
| Edge cases | Missing required field/photo, arbitrary object key, corrupt file, rich/plain mismatch, renderer missing asset, upstream timeout, failure after upload, duplicate request. |
| Regression risks | Validation/render divergence, orphan uploads, state accepted by one input mode only, duplicate mutations, technical errors/secrets leak. |
| Автоматически | Request parsing/normalization/error codes with fakes; same input to validation/render; output buffer checks. |
| Visual/golden | Final PNG per representative template and error state preservation in editor. |
| External dependencies | CURRENT B2/Yandex and optional legacy Figma; future tests inject fake provider first. |
| Unit tests | Parsers, MIME/crop normalization, validation orchestration after extracting pure functions. |
| Integration tests | Route + fake provider/snapshot; isolated storage success/failure; no production writes. |

### 8. Caching

| Аспект | Baseline contract / стратегия |
| --- | --- |
| Что делает сейчас | Generic byte/count/TTL LRU с in-flight dedupe; separate stale `memoryCache`; photobank caches; font Promise Map. |
| Критичные входы | Key/version, TTL, size, loader outcome, time, invalidate/clear and concurrent callers. |
| Критичные выходы | Correct hit/miss/value, bounded count/bytes, no stale generation after commit, retry after loader failure. |
| Edge cases | TTL boundary, zero/oversized entry, pending clear, two callers, rejected loader, stale fallback, expired signed URL, multi-instance. |
| Regression risks | Old loader repopulates cache, indefinite stale, cache URL expires before entry, failure permanently memoized, mutation invisible across instances. |
| Автоматически | Fake clock, deterministic concurrent promises, snapshot stats, generation/version invalidation. |
| Visual/golden | Не требуется; broken preview/download проявляется integration/E2E. |
| External dependencies | Нет для LRU unit; instance topology/provider needed for coherence tests. |
| Unit tests | LRU get/set/evict/TTL/dedupe/clear race; memory cache stale policy; failed font loader retry. |
| Integration tests | Publish new manifest while reads pending; two app instances or coherence adapter; signed URL refresh. |

### 9. Photobank domain/pure logic

| Аспект | Baseline contract / стратегия |
| --- | --- |
| Что делает сейчас | Normalizes path/cache keys, maps public Yandex resources to folders/images, filters by MIME, paginates and resolves preview/download href. UI selects one active slot. |
| Критичные входы | Root/path, offset/limit, embedded resources, MIME, preview/original href, active photo field. |
| Критичные выходы | Confined normalized path, stable page/cursor, supported image list, source identity and correct slot assignment. |
| Edge cases | Mixed unsupported files, filtered pagination, empty folder, duplicate page, Unicode names, redirect/timeout, image MIME generator cannot decode. |
| Regression risks | Offset stalls/skips, path escape, preview-original mismatch, unbounded response, selecting one slot overwrites another. |
| Автоматически | Mapping/filter/cursor/path fixtures; supported MIME registry; selection state. |
| Visual/golden | M1/M2 tree/grid/empty/error later; current modal screenshots can be historical references. |
| External dependencies | CURRENT public Yandex API; future OAuth/private adapter requires isolated account. |
| Unit tests | Extract/normalize pure mapping from transport, cursor math, MIME and source ID. |
| Integration tests | Stubbed provider pages/timeouts/retries; later private Yandex test root. |

### 10. Template/package processing (FUTURE boundary around reusable extraction)

| Аспект | Baseline contract / стратегия |
| --- | --- |
| Что делает сейчас | Admin sync extracts visible TPL frames/assets/schema directly into active B2 snapshots; package.zip/import/manifests отсутствуют. |
| Критичные входы | Single/multiple design frames, schema version, complete asset/font set, stable IDs, existing active version. |
| Критичные выходы | FUTURE: deterministic package entries, hashes/count, validation report, staged inactive version, atomic activation. |
| Edge cases | One invalid package in N, duplicate ID, missing asset/font, unsupported node, path traversal, oversized archive, retry after partial remote failure. |
| Regression risks | Existing valid template becomes incomplete, partial catalog publish, ID drift, B2 fallback masks missing migrated data. |
| Автоматически | ZIP entry allowlist/path/ratio/count; manifest JSON schema; deterministic export structure; transaction fault matrix. |
| Visual/golden | Exported package must render equal to approved/current reference before activation. |
| External dependencies | Figma exporter side; provider for staging/commit; neither should be required by ordinary render test. |
| Unit tests | Manifest/index parser, package validator, hash, path rules, reconciliation. |
| Integration tests | Export→validate→stage→confirm→commit→rebuild; N package atomicity; two writers; B2 migration rehearsal. |

## Минимальный fixture / golden catalog

Идентификаторы ниже предназначены для будущего test repository. Source data должны быть synthetic либо legally approved copies. Ни один fixture сейчас не создан.

| Case | Источник входных данных | Expected result | Golden PNG | Основное сравнение |
| --- | --- | --- | --- | --- |
| G01 text-only | Minimal synthetic normalized frame + approved local test font | Ненулевой PNG, exact canvas, один text block | Да | dimensions, alpha bounds, pixel diff; structural JSON lines/boxes |
| G02 Cyrillic weights/alignment | Synthetic strings + regular/medium/bold font files | Correct left/center/right placement and weight | Да | metrics tolerance, pixel diff, font hashes |
| G03 long word/wrap | Fixed narrow text box, Cyrillic long word/punctuation/newlines | Stable line array; explicit overflow result | Да | structural lines/overflow + pixel diff |
| G04 rich text | Runs with two colors inside word and across wrap | Plain identity and correct colored glyph spans | Да | normalized runs, paths/groups, pixel diff |
| G05 text size levels | Same template at -1/0/+1 baseline and future configurable levels | Expected typography mapping and layout response | Да для baseline trio | structural size/boxes + pixel diff; future expectation separately versioned |
| G06 photo cover | Coordinate-grid JPEG/PNG + known slot | Correct center/cover region and dimensions | Да | dimensions, sampled pixels, pixel diff |
| G07 crop edges | Coordinate-grid source + normalized corner/center crops | Exact bounded source rect, no neighboring pixels | Да | crop rect structural + pixel diff |
| G08 EXIF portrait | Synthetic/approved oriented JPEG and normalized preview | Preview/original orientation contract explicit | Да | metadata/orientation, dimensions, pixel diff |
| G09 multiple image layers | Frame with background/logo/photo/sticker/marks | Correct z-order, opacity and each layer present | Да | layer debug JSON + pixel diff |
| G10 masks/rounded/alpha | Synthetic checkerboard in rounded photo slot | Expected transparent corners/opacity | Да | alpha samples/histogram + pixel diff |
| G11 missing required asset | Package references absent required logo | Explicit validation/render error, no downloadable success | Нет | error code/API response, no result object |
| G12 optional/unsupported node | Marked optional asset and one unsupported class | Policy-driven warning or hard error, never silent ambiguity | Только если output разрешён | validation report + structural JSON |
| G13 nonstandard canvas | Wide, tall and odd/fractional source geometry | Exact declared integer output dimensions, bounded layers | Да | dimensions, boxes, pixel diff |
| G14 schema traversal | Nested visible/hidden/duplicate/missing-ID node tree | Deterministic fields/errors/order | Нет | exact structural JSON |
| G15 cache concurrency | Fake clock/loaders, pending read + invalidate + new generation | Старое значение не возвращается как current | Нет | values/stats/call order |
| G16 generation API | Multipart/normalized JSON with fake provider and G01/G06 | Stable success keys/status; same validation input | Да через G01/G06 | API response schema, stored key/content hash, PNG checks |
| G17 generation failure cleanup | Failure injected after each write | No false success; bounded orphan/recovery record | Нет | provider operation log/state/API error |
| G18 photobank pagination | Stub pages with folders, supported/unsupported files, duplicates | Stable cursor/no skip/stall, supported items only | Нет | structural page JSON/source IDs |
| G19 exporter package single/N (FUTURE) | Approved representative Figma copies | Deterministic valid package(s), complete manifest/assets | Rendered goldens per family | ZIP entries/hash/manifest + render diff |
| G20 target multi-format (FUTURE) | Approved family with 1–5 adaptations/common content | Independent geometry/crops/status and exact complete ZIP | Да per adaptation | structural state, files/count/names, pixel diff, API response |
| G21 print A4/A5 (FUTURE) | Approved physical template, ICC, font policy, photos near PPI boundary | Preflight pass/fail and valid print PDF | Reference PDF/raster preview | page/trim/bleed boxes, OutputIntent/colorspace/fonts/PPI; visual proof |

Exact bytes не используются как единственный raster criterion: PNG chunks, compression и metadata могут измениться при одинаковых pixels. Сначала POC G01/G06/G09 повторяется несколько раз на закреплённой среде. Если bytes детерминированы, hash может быть быстрым first gate; при mismatch всё равно анализируются decoded dimensions/pixels и metadata. Pixel diff должен хранить threshold и generated diff image; значение threshold не выбирается до D08.

## Existing reference candidates

`assets/screens` содержит historical candidates, которые нельзя менять или автоматически принять за TARGET goldens:

- `Страница выбора шаблонов 1.png`, `Страница выбора шаблонов 2.png` и loading/error screenshots — current catalog states;
- `Страница шаблона 1.png` … `Страница шаблона 12 ...png` — editor, readiness, preview loading и crop states;
- `Окно фотобанка 1.png` … `Окно фотобанка 4.png` — current photobank interaction;
- `UI kit ...png` — current field/photo/color/size/back/right-action elements.

Они полезны как visual history и для поиска крупных unintended regressions до новой Figma. Перед использованием нужно подтвердить: источник/дата, соответствующий commit/data, viewport, шрифты, отсутствие устаревших ожиданий и права хранения. После утверждения новой Figma CURRENT screenshots и TARGET references должны храниться как разные наборы.

Для output renderer готовых canonical PNG в tracked дереве не обнаружено: screenshots интерфейса не доказывают точность generated file. Первые renderer goldens должны создаваться из controlled fixtures после отдельного review.

## Future test matrix

`FUTURE` означает компонент/сценарий TARGET ещё не реализован. Это не failed test.

| Test area | Unit | Integration | Visual/Golden | E2E | External dependency |
| --- | --- | --- | --- | --- | --- |
| Renderer | Geometry/layout/helpers | Package/snapshot + fake provider → PNG | Обязательно G01–G13 | Generate→preview/download после safe test storage | Current B2 only for legacy integration; future provider adapter |
| Text layout | Metrics/wrap/truncate/overflow | Validator and renderer share normalized input/font registry | Обязательно Cyrillic/spacing/weights/align | Editor text→render | Local font; approved font package FUTURE |
| Rich text | Run transformations/invariants | DOM payload→validation→render | Обязательно colored runs/wrap | Selection/paste/edit/generate | Browser + local font |
| Crop | Coordinate/state transitions | Browser state→server sharp output | Coordinate-grid/EXIF/masks | Select/replace/cancel/confirm | Browser; photobank provider only for external variant |
| Image processing | Decode/MIME/dimensions/crop/mask | File/source resolver→prepared layer | Обязательно cover/alpha/orientation | Upload/crop/generate on test storage | sharp native runtime |
| Schema extraction | Traversal/key/order/validation | Exported/copy JSON→normalized package | Через renderer representative cases | Import form fields after activation | Figma only for approved exporter POC |
| Template import | FUTURE manifest/ZIP/path/hash/state reducers | FUTURE stage/atomic commit/rebuild/faults | FUTURE render every imported family | FUTURE admin single/N reports | Test provider; Figma exporter artifact |
| Storage | Provider contract/path/error/retry fakes | Adapter against isolated root; concurrency/faults | Не требуется | Admin/import/generated flows FUTURE | Private Yandex OAuth FUTURE; transitional B2 |
| Photobank | Mapping/path/cursor/MIME/selection | Stub provider + isolated OAuth root FUTURE | Current M1 candidates; M1/M2 TARGET FUTURE | Browse/select/back/error/retry | Public Yandex current; private Yandex FUTURE |
| Generation | Parse/normalize/validation/error | Route + fake provider/renderer and output gate | Final PNG G01/G06/G09 | Editor→result without production writes | Provider; no Figma in TARGET |
| Target | FUTURE family/sizeLevel/crop/state | FUTURE 1–5 bounded renders/partial retry/ZIP | FUTURE per-adaptation goldens | FUTURE full target editor flow | Approved packages; provider |
| Print/PDF | FUTURE PPI/boxes/preflight rules | FUTURE PDF engine + inspector/profile/fonts | FUTURE A4/A5 proof | FUTURE editor→preflight→download | ICC/profile/fonts/print process |
| Admin | Auth/session/rate-limit/state pure logic FUTURE | FUTURE provider/import/health/cleanup with failures | FUTURE approved dashboard states | FUTURE login/import/manage/cleanup/accessibility | OAuth/provider/runtime health; never production in CI |

## Minimal pre-refactor regression gate

До изменения каждого reusable компонента должны существовать либо быть утверждены:

1. Baseline commit и exact source fixtures, которые выполняются без production writes.
2. Characterization cases для затронутых pure functions и хотя бы один success + один failure integration case.
3. Для raster changes — representative golden до изменения, pinned fonts/runtime и согласованный diff method.
4. Для IO boundary — fake provider operation log и fault after every write/read boundary.
5. Явный список known baseline defects: ожидаемое исправление нельзя смешивать с unintended regression.
6. Повтор `next build`, lint/test status и browser route smoke из `RUNTIME_BASELINE_2026.md`.

Пока tests не реализованы, этот документ определяет coverage, но не разрешает renderer/storage refactor. Реализация test harness относится к будущему plan после прохождения PRE-CODE GATE и не должна начинаться скрыто в документационной ветке.
