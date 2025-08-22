# Расширенные системы для Match-3 игры

Этот документ описывает расширенную логику, добавленную к базовой игре Match-3, включая систему уведомлений, покупок, инвайтов и управления рекламой.

## 🚀 Новые возможности

### 1. Система уведомлений (NotificationManager)
- **Типы уведомлений**: Success, Error, Warning, Info
- **Автоматическое скрытие** с настраиваемой длительностью
- **Ограничение количества** одновременно отображаемых уведомлений
- **Анимации появления/исчезновения**

### 2. Система покупок (PurchaseManager)
- **Поле ввода Item ID** для покупок
- **Предустановленные товары**: бустеры, премиум функции, удаление рекламы
- **Интеграция с Yandex SDK** для платежей
- **Автоматическое применение эффектов** после покупки

### 3. Система инвайтов (InviteManager)
- **Настраиваемые параметры** через UI
- **Поддержка различных режимов игры** и сложности
- **Бонусы за приглашения** (дополнительные бустеры)
- **Сохранение и загрузка** параметров инвайтов

### 4. Система квот рекламы (AdQuotaManager)
- **Дневные, часовые и сессионные лимиты** для разных типов рекламы
- **Антиспам защита** с настраиваемыми параметрами
- **Умные триггеры** для показа рекламы
- **Интеграция с игровыми событиями**

## 📁 Структура файлов

```
scripts/
├── NotificationManager.gd      # Система уведомлений
├── PurchaseManager.gd          # Управление покупками
├── PurchaseUI.gd               # UI для покупок
├── InviteManager.gd            # Управление инвайтами
├── InviteParamsUI.gd           # UI для параметров инвайтов
├── AdQuotaManager.gd           # Управление квотами рекламы
└── GameSystemsManager.gd       # Главный менеджер всех систем
```

## 🔧 Установка и настройка

### 1. Добавление в проект
Добавьте `GameSystemsManager.gd` в корневую сцену вашего проекта:

```gdscript
# В главной сцене
var game_systems: GameSystemsManager

func _ready():
    game_systems = GameSystemsManager.new()
    add_child(game_systems)
```

### 2. Автоматическая инициализация
Система автоматически:
- Создает все необходимые менеджеры
- Подключается к существующим системам (YandexSDK, SaveManager)
- Инициализирует UI компоненты
- Загружает сохраненные данные

## 💰 Использование системы покупок

### Доступные товары
```gdscript
# Получить список доступных товаров
var items = game_systems.get_available_items()

# Инициировать покупку
game_systems.initiate_purchase("booster_pack")
game_systems.initiate_purchase("remove_ads")
```

### Предустановленные товары
- **booster_pack**: Набор бустеров (5 каждого типа)
- **premium_booster**: Неограниченные бустеры на 24 часа
- **remove_ads**: Постоянное удаление рекламы

### UI компонент
```gdscript
# Получить UI для покупок
var purchase_ui = game_systems.get_purchase_ui()

# Показать/скрыть
purchase_ui.show()
purchase_ui.hide()

# Установить Item ID
purchase_ui.set_item_id("booster_pack")
```

## 🎯 Использование системы инвайтов

### Настройка параметров
```gdscript
# Установить параметр инвайта
game_systems.set_invite_param("game_mode", "time_attack")
game_systems.set_invite_param("difficulty", "hard")
game_systems.set_invite_param("booster_bonus", "true")

# Отправить инвайт
game_systems.send_invite()
```

### Доступные параметры
- **game_mode**: classic, time_attack, puzzle, endless
- **difficulty**: easy, normal, hard, expert
- **booster_bonus**: true, false
- **daily_challenge**: true, false
- **custom_theme**: default, halloween, christmas, summer
- **special_rules**: none, no_boosters, time_limit, score_target

### UI компонент
```gdscript
# Получить UI для параметров инвайтов
var invite_ui = game_systems.get_invite_params_ui()

# Показать/скрыть
invite_ui.show()
invite_ui.hide()
```

## 📺 Использование системы рекламы

### Триггеры показа рекламы
```gdscript
# Зарегистрировать игровое событие
game_systems.trigger_game_event("game_start")
game_systems.trigger_game_event("game_over", {"score": 150})
game_systems.trigger_game_event("booster_used")
game_systems.trigger_game_event("long_no_match_series", {"moves_count": 15})
```

### Проверка квот
```gdscript
# Проверить, можно ли показать рекламу
if game_systems.can_show_ad("interstitial"):
    game_systems.show_ad("interstitial", "game_over")

# Получить статус квот
var status = game_systems.get_ad_quota_status("interstitial")
print("Осталось показов сегодня: ", status.daily_remaining)
```

### Настройка квот
```gdscript
var ad_manager = game_systems.get_ad_quota_manager()

# Установить дневной лимит
ad_manager.set_ad_quota("interstitial", "daily_limit", 10)

# Настроить антиспам
ad_manager.set_anti_spam_setting("max_ads_per_hour", 5)

# Настроить триггер
ad_manager.set_ad_trigger_setting("game_over", "probability", 0.8)
```

## 🔔 Использование системы уведомлений

### Прямое использование
```gdscript
# Показать уведомление
game_systems.show_notification("Успешно сохранено!", "success")
game_systems.show_notification("Ошибка загрузки", "error")
game_systems.show_notification("Внимание!", "warning")
game_systems.show_notification("Информация", "info")
```

### Через менеджер
```gdscript
var notification_manager = game_systems.get_notification_manager()

# Показать с кастомной длительностью
notification_manager.show_success("Покупка завершена!", 5.0)
notification_manager.show_error("Недостаточно средств", 10.0)
```

## 🔗 Интеграция с существующими системами

### С UIManager
```gdscript
# Интеграция с существующим UI
game_systems.integrate_with_ui_manager()

# Обновление UI после покупки
if ui_manager.has_method("_update_booster_labels"):
    ui_manager._update_booster_labels()
```

### С BoardManager
```gdscript
# Интеграция с игровым полем
game_systems.integrate_with_board_manager()

# Регистрация событий игры
game_systems.trigger_game_event("tile_matched")
game_systems.trigger_game_event("combo_achieved", {"combo_count": 5})
```

## 📊 Аналитика и логирование

### Логирование показов рекламы
Система автоматически логирует:
- Время показа рекламы
- Причину показа
- Тип рекламы
- Статистику по квотам

### Доступ к данным
```gdscript
# Получить аналитику рекламы
var save_manager = get_node("/root/SaveManager")
var settings = save_manager.get_settings()
if settings.has("ad_analytics"):
    var analytics = settings.ad_analytics
    print("Показов рекламы: ", analytics.size())
```

## 🧪 Тестирование систем

### Тестовые методы
```gdscript
# Тест системы уведомлений
game_systems.test_notification_system()

# Тест системы покупок
game_systems.test_purchase_system()

# Тест системы инвайтов
game_systems.test_invite_system()

# Тест системы рекламы
game_systems.test_ad_system()
```

## ⚙️ Настройка и кастомизация

### Изменение квот рекламы
```gdscript
var ad_manager = game_systems.get_ad_quota_manager()

# Установить новые лимиты
ad_manager.set_ad_quota("interstitial", "daily_limit", 8)
ad_manager.set_ad_quota("rewarded", "hourly_limit", 4)
ad_manager.set_ad_quota("banner", "session_limit", 15)
```

### Настройка триггеров
```gdscript
# Изменить вероятность показа рекламы
ad_manager.set_ad_trigger_setting("game_over", "probability", 0.6)
ad_manager.set_ad_trigger_setting("booster_used", "probability", 0.3)

# Настроить интервалы
ad_manager.set_ad_trigger_setting("game_start", "min_games_between", 3)
ad_manager.set_ad_trigger_setting("level_complete", "min_levels_between", 5)
```

### Кастомизация UI
```gdscript
var purchase_ui = game_systems.get_purchase_ui()

# Изменить тексты кнопок
purchase_ui.set_button_texts("Купить", "Отмена")

# Изменить размеры элементов
purchase_ui.set_input_field_size(250, 35)
purchase_ui.set_button_size(120, 45)
```

## 🐛 Устранение неполадок

### Проблемы с инициализацией
- Убедитесь, что `GameSystemsManager` добавлен в корневую сцену
- Проверьте, что все зависимости доступны (YandexSDK, SaveManager)
- Проверьте консоль на наличие ошибок

### Проблемы с покупками
- Проверьте доступность Yandex SDK
- Убедитесь, что Item ID корректный
- Проверьте настройки платежей в SDK

### Проблемы с рекламой
- Проверьте квоты и лимиты
- Убедитесь, что антиспам не блокирует показ
- Проверьте настройки триггеров

## 📈 Расширение функциональности

### Добавление новых товаров
```gdscript
# В PurchaseManager.gd
var available_items: Dictionary = {
    "new_item": {
        "name": "New Item",
        "description": "Description of new item",
        "price": "199",
        "currency": "RUB",
        "custom_effect": true
    }
}
```

### Добавление новых параметров инвайтов
```gdscript
# В InviteManager.gd
var available_params: Dictionary = {
    "new_param": ["value1", "value2", "value3"]
}
```

### Добавление новых триггеров рекламы
```gdscript
# В AdQuotaManager.gd
var ad_triggers: Dictionary = {
    "new_trigger": {
        "enabled": true,
        "probability": 0.5,
        "custom_condition": true
    }
}
```

## 📝 Лицензия

Этот код распространяется под той же лицензией, что и основной проект.

## 🤝 Поддержка

Для вопросов и предложений по расширенным системам обращайтесь к разработчикам проекта.