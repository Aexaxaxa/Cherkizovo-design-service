# Open Parameters / Decisions 2026

Состояние на 08.09.2026, baseline `236cbfda11c3b45faba4a6bf8e3c7e30cccd5a31`. Источники: `MIGRATION_2026.md`, `TECH_DEBT_2026.md`, `REQUIREMENTS_TRACEABILITY_2026.md`, код CURRENT и ТЗ v1.0 от 06.09.2026. Финальных Figma-макетов и ТЗ 2.0 нет. Поэтому документ каталогизирует решения и рекомендации, но не подменяет отсутствующие продуктовые данные.

`RECOMMENDATION, НЕ FINAL DECISION` означает наиболее безопасное направление на имеющихся фактах. Оно становится решением только после явного принятия владельцем и отражения в будущей Architecture 2026/Implementation Plan.

## A. МОЖНО РЕШИТЬ ДО FIGMA

| ID | Вопрос | Почему нужно решить | Что зависит | Можно решить сейчас? | Зависит от Figma? | Зависит от ТЗ 2.0? | Нужен research/POC? | Крайний момент принятия |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A01 | Ввести ли `StorageProvider` как единственную business-границу storage и какие 8 операций обязательны? | CURRENT вызывает S3 helpers напрямую; ТЗ задаёт upload/download/delete/exists/list/mkdir/move/getUsage. | Все manifests, import, generated, photobank и admin stats. | Да, интерфейс и ownership ошибок; transport details позже. | Нет | Нет для базового контракта | Небольшой contract spike полезен | До Architecture 2026 и первого storage-touching кода |
| A02 | Что считать source of truth: per-template manifest, а index — rebuildable projection? | Один `templates.json` не даёт безопасный lifecycle/recovery. | Import/update/enable/delete, catalog, cache recovery. | Да, принцип задан ТЗ. Поля content зависят от templates. | Частично | Частично | Нет для принципа | До model/import architecture |
| A03 | Как разделить runtime model и Figma-shaped snapshot? | Renderer зависит от Figma tree, хотя обычный flow не ходит в Figma REST. | Exporter adapter, renderer input, автономность. | Да: runtime не должен импортировать Figma transport/types beyond normalized boundary. | Нет для boundary | Нет | Golden proof потребуется | До первого refactor renderer/schema |
| A04 | Должен ли production runtime полностью работать без Figma network/token? | ARC-FIG-01 и §13.6 требуют автономности после import. | Deployment, package acceptance, health, secrets. | Да: это прямое требование ТЗ. | Нет | Нет | Autonomy test нужен позднее | До Architecture 2026; доказать до release |
| A05 | Какое правило cache invalidation использовать после mutations? | CURRENT имеет независимые caches, stale signed URLs и race с pending loader. | Catalog/schema/assets/manifests/admin consistency. | Да на уровне принципа: commit/version first, invalidate after success, URLs не кэшировать дольше срока. | Нет | Нет | Multi-instance implementation spike возможен | До проектирования import/update/delete |
| A06 | Какие security invariants обязательны независимо от UI? | Новые OAuth, ZIP, delete и admin увеличат trust boundary. | Все APIs, provider, import, logs, deployment. | Да для обязательных invariant; численные limits позже. | Нет | Частично | Threat-model review, targeted POC для ZIP/egress | До Architecture 2026 и каждого security-sensitive компонента |
| A07 | Как разделить pure reusable core и IO orchestration? | Renderer/text/crop/schema helpers полезны, но IO и routes смешаны. | Testability, storage migration, golden comparisons. | Да: dependency direction и test seams можно определить сейчас. | Нет | Нет | Characterization harness design уже дан | До первого изменения core |
| A08 | Как трактовать existing baseline failures? | `pnpm` entry points сейчас не воспроизводимы, tests отсутствуют. | CI gate и оценка новых regressions. | Да: baseline failures нельзя выдавать за новые; direct build pass хранить отдельно. | Нет | Нет | Нет | До первого CI/test change |
| A09 | Каким должен быть templates index lifecycle? | ТЗ требует rebuild; index не может быть единственной копией metadata. | Startup/catalog/recovery/admin counts. | Да для rebuildability/version marker; конкретные поля позже. | Частично | Частично | Fault-injection нужен позднее | До import architecture |
| A10 | Должны ли ошибки provider/render/import иметь typed domain codes без upstream body/secrets? | CURRENT местами возвращает `error.message` и пишет upstream details. | UI errors, logs, retry, security. | Да. | Нет | Частично для user wording | Нет | До подключения OAuth/import APIs |

### Варианты и предварительные рекомендации A

#### A01 — StorageProvider

**RECOMMENDATION, НЕ FINAL DECISION:** один минимальный async-интерфейс из восьми операций, normalized `ResourceInfo`, typed errors и явные path/root guards; B2 и Yandex Disk — adapters, business-код SDK не видит.

| Вариант | Плюсы | Минусы | Влияние на migration | Что подтвердить |
| --- | --- | --- | --- | --- |
| Узкий единый interface + adapters | Выполняет ТЗ, тестируется in-memory fake, позволяет transitional B2 read adapter | Различия S3/WebDAV-like semantics надо выразить errors/capabilities | Даёт постепенную изоляцию без немедленного переноса данных | Семантику overwrite/move/list/pagination и async completion Yandex |
| Расширенный capability interface | Явно показывает optional server-side move/quota | Рано закрепляет transport details и усложняет consumers | Может снизить риск ложной атомарности | Какие capabilities реально доступны в corporate API |
| Отдельные interfaces по доменам | Узкие зависимости catalog/generated/import | Риск дублирования path/error semantics | Больше adapter glue | Нужна ли эта сложность после первых contract tests |

#### A02/A09 — manifests и index

**RECOMMENDATION, НЕ FINAL DECISION:** versioned per-template manifest — authoritative; index содержит только rebuildable catalog projection и generation/version marker. Любая активация публикует полный manifest/package, затем новый index.

| Вариант | Плюсы | Минусы | Влияние на migration | Что подтвердить |
| --- | --- | --- | --- | --- |
| Per-template manifests + rebuildable index | Recovery, независимый lifecycle, прямое соответствие ТЗ | Нужен протокол publish и scan cost | Existing snapshots проходят converter/re-export | Реальный объём библиотеки и list performance |
| Единый monolithic manifest | Простое чтение | Large-write contention и повтор CURRENT `templates.json` weakness | Плохо поддерживает atomic N import | Не рекомендуется без доказательства малого фиксированного объёма |

#### A03/A04/A07 — граница runtime core

**RECOMMENDATION, НЕ FINAL DECISION:** exporter/converter производит versioned normalized package; runtime знает package schema, provider и pure render inputs. Figma API/token остаются только design/import side и удаляются из ordinary runtime после golden/autonomy proof.

| Вариант | Плюсы | Минусы | Влияние на migration | Что подтвердить |
| --- | --- | --- | --- | --- |
| Normalized runtime model + legacy adapter | Чёткая автономность, позволяет поэтапный перенос | Нужен adapter и двойные fixtures на переходе | Наиболее безопасен для сохранения renderer | Coverage реальных Figma nodes/assets |
| Snapshot-compatible package как v1 | Быстрее первый перенос | Консервирует Figma-shaped schema в TARGET | Меньше initial churn, больше будущего debt | Допустим ли transitional срок и exit criteria |

#### A05 — cache invalidation

**RECOMMENDATION, НЕ FINAL DECISION:** кэш только производный; ключи включают committed manifest/index version; publish меняет version после полной записи; signed URL создаётся/обновляется отдельно; pending loaders не могут вернуть older generation после invalidation.

Альтернатива — явные delete/clear по process-local keys. Она проще, но не закрывает multi-instance и in-flight race, поэтому допустима только для локального transitional режима. Подтвердить hosting topology, стоимость list/read и срок access URLs.

#### A06/A10 — security и error policy

**RECOMMENDATION, НЕ FINAL DECISION:** server-only credentials; allowlisted egress hosts; root-confined normalized paths; bounded bytes/pixels/count/time/concurrency; ZIP traversal/ratio/count protection; authn/authz до body processing; typed safe client errors; redacted structured logs; retry только временных ошибок, без auth loop.

Плюсы — единая проверяемая граница и выполнение §13.3. Минусы — численные limits и log retention нельзя установить без runtime/ТЗ 2.0. Migration должен заменить current generic errors постепенно и сохранить диагностический correlation ID. Подтвердить corporate perimeter, provider redirects, observability platform и resource budgets.

#### A08 — baseline gate

**RECOMMENDATION, НЕ FINAL DECISION:** хранить две колонки результата: официальный command и underlying application check. Existing failure остаётся известным до отдельного разрешённого tooling change; новая ветка не может ухудшить direct `next build`, route smoke или будущие characterization tests.

## B. НУЖНА FIGMA

| ID | Вопрос | Почему нужно решить | Что зависит | Можно решить сейчас? | Зависит от Figma? | Зависит от ТЗ 2.0? | Нужен research/POC? | Крайний момент принятия |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B01 | Финальная package schema для Template Exporter | Нужны реальные node types, assets, geometry, editable permissions и variants. | Export single/multi, importer, renderer adapter. | Только envelope/versioning | Да | Частично | Да, export coverage spike | До exporter implementation |
| B02 | Какие Figma nodes/styles/constraints поддерживаются и что считается hard error? | CURRENT поддерживает не все fills/classes и может silently skip. | Package validation и visual fidelity. | Нет полного списка | Да | Нет | Да, inventory + golden samples | До schema v1 freeze |
| B03 | Migration existing templates: re-export или transitional converter | Полнота snapshots/manual assets неизвестна. | B2 exit, stable IDs, regression proof. | Нет | Да | Частично | Да | После inventory, до массового migration |
| B04 | Stable template/family/adaptation IDs и mapping legacy IDs | Name-based current model недостаточна для lifecycle. | URLs, manifests, index, updates, crops, analytics. | Только требования uniqueness/stability | Да | Частично | Возможно | До первой финальной package |
| B05 | Фактические target families/formats и их общие/индивидуальные поля | ТЗ задаёт 1–5 adaptations, но не исчерпывающий inventory. | Target editor, exporter, crops, golden cases. | Нет | Да | Да | Нет после approved inventory | До target implementation |
| B06 | Print geometry каждого template: physical size, trim, bleed, safe zones, marks | Универсального значения ТЗ не задаёт. | PDF, preflight, PPI, exporter. | Нет | Да | Частично | Print proof нужен | До print package acceptance |
| B07 | Approved EVP tokens, fonts, weights, colors и per-field palettes | Current Gotham/цвета не подтверждают будущий бренд и лицензии. | UI kit, exporter, renderer, PDF. | Нет | Да | Частично | Font/PDF checks | До Design System и visual goldens |
| B08 | Какие existing `assets/screens` становятся canonical references | Сейчас это historical screenshots, не утверждённый Figma source. | Visual regression thresholds и UI acceptance. | Кандидатов можно перечислить, канон выбрать нельзя | Да | Да | Да, reference review | После утверждения Figma, до UI code |
| B09 | Точная модель editable fields, labels/order/required/allowedColors/size bounds | Prefix extraction не выполняет TARGET contract. | Forms, validation, exporter/schema. | Envelope возможен | Да | Частично | Schema fixture review | До schema/exporter implementation |

`assets/screens` сохраняются только как потенциальные baseline candidates. Они не объявляются целевым дизайном и не изменяются.

## C. НУЖНО ТЗ 2.0

| ID | Вопрос | Почему нужно решить | Что зависит | Можно решить сейчас? | Зависит от Figma? | Зависит от ТЗ 2.0? | Нужен research/POC? | Крайний момент принятия |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| C01 | Реальный support/request URL и поведение unconfigured state | Home/Help требуют рабочую ссылку; значение неизвестно. | Content/config/acceptance. | Нет значения; disabled state известен | Нет | Да | Нет | До production content acceptance |
| C02 | ФИО/контакты руководителя и корпоративные контакты Федурина А.В. | Нельзя выдумывать персональные данные. | Help/support content. | Нет | Нет | Да | Нет | До production |
| C03 | Будущие категории листовок и финальные filters | Current три соцгруппы не задают target taxonomy. | Navigation/catalog/config. | Extensible mechanism — да, данные — нет | Частично | Да | Нет | До catalog content acceptance |
| C04 | Точный `sizeLevel` mapping, bounds, auto-fit и возврат manual control к 0 | ТЗ v1.0 содержит примеры и две требующие согласования формулировки. | Target typography/UI/goldens. | Нет чисел/семантики | Частично | Да | Layout tests после решения | До target editor implementation |
| C05 | Generated/uploads/staging/cache TTL и cleanup policy | Bounded lifecycle обязателен, конкретные сроки неизвестны. | Storage cost, admin cleanup, privacy, tests. | Механизм — да, значения — нет | Нет | Да | Load/cost data полезны | До первого write в target storage |
| C06 | Upload/ZIP/render resource budgets: bytes, pixels, file count, ratio, concurrency, timeout | Current 10/30 MB не target decision. | Security, performance, errors, deployment. | Categories — да, значения — нет | Частично | Да | Load/abuse POC | До public upload/import |
| C07 | Admin session lifetime, revocation, login rate limits и roles | ТЗ требует secure session, но не даёт durations/attempts/role matrix. | Auth middleware, cookies, operations. | Механизм — частично, policy — нет | Нет | Да | Security review | До admin auth implementation |
| C08 | Yandex OAuth account/scope/root path/ownership | Пример root не является production configuration. | Provider, path guards, quota, migration. | Нет credentials/path | Нет | Да | Integration POC нужен | До подключения test storage |
| C09 | Storage quota thresholds и dashboard scan/TTL | 70/85% и 30–60 сек в ТЗ — ориентиры, не утверждённая policy. | Admin warnings, polling, performance. | Нет финальных значений | Нет | Да | Usage/load measurement | До dashboard acceptance |
| C10 | Production runtime/hosting, regions, network access, limits и ownership | Требуется российская среда, конкретная платформа не выбрана. | Deployment, native sharp/PDF, long jobs, OAuth. | Нет | Нет | Да | Да, deployment spike | До Architecture 2026 finalization и load tests |
| C11 | Security/deployment policy: CSP, CORS, cookies, egress, logging/retention, malware scan ownership | Repo не доказывает corporate perimeter. | All external/admin/file flows. | Invariants — да; organization values — нет | Нет | Да | Security review | До production security acceptance |
| C12 | User-visible wording для overflow/download/import/cleanup/health | ТЗ v1.0 содержит близкие, местами разные формулировки. | Error catalog/UI tests. | Смысл — да, финальный copy — нет | Да | Да | Нет | До UI content freeze |
| C13 | Политика duplicate templates/stale temp и разрешённые admin actions | Scan задан отдельно, auto-delete запрещён, ownership статистики требует уточнения. | Admin lifecycle/cleanup. | Safety rule — да, workflow details — нет | Частично | Да | Fault tests | До template management implementation |
| C14 | Финальные target formats/families вне утверждённого Figma inventory | Примеры размеров не являются полным product scope. | Multi-format pipeline/ZIP/progress. | Нет | Да | Да | Нет | До target scope freeze |

## D. НУЖНО ОТДЕЛЬНОЕ ТЕХНИЧЕСКОЕ ИССЛЕДОВАНИЕ / POC

| ID | Вопрос | Почему нужно решить | Что зависит | Можно решить сейчас? | Зависит от Figma? | Зависит от ТЗ 2.0? | Нужен research/POC? | Крайний момент принятия |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| D01 | Семантика Yandex Disk private API для 8 `StorageProvider` operations | Move/overwrite/list/quota/async completion нельзя предположить по public API. | Provider errors, atomic publish, retry. | Нет | Нет | Частично: account/root | Обязательно, isolated test root | До выбора commit protocol |
| D02 | Atomic import одного и N packages при remote multi-file writes/concurrent writers | Единичный move не доказывает транзакцию пакета. | Staging, manifests/index, rollback/recovery. | Нет | Частично | Нет | Обязательно: failure after each write + two writers | До import implementation |
| D03 | PDF engine и production packaging | CURRENT PDF отсутствует; нужны CMYK, boxes, OutputIntent и fonts. | Print renderer/deployment. | Нет | Частично | Да: profile policy | Обязательно: real A4/A5 sample | До выбора PDF dependency/process |
| D04 | CMYK conversion и ICC/OutputIntent profile | `sharp` RGBA PNG не доказывает print-ready color management. | PDF correctness/preflight. | Нет | Частично | Да | Обязательно с типографией/inspector | До print architecture freeze |
| D05 | Effective PPI calculation after crop/scale и warning/block thresholds | Resize dimensions могут дать ложный pass; threshold открыт. | Photo validation/preflight/UI badges. | Формула исследуема, policy нет | Да: slot geometry | Да | Да, real images/physical boxes | До print validation implementation |
| D06 | Font embedding vs approved outline conversion и лицензии | SVG paths в PNG не равны PDF embedding; права неизвестны. | Exporter/package/PDF/preflight. | Нет | Да | Да | Обязательно: license + PDF inspection | До package/font contract |
| D07 | Coverage universal renderer на реальных templates | Silent missing assets/unsupported nodes возможны. | Reuse verdict и converter design. | Нет полного доказательства | Да | Нет | Golden inventory POC | До крупного renderer refactor |
| D08 | Pixel-diff method/tolerance и deterministic render environment | Exact PNG bytes могут меняться из-за libraries/metadata. | Regression gate/CI artifacts. | Кандидаты можно определить | Да для goldens | Нет | Да, repeatability experiment | До фиксации golden set |
| D09 | Production runtime/deployment для Next + sharp + выбранного PDF engine + long jobs | Platform limits определяют memory/time/concurrency. | Hosting, queues, budgets, observability. | Нет | Нет | Да | Deployment/load POC | До Architecture 2026 approval |
| D10 | Migration reconciliation: count/hash/IDs и момент отключения B2 fallback | Нельзя удалить credentials до доказательства полноты. | B2 exit и rollback. | Нет без inventory | Да | Нет | Dry-run migration rehearsal | До production cutover |
| D11 | OAuth token refresh, scopes, redirect/egress и secret rotation | CURRENT OAuth отсутствует. | Private photobank/storage reliability/security. | Нет | Нет | Да: account ownership | Isolated integration/security POC | До реального OAuth adapter |
| D12 | Multi-instance cache coherence и pending invalidation | Process Maps/LRU не гарантируют consistency. | Catalog/admin mutation correctness. | Pattern можно выбрать после topology | Нет | Да: runtime topology | Concurrency POC | До production mutation path |

### Рамки POC

POC выполняются только на отдельном test root/account и synthetic packages; не на production library. Для каждого заранее задаются pass/fail criteria, resource budget, данные очистки и сохранённый reproducible fixture. POC не должен превращаться в скрытую feature-ветку до прохождения PRE-CODE GATE.

## PRE-CODE GATE

Gate относится к **первому изменению runtime-кода версии 2026**, а не к документационным исследованиям. На 08.09.2026 он не пройден.

### BLOCKING BEFORE CODE

| Условие | Что считается готовностью | Текущий статус |
| --- | --- | --- |
| Figma основного UI | Утверждены все основные страницы, M1–M4 и связи между ними | BLOCKED: финальных макетов нет |
| Основные состояния экранов | Loading/empty/error/disabled/success/partial/retry/confirmation и keyboard behavior видны в макетах/спецификации | BLOCKED |
| UI Kit / Design System | Tokens, typography, spacing, controls, dialogs, error states и responsive desktop rules утверждены | BLOCKED |
| Tabler Icons | В UI Kit закреплён Tabler Icons как основная библиотека новых иконок, описаны исключения для brand/existing assets | BLOCKED; dependency сейчас не добавлялась |
| Финальное ТЗ 2.0 | Устранены неоднозначности scope, content, policy и acceptance | BLOCKED: документа нет |
| Блокирующие архитектурные решения | Приняты A01–A07 и получены результаты D01/D02, а для первого implementation slice — соответствующие B/C/D решения | BLOCKED |
| Architecture 2026 | Утверждён отдельный документ после Figma/ТЗ 2.0/POC; CURRENT не переименован в target | BLOCKED; `ARCHITECTURE_2026.md` сейчас не создавался |
| Implementation Plan | Составлен после Architecture 2026, с dependency order, rollback и verification gates | BLOCKED; `IMPLEMENTATION_PLAN_2026.md` сейчас не создавался |
| Baseline tests определены | Characterization/golden/fixture strategy и future matrix review приняты; известен способ сравнить CURRENT/TARGET | PREPARED в `REGRESSION_BASELINE_2026.md`, требует review |
| Critical migration risks понятны | H01–H11, atomic import, B2 cutover, Figma coverage, resource/security gates имеют owners/mitigation/proof | IDENTIFIED, owners/решения ещё не назначены |
| Reproducible toolchain decision | Закреплены Node/pnpm и устранён либо принят baseline `ERR_PNPM_IGNORED_BUILDS`; официальные команды дают однозначный signal | BLOCKED; не исправляется этой задачей |

До закрытия этих условий допустимы read-only inventory, документация и заранее ограниченные research/POC без изменения production data. Feature/refactor runtime work начинать нельзя.

### CAN BE DECIDED LATER

Следующие решения могут оставаться configurable после начала кода, если первый slice от них изолирован и интерфейс не фиксирует выдуманное значение:

- реальные support/contact values — до content acceptance;
- будущие категории и финальные filters — до наполнения соответствующего catalog;
- точные TTL, quotas warning levels, session durations и numeric rate limits — до первого затрагивающего production path, при наличии безопасных config boundaries;
- final hosting tuning, concurrency и cache TTL — до load/integration acceptance, но базовая платформа нужна для Architecture 2026;
- полный список target families — до target slice, если package schema доказан на approved representative families;
- user-facing copy variants — до UI content freeze при сохранении action/error semantics;
- окончательные pixel-diff tolerances — после repeatability POC, до включения visual gate в CI.

Нельзя отложить boundary decisions так, чтобы временная реализация снова связала business-код с B2/Figma или сделала необратимыми schema/storage paths. Открытый параметр остаётся явным config/decision record, а не скрытым hardcoded default.
