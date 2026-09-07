# Варианты миграции Cherkizovo Design Service 2026

Аудит 07.09.2026. CURRENT — `b6400a95e8e26bd35c4dbba6cff79c6c9e555f64`; TARGET — приложенное ТЗ v1.0 от 06.09.2026, все разделы 1–15 и приложения А–И. Документ показывает gaps, варианты сохранения/изменения механизмов и зависимости решений. Он не является финальной архитектурой или финальным implementation plan. `ARCHITECTURE_2026.md` на этом этапе не создаётся.

Главный вывод: текущий сервис уже имеет полезное автономное растровое ядро, читающее snapshots и assets из B2. Его не требуется заменять целиком ради отказа от production Figma. Основной объём миграции — изоляция хранения и Figma-shaped model, полный пакет/template lifecycle, пользовательские сценарии ТЗ, target orchestration и отдельная печатная подсистема. Ни один действующий storage object или runtime-файл этим аудитом не изменяется.

## Правила решений

Приоритет: reuse > improve > refactor > replace. KEEP — сохранить проверяемый механизм; KEEP + IMPROVE — сохранить и расширить/исправить; REFACTOR — сохранить поведение/ядро, изменить границы; REPLACE — заменить конкретный механизм из-за несовместимости; REMOVE — исключить из целевого runtime после замены сценария; ADD NEW — отсутствующий механизм; INVESTIGATE — решение требует данных/пробы. REPLACE/REMOVE не являются разрешением удалить legacy сейчас.

Доказательства текущего состояния и потоков: [ARCHITECTURE_CURRENT.md](ARCHITECTURE_CURRENT.md). Требования и статусы: [REQUIREMENTS_TRACEABILITY_2026.md](REQUIREMENTS_TRACEABILITY_2026.md). H/M/L ссылки ниже ведут по смыслу к [TECH_DEBT_2026.md](TECH_DEBT_2026.md).

## Migration map

| Подсистема | CURRENT | TARGET по ТЗ | GAP | Решение | Причина | Риск | Зависимости |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Next.js | App Router + nodejs APIs | Сохранить, §3.2 | Deployment runtime не закреплен | KEEP | Прямое соответствие стеку | Packaging native dependencies | Hosting/Node |
| React | Client pages/state/hooks | Shared user/admin components | Монолитные pages | KEEP | Framework менять не требуется | Lifecycle regressions при выделении | UI contracts |
| UI architecture | / каталог и /t/id, page-level state | Общий shell, categories/editors/modals, §6 | Нет нужного shell/routes | REFACTOR | Состояние/контролы пригодны, композиция и screen boundaries иные | Потеря state при navigation | Category/config, schema |
| Navigation | Нет постоянного меню | Config left nav, UX-NAV-01…04 | Все основные переходы | ADD NEW | Нет механизма, который можно просто настроить | Nested route/state transitions | Category config |
| Home | Общий соцкаталог + red sidebar | Welcome EVP + request block, §6.4 | Иная роль корневого экрана | REPLACE | Прямое несовпадение назначения, а не оценка эстетики | Потерять доступ к catalog | New category routes; support URL |
| Category catalog | TemplateRail и name-based grouping | Shared categories, filters, exact aspect, §6.5 | Filters/status/integrity/empty | KEEP + IMPROVE | Preview click и карточки уже полезны | Signed URLs/large lists | Manifest/index/cache |
| Shared design system | SVG registry, CSS tokens, page-local controls | Общие nav/field/modal/error primitives, §6.2 | EVP palette/radii и компоненты неполны | REFACTOR | Сохранить рабочие primitives, разделить layout и tokens | Незаметные UI regressions | Approved EVP/assets |
| API layer | Next handlers; mixed payloads/errors | Server validation, source refs, protected admin, §7/11/13 | Нет общего validation/error/session contract | REFACTOR | Сохранить HTTP framework и orchestration, H07/H10 | Изменение existing client contracts | Schema, auth, storage |
| Template model | Figma frame + schema snapshots/name/page | package/template/manifest с version/category/status/fields/adaptations | Нет автономного service schema | REFACTOR | Геометрия и nodes пригодны через adapter | Зафиксировать legacy assumptions в v1 | Exporter coverage/inventory |
| Template schemas | `text*`/`photo*`, photoBounds/photoFields | Explicit keys/labels/permissions/required/fonts/colors, §5 | Naming rules и три формы geometry | REFACTOR | Извлечение можно сохранить на design side | Mislabel/duplicate fields | Versioned parser |
| Figma production runtime | Main path offline; legacy image miss и /api/figma/frame online | Ни одного обязательного user call, ARC-FIG-01 | Остаточные live branches | REMOVE | Прямой запрет ТЗ после импортирования | Нельзя убрать до полного покрытия assets | Package autonomy tests |
| Template Exporter | Server sync extraction only | Designer export single/multi ZIP, ARC-FIG-02 | Нет exporter deliverable | ADD NEW | Часть extraction reuse, продукта нет | Неподдержанные Figma nodes, fonts license | Schema v1, real families |
| Import pipeline | Sync writes active snapshots напрямую | Validate→stage→confirm→atomic package commit, §11.7 | Нет ZIP/staging/transaction | REPLACE | H03/H04; нельзя считать sync транзакцией | Partial remote failures/concurrency | Provider semantics, auth, schema |
| JSON manifests/index | Один templates.json, meta snapshot | Per-template source, rebuildable index/service state, §4 | Source-of-truth отличается | ADD NEW | JSON подход сохраняется, lifecycle отсутствует | Index/manifest consistency | Provider, commit policy |
| Backblaze B2 | Persistent storage через SDK | Исключить из конечной production схемы, §4.7 | Все основные writes в B2 | REPLACE | Прямое требование ТЗ | Потеря данных при раннем отключении | Сверка count/hash, контроль сценариев |
| StorageProvider | Нет; s3 helpers напрямую | Все 8 операций, §3.4 | Business связан с SDK | ADD NEW | Нужна граница, текущий B2 за adapter на переходе | Ошибочная унификация S3 semantics | ResourceInfo/error contracts |
| Яндекс Диск transport | public/resources photobank | YandexDiskStorage OAuth private API | Public-key transport не целевой | REPLACE | ARC-YD-01/02 | OAuth scope, redirects, quota, remote operation completion | Provider/path/retry policy |
| Photobank domain/UI state | Папки/pagination/proxy/single-slot | Private storage + M1 tree/M2/full states | Transport/UI layout/paging/format mismatch | KEEP + IMPROVE | Полезны browse results и slot selection | H09, M02/M03/M08 | Provider, modal, original metadata |
| Universal renderer | Snapshot→LayoutTree→layers→PNG | Autonomous package→renderers | Figma type/S3 imports/hardcoded rules | REFACTOR | Есть автономное растровое ядро; не нужна wholesale rewrite | Visual fidelity/missing assets | Normalized model, injected asset access |
| Sharp pipeline | Crop/resize/mask/opacity/composite | PNG + подготовка фото, §3.2 | Resource checks/EXIF/limits | KEEP + IMPROVE | Рабочие операции прямо нужны | Memory/quality regressions | Source validation, pixel budgets |
| Text rendering/layout | OpenType metrics, wrap, SVG paths, dynamic containers | Точная geometry/runs/overflow, §7.3 | Spacing/kerning/height/field policies | KEEP + IMPROVE | Математика пригодна; H07/H08/M05 требуют коррекции | Молчаливое clipping/изменение переносов | Golden templates/fonts |
| Rich text | Runs и editing helpers; integration only `text` | Per-field allowed color/whole/selection | Обобщение и одинаковые validator/render inputs | KEEP + IMPROVE | Pure helpers с низкой связанностью | UTF-16/edit/kerning edge cases | AllowedColors/schema, shared layout |
| Ordinary crop | cropNorm + react-easy-crop inline | M3 modal с template/slot, §6.9 | Layout, restore/focus, metadata | KEEP + IMPROVE | Сохранить normalized coordinates/cancel behavior | EXIF/preview-original mismatch | Image source identity, geometry |
| Validation | Client required + server line limits | Required/permissions/decode + exact layout | Not same payload, no full overflow | REFACTOR | Сохранить metrics, заменить критерии принятия | Неправильный accepted output | Shared normalized input/result |
| Generation | Синхронный PNG request, B2 temp/source/result | Social/print/target pipeline и повторная валидация | Storage coupling/state/budgets | REFACTOR | Orchestration pattern пригоден | Duplicate work/temp files | Provider, validators, renderers |
| Downloads | Signed B2 URL + window.open | Controlled PNG/PDF/ZIP выдача/retry | Expiry recovery/preflight/ZIP нет | REFACTOR | Сохранить выдачу result reference; транспорт меняется | Broken link/stale result | Generated registry/state, provider |
| Target multi-format | Один frame и scalar adjust | Family/adaptations, 1–5 previews/crops/results, §8 | Практически весь scenario | ADD NEW | Один PNG renderer лишь строительный блок | CPU/memory/partial failure | Schema, layout, bounded orchestration |
| Print editor/data | Нет | Dynamic fields, fixed physical template, §6.10/9 | Весь specialization | ADD NEW | Общую форму reuse, print metadata/output новые | False print-ready UX | Print engine/preflight |
| PDF renderer | Нет | CMYK + profile/fonts/boxes, §9.3 | Нет engine | INVESTIGATE | Выбор невозможен без print process и proofs | Engine не выполнит CMYK/profile/лицензии | ICC/profile/real A4/A5; затем ADD NEW |
| CMYK | RGBA PNG | CMYK итог, §9.3 | Color-managed PDF нет | ADD NEW | sharp PNG не подтверждает PDF CMYK | Неверный color conversion | ICC/OutputIntent/PDF engine |
| Effective PPI / 300 dpi | Cover px resize | Проверка source after crop/scale, §9.4 | Нет физической геометрии | ADD NEW | Upsampling не повышает исходное качество | False pass из-за resized dimensions | Physical slot size, threshold |
| Bleed/trim/safe | Frame px only | Boxes/template-controlled, §5.6/9.3 | Нет print boxes | ADD NEW | Требуемая печатная geometry | Неверный итоговый размер | Template print schema |
| Font embedding/conversion | SVG paths растеризуются в PNG | PDF fonts/embed/outline по лицензии | Нет PDF proof | INVESTIGATE | Не считать raster paths embedded font | Лицензии, glyph coverage, PDF validity | Brand files, выбранный PDF process |
| Preflight | Только line-limit check | PDF quality gate before URL, §9.3 | Реального preflight нет | ADD NEW | Обязательный критерий приемки | Некорректный файл скачивается | Print contract/independent inspection |
| Admin auth | Query token/header secret | Password→secure session/expiry/rate limit | Иной credential lifecycle | REPLACE | H02 и §11.2 | Auth regression и lockout | Environment/session policy |
| Admin dashboard | Sync counters | Measured checks/storage/stats/errors, §6.15 | Нет operational dashboard | ADD NEW | Sync status не health | Ложное green при ошибке | Health/provider/system state |
| Admin import | Full/single/dry buttons | ZIP single/multi reports/sticky confirmation | Нет target UI | REPLACE | §6.16 и отказ от sync | UI/transaction state disagreement | Import report/auth |
| Template management | Нет | Table/update/enable/disable/delete | Полный lifecycle | ADD NEW | Нет механизма для reuse | Partial mutation and stale cache | Manifests, index, auth |
| Health checks | Constant ok, sync meta | Six measured checks/timeouts/TTL | Нет измерений | KEEP + IMPROVE | Можно оставить liveness и добавить readiness checks | Heavy or stale health | Minimal PNG/PDF/loader probes |
| Caching | LRU TTL + simple Maps | Recoverable metadata/cache, coherent invalidation | Несвязанные cache levels/URL expiry | REFACTOR | LRU core пригоден, H05/H06/M14 | Multi-instance stale results | Mutation commit/version and URLs |
| Generated cleanup | Нет | Protected bounded delete/partial reporting | Нет админ-операции | ADD NEW | §11.5 прямо требует | Удаление вне generated | Provider path confinement/auth |
| Security | Частичные server checks, generic errors | §13.3 guarantees, safe inputs/URLs/secrets | H01/H02/H09/H10 и др. | KEEP + IMPROVE | Сохранить проверки, закрыть конкретные gaps | Невидимые external settings | Auth, provider, validation |
| Deployment | Generic Next, no tracked infra recipe | Portable российский runtime, §13.6 | Среда/limits/ownership неизвестны | INVESTIGATE | Не назначать hosting без требований | Native deps, long jobs/timeout/memory | Product infra decision, measured tests |

## REUSABLE CORE

Оценка качества ниже — по структуре и статическому пути, без утверждения, что существующие templates побитно совпадают с Figma. У библиотеки нет tracked golden fixtures и автоматического test suite. Сохранение кода допускается после проверки представительных реальных материалов.

| Механизм | Качество существующей реализации | Зависимости / связанность Figma и B2 | Отделимость и соответствие ТЗ | Решение и требуемые изменения |
| --- | --- | --- | --- | --- |
| Universal renderer | Реальная layer composition, masks, opacity, constraints, HUG/FILL/FIXED, text containers; хорошие точки reuse. Монолит 2114 строк; есть hardcoded special cases и silent asset skip. | FigmaNodeLite/figmaLayout; прямые s3 reads; manual-assets namespace; local Gotham map. Сам renderer не делает REST Figma. | Можно отделить input model/asset resolver. Соответствует растровой части, не print/PDF. | REFACTOR: сохранить layer/core geometry, выделить input normalization и asset access; unsupported/missing nodes не скрывать. Проверить golden output до/после. |
| Sharp pipeline | Crop→resize→mask→composite и конечный PNG уже есть. Буферы многократно материализуются, predecode/resource policy неполна. | sharp, source Buffer; IO находится рядом/выше в route и engine. | Операции отделимы как buffer transforms; §3.2 напрямую поддерживает sharp. | KEEP + IMPROVE: единый decode/metadata/orientation/limits, исходные размеры не терять до PPI проверки; не подменять sharp новым raster engine. |
| Text layout | OpenType metrics/word wrapping/line height и SVG glyph paths; dynamic pill two-pass. Нет полного height gate, letterSpacing measurement/output различаются. | textLayout зависит от fs/opentype, без B2/Figma; orchestration зависит от LayoutNode. | Pure metrics/wrap/path функции можно оставить, layout normalize разнести. | KEEP + IMPROVE: единые metrics для render/validation, glyph spacing/rich boundaries, явный overflow вместо truncate; tests длинных слов/кириллицы. |
| Rich text | Runs normalize/slice/apply/replace/reconcile, DOM textContent и plain paste; нет нужды переносить произвольный HTML. | Чистые helpers; UI React/DOM; renderer uses textLayout. Figma/B2 не нужны. | Хорошо отделим. Соответствует color-only model §7.4, но only text key и no-selection semantics неполны. | KEEP + IMPROVE: dynamic field keys, allowed palette, whole string color, spans across edits; undo/composition/UTF-16 и color-run wrapping проверить. |
| Crop | Нормализованные coordinates, local draft vs confirmed state, source replacement сбрасывает свой crop; no grid. | react-easy-crop, React source state; server sharp transform. Geometry из schema; transport source preview связан с photobank. | Math можно сохранить в M3/M4; standalone modal отсутствует, target completion new. | KEEP + IMPROVE: отделить view от math/source identity; restore/cancel; EXIF/optimized-original alignment; M4 orchestrator добавить сверху. |
| Schema extraction | Visible traversal + editable detection + photoBounds; прозрачный небольшой модуль 126 строк. Labels=names, нет unique-key/version/permissions validation. | Figma node shape и naming convention; сама extraction без IO. | Перенести на design/export side или transitional converter; не навязывать prefix rules целевому runtime. | REFACTOR: reuse traversal, explicit labels/order/fonts/palette/minPPI/print/adaptations; единая geometry schema вместо трех вариантов. |
| Template processing | buildLayoutTree нормализует styles/constraints/boxes и byId. Только SOLID fills, заданные node classes, fallback shape behavior. | Figma-shaped geometry, name-based editable, случайный ID при отсутствии ID. | Adapter может обеспечивать normalized scene input; package напрямую старым engine не читается. | REFACTOR: сравнить normalized scene adapter с transitional snapshot-compatible format; schema v1 не фиксировать до coverage inventory. |
| Generation API | Последовательность parse→validate→source→crop→render→store→URL уже есть; два input modes и legacy branches смешаны. | Env/B2/snapshot store/public photobank/universalEngine. | Orchestration сохраняется, endpoint business contract нужно унифицировать. | REFACTOR: normalize input один раз, проверять тот же rich text, источники/required fields, budgets/temp cleanup, errors/output gate. |
| Photobank | Nonrecursive browse, pagination/hasMore, proxy preview, single-slot selection. Нет M2/tree; offset bug при filtered items. | Public Yandex и getEnv→B2 dependency; LRU cache. | Domain DTO и selection reuse; transport заменить. | KEEP + IMPROVE: private provider, next cursor, supported MIME registry, timeouts/backoff, modal tree/single-photo preview. |
| Caching | LRU имеет count/bytes/TTL, in-flight dedupe, stats; полезен. Simple memoryCache unmanaged; clear race и слои invalidation разделены. | LRU generic, s3 wrapper B2; каталог кеширует signed URLs, fonts — Promise Map. | LRU отделим от provider. Кэш может оставаться полностью rebuildable, как требует §3.7. | REFACTOR: сохранить класс с исправлением pending invalidation; metadata separately from access URL; общее правило post-commit invalidation и instance coherence. |

Слабая связанность pure helpers — аргумент за reuse. Размер файла сам по себе не основание REPLACE: `universalEngine.ts` и editor page большие, но заменяются только несовместимые границы и доказанные дефекты. Отдельная PDF subsystem не означает отказ от PNG/text/crop foundations.

## Подробный GAP-анализ A–G

### A. Figma

**CURRENT.** Catalog/schema получают B2 snapshots; universal render читает frame and assets, не REST. Admin sync fetches full file/nodes/images и пишет snapshots. Legacy generate при отключённом universal и включённом USE_FIGMA_RENDER использует getFigmaNodePng; cache miss обращается в Figma. `/api/figma/frame` тоже live. `figmaTemplates.ts` содержит старый loader, но не является main catalog route. FigmaAccessGuard защищает только `/api/admin/status` от Figma, а не весь runtime.

**TARGET.** ARC-FIG-01/02: Figma заканчивается на design export. В package есть всё, включая static assets/adaptations/style. Отказ Figma не влияет на загрузку, previews, поля, фотобанк, crop и generation после import.

**Сохранить.** Pure extraction/normalization, понимание field naming исходников, static asset подготовку как материал для exporter, raster core и уже достигнутую main-path автономность. **Исключить из target runtime.** Live fallbacks, Figma diagnostics endpoint, production sync UI; Figma token после завершения exporter cutover не должен быть необходим приложению. **Добавить.** Exporter single/multi, package completeness validation и тест deny-network для всей user цепочки на холодном кэше. Само отсутствие вызова в одном engine файле недостаточно.

Риск: sync экспортирует только четыре asset kind и допускает пропуски; manual assets живут отдельно. Нельзя отключить fallback, пока реальные исходники/логотипы/декор не включены и проверены. H01 transport нельзя переносить в exporter без ограничения credential host.

### B. Storage

**CURRENT.** s3.ts уже собирает базовые helpers upload/read/head/list/delete/sign, но business modules знают SDK object keys, S3 error shape, B2 env. getEnv заставляет photobank зависеть от B2 config. Яндекс Диск используется только через публичный фотобанк; OAuth storage отсутствует.

**TARGET.** StorageProvider всех восьми операций, YandexDiskStorage, private backend OAuth, service root, templates/photobank/generated/system/staging. B2 конечной версии исключен. §4.7 разрешает переходный read fallback, при этом новые writes только target; B2 удаляется из эксплуатации только после сверки количества/хэшей и сценариев.

**Адаптировать.** Существующие S3 helpers обернуть как переходный provider, сохранить LRU buffer/JSON wrappers отдельно от SDK. **Изолировать.** snapshotStore, adminSyncState, universalEngine source/asset reads, generate/uploads persistence, previews URL issuance, Figma image cache. S3-specific HeadObject/NoSuchKey/$metadata и signing не должны стать business contract.

Варианты миграции данных: перенести snapshots как временно поддерживаемый input с контролируемым converter либо re-export каждый шаблон в целевой package. Первый сохраняет baseline fidelity, второй лучше проверяет completeness; выбор требует inventory. Не предложено массовое удаление текущих assets. Семантика remote move/overwrite/async completion, multi-template commit и concurrent writers должна быть проверена отдельно на безопасном test root; единичный move нельзя объявлять доказанной транзакцией всего пакета.

### C. Template model

**CURRENT.** templates.json{name/page/id}, frames raw Figma tree+assetsMap, schemas fields; name используется для category/preview path. Manual assets могут находиться вне snapshots; fonts локальные Gotham. Нет versioned parser, active/disabled, integrity manifest и package import.

**TARGET.** package.zip содержит package.json и templates/*/template.json/preview.webp/assets, optional licensed fonts (§5.2). После import per-template manifest.json — authoritative metadata/status, templates-index — производный. Manifest не следует ошибочно требовать в source ZIP лишь потому, что он обязателен в постоянном storage. Template IDs не обязаны оставаться буквальными Figma IDs; допустима нормализация с устойчивым mapping (§4.3).

**Совместимость renderer.** Engine ожидает tree со стилями/constraints/boxes, fields keys и asset buffers через B2. Новый package нельзя передать напрямую без parser/adapter. Есть два кандидата: transitional adapter package→совместимый LayoutTree, либо нейтральное scene input и адаптер legacy→scene. Первый меньше затрагивает core, второй уменьшает naming/Figma coupling. Ни один не выбран как финальный: сначала inventory nodes/fonts/print/adaptation needs и round-trip golden proof. Обязательные ограничения package должны быть проверены до активации, а не компенсироваться silent skip в render.

### D. Пользовательский UI

| Экран ТЗ | Что реально есть | Gap/вариант reuse |
| --- | --- | --- |
| Home | Root social catalog/red sidebar | Новая роль Home по §6.4; TemplateRail перенести в categories, welcome/support добавить |
| 6 catalogs | VK/Start/OK sections на одном root | Shared category routes/config filters/active/integrity; сохранить preview-click и геометрию variants как старт |
| Social editor | Dynamic fields, два столбца, result PNG, photo/crop | Refactor shared form/state; absolute sizes, counters/palettes/overflow/live preview/dirty и sidebar |
| Print editor | Нет | Shared form shell reuse; print validation/badges/output добавить |
| Target editor | Нет | Новый family/formats/crop/results orchestration на single-canvas core |
| Help | Нет | FAQ/support content config; реальные контакты остаются open |
| M1 | Photobank modal grid folders/photos | Selection state/API reuse; compact left tree и empty/retry/focus |
| M2 | Нет, thumbnail сразу выбирает | Добавить крупный preview/select/back, сохранить editor state |
| M3 | Inline crop внутри preview panel | Math и draft/confirm reuse, presentation в modal |
| M4 | Нет | Format-aware completion/revisit/cancel/reset слой над crop math |

Полной замены UI primitives не требуется. Замены требуют роль Home и presentation старого sync; crop math/rich text могут жить в новых компонентах. Нельзя назвать current preview «живым»: это snapshot либо результат POST. New live preview должен обновляться от нормализованного input с debounce и сохранять last good view при ошибке. Modal boundaries не должны уносить page fields. UI здесь не реализуется.

### E. Admin

**CURRENT.** Один sync route, query token/client bearer, full/dry/single buttons, read sync meta. Header secret есть и проверяется сервером. /health постоянный ok; status запрещает Figma, но не проверяет storage/render.

**TARGET.** Отдельный password-login + secure session; три раздела Home/Import/Templates. Dashboard измеряет YD root/OAuth/runtime/PNG/PDF/loader, usage and directory groups, generated cleanup, duplicates и service state. Import показывает каждого template, блокирует весь пакет при любой critical error и публикует атомарно. Table управляет active/disabled/update/delete, сохраняет status при update, truthfully отображает частичные ошибки.

**Сохранить.** Server-side enforcement как принцип; простую operational JSON metadata, отдельную admin URL-зону, basic progress/errors. **Заменить.** Query token transport и sync business operation/UI. **Добавить.** Session lifecycle/rate limit; safe extraction/transactions; measured health/statistics; bounded deletes and duplication review. Lock/meta из sync нельзя назвать готовой transaction abstraction: H03/H04/H05 показывают ограничения. Без DB всё равно требуется согласованный writer protocol; отсутствие БД не оправдывает частичную публикацию.

### F. Print

**CURRENT.** Output только PNG/RGBA. Text paths растеризуются sharp; physical units/CMYK/ICC/OutputIntent/bleed/TrimBox/font embedding/effective PPI/preflight не реализованы. Текстовый `validate=1` и console phrase «preflight» не являются PDF preflight.

**TARGET.** §5.6/6.10/9: физические размеры и print metadata из template, PDF CMYK, quality около 300 effective PPI, bleed/safe/trim, встроенные либо допустимо преобразованные шрифты, согласованный profile/ICC, проверка до выдачи download. User видит только PDF/CMYK/300dpi; format/orientation не выбираются в editor.

**Reusable input.** Text/photo controls, runs, cropNorm, image decode/geometry и часть font metrics. **New output.** PDF pipeline и preflight, зависящие от реальных типографских правил. Нельзя объявить sharp достаточным PDF engine или выбрать библиотеку без demonstration нужного профиля. Сначала требуется проверяемый образец PDF с реальным CMYK, fonts, boxes, cropped image и независимой проверкой. Финальный engine — INVESTIGATE, не решение этого аудита.

Effective PPI должен использовать число исходных пикселей оставшегося после crop участка и физическую область размещения, а не размеры после upsample. Например вычислительный принцип — pixels / inches по обеим осям; конкретные threshold и warning/block policy определяет config. PDF/X-4 приведён как пример, 250–300 PPI — рекомендуемый порог, фиксировать их как безусловные обязательные значения нельзя. ТТХ и лицензия определяют допустимость outlining вместо embedding.

### G. Target

**CURRENT.** Один template ID→один frame→один resultUrl. Кнопки -1/0/+1 изменяют размер текста base±10 px, но нет family, selectedFormats, per-format geometry, auto-fit и ZIP. Это заготовка UI control, не многоформатная генерация.

**TARGET.** Family выбирается до formats; общий text/photo content, индивидуальные base geometry/fonts/crop по adaptation; от 1 до 5 preview одновременно без scroll, enlargement inside panel. sizeLevel=0 допускает auto-fit вниз в разрешенных bounds, explicit manual size не перезаписывается. Каждый выбранный format/slot должен иметь completed crop. Добавление нового format требует его crop; source replacement сбрасывает все crops только этого slot. Ошибки per-format, успешные outputs сохраняются; retry failed без ререндера successful при неизменных данных; ZIP только полный ожидаемый набор.

**Сохранить.** Single-canvas PNG engine, source reuse, crop math, relative control idea. **Добавить.** Family schema, normalized content revision, adaptation state, bounded execution, status aggregation, all-formats ZIP validation и complete crop gating. Не добавлять campaign goal/CTA/трафик поля: §6.11.3 запрещает их, если не являются реальными fields выбранного package. Примеры 1:1/16:9/9:16 не заменяют фактический список templates.

## Зависимости и контрольные условия перехода

Это порядок снятия зависимостей, а не backlog с финальными модулями/API/оценками сроков. Этапность A–F взята из §15; внутри неё новые admin mutation возможности должны быть защищены с самого начала, даже если полный dashboard создается позднее.

| Условие | Почему требуется | Что должно быть проверено до следующего перехода |
| --- | --- | --- |
| Обсуждение аудита и inventory реальных templates/assets | Нельзя определить renderer/schema coverage только по TypeScript | Reusable classes, manual assets, шрифты/лицензии, отсутствующие source artifacts |
| Изоляция storage при сохраненном baseline behavior | Прямые B2 вызовы мешают provider migration | Contract checks и golden render на прежних данных, safe path mapping |
| Проверка Yandex test-root semantics и transfer reconciliation | Move/replace/quotas не проверены в этом аудите | Все 8 операций, failure modes, counts/hash; B2 ещё доступен для сверки |
| Versioned schema/export/import completeness | Runtime не должен восстанавливать assets из Figma | Single/multi packages, unique fields, assets/fonts, version rejection; no publish until confirmation |
| Auth + writer/commit/invalidation invariants | Запись множества файлов не атомарна автоматически | Concurrent writers, fault after each step, repeated confirm, old active intact, repaired index/cache |
| User editor/preview на общем input contract | Current validator и renderer расходятся | Same rich text/layout, required/permissions, crop replacement, errors/state/focus |
| Target and print proofs | Отдельные ресурсы и output guarantees | Per-format partial failure/ZIP completeness; real PDF preflight/PPI/fonts/boxes |
| Production candidate | §15.6 и приложение З | 15 screens+4 modal QA, no Figma/B2 mandatory network, runtime settings, real support config |

Допустимый по §4.7 transitional B2 read fallback нельзя превращать в бессрочную скрытую зависимость. Отключение credentials/fallback разрешается только как отдельное последующее изменение после проверки migrated outputs/counts/hash; main и legacy baseline сохраняются. Публикация final production требует отдельной команды владельца по AGENTS.md.

## Что требуется исследовать отдельно

Реальная библиотека Figma/B2 не считывалась: неизвестны количество template families, доля нестандартных nodes, полнота manual assets, действительные размеры/шрифты. Vercel production env/branch/limits не подтверждены. В этом сеансе GitHub CLI первоначально вернул 401, поэтому GitHub/Vercel настройки не считаются проверенными по старому README. Нет оснований утверждать успешную миграцию хранения, print output или production autonomy по одному статическому анализу.

Системный риск — несогласованность schema/editor/renderer/validator. Минимальный reuse proof должен сравнивать одинаковый normalized input и output до/после отделения IO; отдельно проверять ошибки. Предварительный набор regression и acceptance приведен в REQUIREMENTS_TRACEABILITY_2026.md, конкретные defect fixtures — в TECH_DEBT_2026.md.

## OPEN PARAMETERS / DECISIONS REQUIRED

Значения ниже намеренно не придуманы. Первые восемь групп взяты из приложения И; остальные — открытые policy/configuration места основного текста либо явно обозначенные инженерные решения для следующего этапа. Current defaults не переносятся автоматически в TARGET.

| Источник / что нужно решить | Почему требуется | Компонент | Блокирует ли начало разработки | Когда решение нужно |
| --- | --- | --- | --- | --- |
| И — реальный URL корпоративной заявки | Одна рабочая кнопка в Home и Help; пустой URL — production defect | Support config | Нет; unconfigured disabled state задан ТЗ | До production content acceptance |
| И — ФИО и контакты руководителя отдела | Нельзя выдумывать персональные данные | Help/support config | Нет; явные placeholders допустимы до запуска | До production |
| И — корпоративные контакты Федурина Алексея Викторовича | ФИО задано, e-mail/канал связи отсутствуют | Help/support config | Нет | До production |
| И — будущие категории листовок | Базовые referral/vacancies есть, расширения неизвестны | Category/nav config | Нет; config должна расширяться | При inventory и подготовке новых категорий |
| И, §6.5 — финальные filters каждой категории | Примеры chips/theme/segments не окончательные данные | Catalog metadata/config | Нет для общего catalog; нужны для содержательной приемки | После inventory реальной библиотеки |
| И — фактический список target formats/families | 1–5 одновременно — рамка UI, не полный список размеров | Exporter/schema/target tests | Нет для общего механизма; реальные fixtures зависят | До target package приемки |
| И, §6.2, В — утверждённые EVP fonts/colors | Current Gotham не доказательство лицензии/нового EVP; dark placeholder открыт | Tokens/font registry/exporter/renderer | Не блокирует IO isolation; блокирует окончательную типографику | До visual golden approval и production |
| И, §3.2 — российский production runtime | Limits/native deps/long operations/network определяются средой | Deployment/resource policy | Нет для чистых модулей; блокирует release/performance verdict | До окончательной integration/load приемки |
| §9.3 — целевой PDF profile, ICC/OutputIntent, политика шрифтов | PDF/X-4 только пример; engine выбор зависит от типографии/лицензии | PDF engine/preflight/exporter | Блокирует окончательный выбор print process, не raster работу | До print prototype acceptance |
| §9.4 — точный warning/block effective PPI threshold | 250–300 рекомендовано, target 300; допуски material-specific | Photo quality validator | Нет для формулы; блокирует pass/fail policy | До print tests на реальных A4/A5 |
| §5.6/9.3 — physical sizes, bleed/safe/trim/marks каждого шаблона | ТЗ не задает универсальный вылет в миллиметрах и crop marks policy | Print template/exporter | Нет для schema scaffolding | При подготовке каждого print package |
| §6.11.4/8.3 — sizeLevel mapping/steps/bounds | Конкретный шаг configurable, примеры не закон | Target typography/auto-fit | Нет для control, да для ожидаемых layout outputs | До target golden tests |
| §6.11.4 и §8.3 — ручное изменение с возвратом к 0 | Первая формулировка учитывает факт ручного взаимодействия, вторая — текущее sizeLevel=0; поведение возврата требует согласования | Target editor size state | Нет для других частей | До финального auto-fit contract; не считать текущее ±10 решением |
| §6.6.4 — base size вне глобального range | ТЗ требует warning и не активировать до согласования политики | Import activation gate | Нет; безопасное неактивирование предусмотрено | До импорта такого template |
| §3.6–7/4.6 — TTL staging/uploads/cache/generated retention | Нужны bounded temporary lifecycle и recovered cache; конкретные сроки не заданы полностью | Storage/temp/cache/cleanup | Нет для интерфейсов | До запуска cleanup и resource tests |
| §7.5/11.7/13.1 — max upload bytes/pixels/count, ZIP unpack budget и render concurrency | Current 10/30 MB не target decision; resource budget зависит от runtime | Upload/import/render | Нет для независимых primitives | До приема реальных uploads/archives и load tests |
| §11.2 — session lifetime/revocation и rate-limit thresholds | ТЗ требует ограничение/ревокацию, не задает duration/attempt count | Admin auth | Нет для механизмов, да для окончательной конфигурации | До login security acceptance |
| §6.15.4/11.3–4 — stats TTL/usage thresholds/health timeout | 70/85% и 30–60 сек — рекомендации/допустимые ориентиры; интервалы scans зависят от объема | Admin health/stats/cache | Нет | До dashboard performance/config приемки |
| §3.5/4.1 — service root и доступы OAuth | Root путь приведён как пример; нужен реальный corporate namespace/scope | Provider/path guards | Не блокирует abstraction, блокирует real connection | До integration на отдельном test root |
| Инженерное решение, вытекающее из §4.5/11.7 — atomic multi-template publish и concurrent writer protocol | Восьми provider операций недостаточно, чтобы без проверки объявить multi-file transaction | Import/manifests/index/cache | Блокирует финальную архитектуру mutations, не чтение/аудит | Следующий архитектурный этап, после проверки remote semantics |
| Инженерное решение по §4.7/5 — re-export vs transitional converter и stable ID mapping | Реальная полнота snapshot/manual assets неизвестна | Template migration | Блокирует финальное решение о конвертации, не сохранение core | После inventory и golden proof |

ТЗ местами использует чуть разные формулировки сообщений download/overflow и aggregate health warning (§6/12/Е), а приложение Ж упоминает duplicate statistics рядом со storage-stats при отдельном duplicate-scan в §4.1/4.6. Это не основание создавать лишние функции: на следующем этапе согласовать единый текстовый каталог и ownership служебных полей, сохранив требуемые user actions и отдельный кэш scan. Конкретные имена TypeScript interfaces, URLs из приложения А, библиотека PDF и способ writer coordination этим аудитом окончательно не выбраны.
