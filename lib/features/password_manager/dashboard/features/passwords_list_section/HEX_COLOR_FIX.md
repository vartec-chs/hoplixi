## Исправление FormatException при парсинге hex цветов

### Проблема
В коде возникала ошибка `FormatException: Invalid radix-16 number` при попытке парсить hex цвета из базы данных, которые хранятся в формате `#0f64a8`.

### Причина
Функция `int.parse()` с `radix: 16` не может обработать символ `#` в начале строки.

### Решение
1. **Добавлена утилитарная функция** `parseHexColor()` для безопасного парсинга hex цветов:
   ```dart
   Color parseHexColor(String? hexColor, Color fallbackColor) {
     if (hexColor == null || hexColor.isEmpty) return fallbackColor;
     
     try {
       // Убираем # если есть и парсим hex
       final cleanHex = hexColor.replaceAll('#', '');
       return Color(int.parse(cleanHex, radix: 16));
     } catch (e) {
       // Если не удалось распарсить, возвращаем fallback цвет
       return fallbackColor;
     }
   }
   ```

2. **Обновлены методы** `_buildTagChip()` и `_buildCategoryChip()` для использования новой утилитарной функции.

3. **Добавлена обработка ошибок** - если цвет не удается распарсить, используется fallback цвет из темы.

### Преимущества
- ✅ Устраняет FormatException при парсинге hex цветов
- ✅ Добавляет fallback механизм для некорректных цветов
- ✅ Упрощает код и делает его более читаемым
- ✅ Предотвращает подобные ошибки в будущем

### Изменённые файлы
- `passwords_list.dart` - добавлена утилитарная функция и обновлены методы построения чипов