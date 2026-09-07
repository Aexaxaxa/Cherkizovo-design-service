# Runtime baseline Cherkizovo Design Service перед изменениями 2026

Дата проверки: 08.09.2026. Baseline commit: `236cbfda11c3b45faba4a6bf8e3c7e30cccd5a31` (`origin/develop-2026` на момент создания `chore/2026-precode-baseline`). Проверка фиксирует старый сервис без исправления найденных проблем и без изменения runtime-кода, конфигурации или production-данных.

## Правила интерпретации

| Статус | Значение |
| --- | --- |
| PASSED | Команда или сценарий фактически выполнены и завершились ожидаемо в проверенной среде. |
| FAILED — EXISTING BASELINE | Проверка фактически упала на состоянии baseline; исправление в эту задачу не входит. |
| NOT RUN | Проверка намеренно не запускалась; причина указана. |
| NOT APPLICABLE | В baseline нет соответствующего script/компонента. |
| BLOCKED | Проверку нельзя было довести до результата из-за конкретного внешнего условия. |

PASSED относится только к указанному сценарию и среде. HTTP 200 не доказывает корректность всех взаимодействий, а успешный build не доказывает production readiness.

## Среда и установка

| Проверка | Статус | Фактический результат |
| --- | --- | --- |
| Baseline / ancestry | PASSED | HEAD и merge-base с `origin/develop-2026` перед работой: `236cbfda11c3b45faba4a6bf8e3c7e30cccd5a31`. Local/remote `main`: `ab8119ac4495e6994e3730f83e9a8a9121967a80`. |
| Node.js | PASSED | `v22.20.0`. Репозиторий не закрепляет Node через `engines`/`.nvmrc`; эта версия описывает только текущую среду. |
| pnpm | PASSED | `11.19.0`, предоставлен Codex runtime wrapper. При каждом вызове предупреждает, что поле `pnpm` в `package.json` больше не читается. |
| Исходный install state | FAILED — EXISTING BASELINE | `node_modules` и `.modules.yaml` присутствовали, но первый `pnpm build` инициировал dependency status check и попытку переустановки; без TTY получил `ERR_PNPM_ABORTED_REMOVE_MODULES_DIR_NO_TTY`. Установку нельзя считать воспроизводимо готовой. |
| `pnpm install --frozen-lockfile` | FAILED — EXISTING BASELINE | С `CI=true` lockfile признан актуальным, установлены 400 packages, затем pnpm 11 завершился `ERR_PNPM_IGNORED_BUILDS`: scripts `sharp@0.34.5` и `unrs-resolver@1.11.1` не разрешены. Он создал предложенный `pnpm-workspace.yaml`; файл удалён как артефакт проверки и не вошёл в Git. |
| Lockfile integrity | PASSED | `pnpm-lock.yaml` не изменился; SHA-256 после install: `0719B837F5A7323C7BAC92E72CC917FFE34FFC27340787015334ADEFF0BC188A`. Git diff для manifest/lockfile пуст. |
| Фактические dependencies | PASSED | По lock установлены Next 15.5.12, React/React DOM 19.2.4, sharp 0.34.5, AWS SDK 3.990.0, TypeScript 5.9.3, ESLint 9.39.2. `require('sharp')` успешно загрузился несмотря на pnpm policy failure. |

В `package.json` реально объявлены только scripts `dev: next dev`, `build: next build`, `start: next start`, `lint: next lint`. Test script отсутствует.

## Build, lint и tests

| Проверка | Статус | Фактический результат |
| --- | --- | --- |
| `pnpm build` | FAILED — EXISTING BASELINE | Через текущий pnpm wrapper команда дважды не дошла до `next build`: сначала no-TTY purge, после frozen install — `ERR_PNPM_IGNORED_BUILDS`. Это baseline/toolchain defect, а не найденная ошибка компиляции приложения. |
| Фактическое содержимое build script: `next build` | PASSED | Прямой запуск установленного `node node_modules/next/dist/bin/next build`: compilation, lint/type checking, 19 static/dynamic routes, page optimization и build traces завершились успешно. |
| Build warnings | PASSED | Build завершён, но зафиксированы восемь existing `@next/next/no-img-element`: `app/page.tsx:253`, `app/t/[id]/page.tsx:435,1713,1815,1832,2016`, `app/ui.tsx:172,177`. Предупреждения сборку не останавливают и не исправлялись. |
| `pnpm lint` | FAILED — EXISTING BASELINE | Не дошёл до script по той же pnpm build-policy ошибке. |
| Фактическое содержимое lint script: `next lint` | PASSED | Завершилось без lint errors, с теми же восемью `no-img-element`. Дополнительно Next сообщил, что `next lint` deprecated и будет удалён в Next.js 16. |
| Automated tests | NOT APPLICABLE | `scripts.test` отсутствует; test suite/fixtures в baseline не обнаружены. Поэтому тесты не запускались и не считаются passed. |

Build создал только ignored `.next`; отслеживаемые runtime/config-файлы не изменились. Исправления warnings, pnpm policy и lint script намеренно не выполнялись.

## Dev server и страницы

`pnpm dev` отдельно не повторялся: pnpm wrapper уже воспроизвёл одинаковый pre-script blocker для build/lint. Для проверки самого приложения запущено точное содержимое script: `node node_modules/next/dist/bin/next dev --hostname 127.0.0.1 --port 3000`. Next 15.5.12 стал Ready за 2,7 сек. После проверок процесс штатно остановлен.

| Route / проверка | Статус | HTTP / наблюдение |
| --- | --- | --- |
| `/` | PASSED | HTTP 200. Browser: загрузились 35 template entries в группах «Вконтакте», «Старт», «Одноклассники»; preview-карточки и правая инфографика видимы. Очевидных missing assets/hydration crash нет. |
| `/t/baseline-route-check` | PASSED | HTTP 200 подтверждает route shell; не подтверждает schema неизвестного ID. |
| `/t/2005%3A94` | PASSED | HTTP 200. Browser загрузил `TPL_ok_post_1_1`, default rich text, size/color controls, photo controls и template preview. Generate не запускался. |
| `/admin/sync` без token | PASSED | HTTP 404 и стандартная 404-страница. Это ожидаемое защитное поведение current implementation, а не подтверждение работы авторизованной admin page. |
| Browser console | PASSED | Для `/`, существующего editor route и неавторизованного admin route ошибок и warnings в доступном console log не зафиксировано. |
| Dev server log | PASSED | Все выполненные запросы зарегистрированы с ожидаемыми status; uncaught server errors и runtime crashes не наблюдались. |

Визуальная проверка ограничена одним desktop viewport, текущими загруженными данными и двумя рабочими экранами. Она не является pixel comparison с `assets/screens` и не доказывает отсутствие missing assets во всех 35 шаблонах.

## Безопасно проверенные API

| Endpoint | Статус | Результат и граница вывода |
| --- | --- | --- |
| `GET /api/health` | PASSED | HTTP 200, JSON 15 bytes. Current endpoint — liveness response, не measured health зависимостей. |
| `GET /api/templates` | PASSED | HTTP 200, JSON array из 35 entries; первый объект имеет `id`, `name`, `page`, `previewSignedUrl`. Выполняет read/sign operation без записи production data. |
| `GET /api/templates/2005%3A94/schema` | PASSED | HTTP 200, JSON 556 bytes. Подтверждена выдача schema одного существующего template. |
| `GET /api/photobank/browse?limit=1&offset=0` | PASSED | HTTP 200, JSON 191 bytes. Проверено только чтение корня с малым limit; дерево, pagination и download не проверялись. |
| `GET /api/admin/status` без auth | PASSED | HTTP 403. Подтверждён отказ неавторизованному запросу. |
| `GET /api/admin/cache` без auth | PASSED | HTTP 403. Подтверждён отказ неавторизованному запросу. |

Не вызывались POST upload/generate/admin sync/cache, photobank resolve, Figma diagnostic и preview mutation routes. Подписанные URL, содержимое секретов и полные внешние ответы не выводились.

## Existing baseline defects и предупреждения

1. **Pnpm 11 install/script policy.** `package.json.pnpm.onlyBuiltDependencies` игнорируется; frozen install завершается `ERR_PNPM_IGNORED_BUILDS`. Поэтому стандартные `pnpm build/lint/dev` в этой среде не являются рабочими entry points, хотя установленные binaries запускаются напрямую.
2. **Невоспроизводимая версия runtime.** Node/pnpm не закреплены в репозитории; результат зависит от среды. Текущий Node 22 удовлетворяет фактическим `>=20` требованиям части lock dependencies, но не является утверждённым production runtime.
3. **Lint command deprecated.** `next lint` работает на Next 15.5.12, но Next предупреждает об удалении в версии 16.
4. **Восемь `no-img-element`.** Build/lint предупреждают об обычных `<img>` в каталоге, editor и UI helpers.
5. **Automated tests отсутствуют.** Нет test script, fixture catalog или CI evidence.
6. **Runtime data dependency сохраняется.** Успешные catalog/editor checks зависят от доступных `.env.local`, B2 snapshots и public Yandex data; это не подтверждение автономности TARGET.

Эти пункты зафиксированы, но не исправлены. Риски архитектуры и безопасности подробно перечислены в `TECH_DEBT_2026.md`; статус этой runtime-проверки не меняет их приоритет.

## Что не проверено

| Проверка | Статус | Причина |
| --- | --- | --- |
| Production server `next start` | NOT RUN | Dev и production build уже дали необходимый baseline; запуск второго процесса не добавляет проверку реального hosting. |
| Authenticated `/admin/sync` | BLOCKED | Не передавались и не выводились admin secrets; destructive sync запрещён задачей. |
| Upload/generate/download/crop interaction | NOT RUN | Может создать внешние `uploads/`/`renders/`; production mutation исключена. Editor проверен до этих действий. |
| Figma live API | NOT RUN | Не нужен для read-only user flow и мог бы раскрыть operational errors/credential scope; TARGET должен отказаться от runtime-зависимости. |
| Photobank download/preview каждого типа | NOT RUN | Проверено только безопасное browse; массовые внешние чтения не нужны для baseline. |
| Все 35 templates | NOT RUN | Один существующий schema/editor case и каталог; batch visual validation требует fixtures и golden strategy. |
| Mobile/несколько desktop размеров, keyboard/a11y | NOT RUN | Минимальная runtime-проверка; никаких UI изменений в задаче нет. |
| Load/performance/memory | BLOCKED | Нет утверждённой инфраструктуры и resource budgets; один dev timing не переносится в production. |
| Production hosting, headers, ACL/lifecycle | BLOCKED | Нет read-only подтверждения Vercel/периметра/storage policy в этой задаче. |
| Security penetration/CVE/history scan | NOT RUN | Не входит в безопасную runtime smoke-проверку; static review уже ограниченно зафиксирован в debt document. |

## Проверки, которые нужно повторять после изменений

- На закреплённых Node/pnpm: frozen install, официальный `pnpm build`, рабочий lint command и test suite.
- HTTP и browser smoke для `/`, реального editor route и защищённой admin-зоны; отсутствие hydration/console/server errors.
- `health`, catalog, schema и photobank read contracts, включая ошибки внешних сервисов.
- Golden renderer cases и structural fixtures из `REGRESSION_BASELINE_2026.md` до и после отделения storage/Figma model.
- После появления безопасного test storage: upload → crop → generate → download, cleanup и fault injection без production writes.
- После появления package import: validate/stage/atomic commit/rebuild index, concurrent writer и retry/idempotency.
- После появления target/print: multi-format partial/retry/ZIP и PDF preflight на утверждённых параметрах.
