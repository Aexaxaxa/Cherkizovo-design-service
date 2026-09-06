# Baseline версии 2026

- Дата создания development-линии: 2026-09-07 (Asia/Yekaterinburg).
- Репозиторий: `Aexaxaxa/cherkizovo-design-service`.
- Исходная ветка: `main`, подтверждённая fetch как актуальный `origin/main`.
- Exact baseline SHA: `ab8119ac4495e6994e3730f83e9a8a9121967a80` (`Final-service`).
- Annotated legacy tag: `legacy-pre-2026`.
- Release: [Stable service before 2026 redevelopment](https://github.com/Aexaxaxa/cherkizovo-design-service/releases/tag/legacy-pre-2026).
- Интеграционная ветка: `develop-2026`, создана и впервые опубликована на этом же SHA.
- При создании `main == develop-2026` по commit, истории и содержимому; `git diff main develop-2026` был пустым.
- Документация подготовки создаётся отдельно в `chore/2026-development-bootstrap` и поступает через PR в `develop-2026`.

Это зафиксированная исходная точка для будущего migration audit. В рамках подготовки UI, бизнес-логика, storage, Figma integration и runtime-код не меняются.

## Стек по реальному package.json

Ниже именно объявленные диапазоны зависимостей baseline, а не утверждение об установленных версиях:

| Компонент | Диапазон |
| --- | --- |
| Next.js | `^15.4.0` |
| React / react-dom | `^19.0.0` |
| TypeScript (dev) | `^5.7.0` |
| sharp | `^0.34.0` |
| opentype.js | `^1.3.4` |
| react-easy-crop | `^5.5.6` |
| @aws-sdk/client-s3 | `^3.876.0` |
| @aws-sdk/s3-request-presigner | `^3.876.0` |
| ESLint (dev) | `^9.17.0` |
| eslint-config-next (dev) | `^15.4.0` |
| @types/node (dev) | `^22.10.0` |
| @types/react / @types/react-dom (dev) | `^19.0.2` |

Приложение использует Next.js App Router и Node.js server API. Версия Node runtime в package.json не закреплена; `@types/node` её не определяет. Есть `pnpm-lock.yaml` и pnpm.onlyBuiltDependencies (`sharp`, `unrs-resolver`). Скрипты: `dev: next dev`, `build: next build`, `start: next start`, `lint: next lint`. Test script отсутствует. Работоспособность lint/build не проверялась в документационной подготовке; запись скрипта не означает успешную проверку.

## Наблюдаемая структура системы

| Файл или каталог | Реально найденное назначение |
| --- | --- |
| `app/page.tsx`, `app/layout.tsx`, `app/globals.css`, `app/ui.tsx` | Главная страница, layout, глобальные стили и UI |
| `app/t/[id]/page.tsx`, `RichColorTextField.tsx` | Редактор выбранного шаблона и текстовых полей |
| `app/admin/sync/` | Административный интерфейс синхронизации |
| `app/api/templates/route.ts`, `app/api/templates/[id]/schema/route.ts` | Шаблоны и схемы на основе snapshots |
| `app/api/generate/route.ts` | Валидация, обработка фото через sharp, вызов renderUniversalTemplate, сохранение результата |
| `lib/universalEngine.ts`, `lib/textLayout.ts`, `lib/richTextLayout.ts`, `lib/richTextSegments.ts` | Рендеринг и работа с текстом |
| `lib/snapshotStore.ts` | Ключи и чтение/запись JSON templates, frames, schemas и assets |
| `lib/s3.ts`, `lib/cache.ts`, `lib/memoryCache.ts` | S3-совместимое B2-хранилище, signed URL, кэш |
| `app/api/admin/sync/route.ts`, `lib/figmaClient.ts`, другие `lib/figma*.ts` | Figma API и синхронизация snapshots/assets |
| `app/api/admin/status/`, `app/api/admin/cache/`, `lib/adminSyncState.ts` | Статус синхронизации и управление кэшем |
| `app/api/photobank/`, `lib/photobank.ts` | Фотобанк через Yandex Disk public API |
| `app/api/upload/`, `app/api/previews/`, `app/api/figma/`, `app/api/health/` | Дополнительные API-маршруты |
| `assets/fonts/gothampro/`, `assets/icons/`, `assets/screens/` | Шрифты, SVG-иконки и изображения экранов |
| `types/`, `next.config.ts`, `tsconfig.json` | Type declarations и конфигурация проекта |

Подтверждённый кодом основной pipeline: admin sync получает Figma-данные и записывает snapshots в B2; templates API читает snapshots; generate API обрабатывает фото, вызывает universal engine и сохраняет результат в B2. `lib/photobank.ts` обращается к Yandex Disk public API. `next.config.ts` включает Gotham Pro TTF в tracing для `/api/generate`.

## Границы фиксации

Git tag сохраняет отслеживаемые исходники, а не production data, секреты или внешние файлы. `0_documents.zip` и `0_documents/` остаются пользовательскими локальными untracked-объектами и не входят в baseline commit или новые PR.

В baseline нет отслеживаемой конфигурации Vercel, найденной по именам `*vercel*`, и доступного Vercel MCP в сеансе подготовки нет. Позднее GitHub PR #2 подтвердил срабатывание Vercel-интеграции для рабочей ветки: `Vercel Preview Comments` — SUCCESS; статус `Vercel` при первом чтении — PENDING, со ссылкой на deployment проекта `a-feds-projects/cherkizovo-design-service`. Фактическая Production branch и общая политика Preview требуют отдельной read-only проверки. GitHub default branch подтверждена как `main`; это само по себе не доказывает Vercel Production branch.
