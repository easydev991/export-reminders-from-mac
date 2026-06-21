## Context

Проект — SPM-only Swift CLI для macOS 14+. Сборка через `swift build`, подпись через `codesign` с entitlement'ом для доступа к EventKit. Инструменты разработки: SwiftFormat (0.61+), Periphery. Makefile должен автоматизировать два сценария: быстрый запуск экспорта и проверку/установку инструментов.

## Goals / Non-Goals

**Goals:**
- `make export` — сборка release, подпись с entitlement, запуск экспорта в JSON в корень проекта
- `make setup` — проверка Homebrew, SwiftFormat, Periphery; установка каждого отсутствующего по диалогу y/N
- Возможность передать аргументы в CLI через `make export ARGS="--format csv --output ./reminders.csv"`
- Минимальная сложность: POSIX-совместимый Makefile, без внешних зависимостей

**Non-Goals:**
- Не менять Swift-код проекта
- Не добавлять CI/CD
- Не автоматизировать tccutil (требует ручного диалога macOS)

## Decisions

1. **SPM-фазы в make export**: build → codesign → run
   - Каждая команда выполняется последовательно, `&&` для остановки при ошибке
   - Подпись обязательна только для release-сборки — macOS 14+ блокирует EventKit без entitlement

2. **Путь к бинарнику**: `.build/release/ExportReminders` — стандартный путь SPM для release-сборки

3. **Аргументы CLI**: переменная `ARGS` с умолчанием
   ```makefile
   ARGS ?= --format json --output ./reminders.json
   ```
   Пользователь: `make export ARGS="--format csv --output ./reminders.csv"`

4. **Проверка Homebrew**: через `which brew` — стандартный способ, работает с любым расположением brew

5. **Проверка инструментов**: через `which swiftformat` / `which periphery` — инструменты могут быть установлены не только через brew, но и через другие менеджеры

6. **Диалог установки**: `read -p "..."` с проверкой ответа `y`/`Y` — POSIX-совместимо, не требует внешних утилит
   - Каждый инструмент — отдельный диалог, как требует пользователь
   - Установка через `brew install <formula>`

7. **Единый формат команд**: Makefile использует `.PHONY` цели, так как не создаёт файлы

## Risks / Trade-offs

- **[Риск] Пользователь без sudo не сможет установить инструменты через brew** → Makefile выполнит `brew install`, который сам запросит sudo если нужно; сообщение об ошибке unix пройдёт на stdout
- **[Риск] SwiftFormat может быть установлен из другого источника (Mint, MacPorts)** → `which` находит любой; при установке brew перезапишет симлинк
- **[Риск] macOS Gatekeeper может блокировать неподписанный бинарник** → описывается в README как отдельный шаг; make export подписывает бинарник
