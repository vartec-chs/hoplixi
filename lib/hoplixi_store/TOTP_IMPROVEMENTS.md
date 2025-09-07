# Улучшения модели TOTP

## Добавленные поля

### Новые поля для совместимости с otpauth URI:

1. **`issuer`** - Название сервиса (например, "Google", "GitHub", "Microsoft")
   - Используется для генерации otpauth URI
   - Помогает пользователю идентифицировать источник кода

2. **`account_name`** - Идентификатор аккаунта (email, username)
   - Дополняет issuer для полной идентификации
   - Стандартная часть otpauth URI

3. **`type`** - Тип одноразового пароля (TOTP/HOTP)
   - `totp` - Time-based OTP (по умолчанию)
   - `hotp` - HMAC-based OTP (счетчиковый)

4. **`counter`** - Счетчик для HOTP
   - Обязательное поле для типа HOTP
   - Null для типа TOTP
   - Увеличивается при каждой генерации кода

### Улучшенная безопасность секрета:

5. **`secret_nonce`** - Nonce для шифрования
6. **`secret_cipher`** - Зашифрованный секрет
7. **`secret_tag`** - Тег аутентификации

Вместо одного поля `secret_cipher` теперь используется трехкомпонентное шифрование для повышенной безопасности.

## Преимущества

### 1. Полная совместимость с otpauth URI
```
otpauth://totp/GitHub:username?secret=XXXXX&issuer=GitHub&algorithm=SHA1&digits=6&period=30
otpauth://hotp/Google:user@example.com?secret=XXXXX&issuer=Google&counter=0&digits=6
```

### 2. Поддержка HOTP
- Счетчиковые коды для особых случаев
- Constraint обеспечивает корректность данных

### 3. Улучшенная безопасность
- Разделение компонентов шифрования
- Возможность использования authenticated encryption

### 4. Лучший UX
- Отображение issuer и account для быстрой идентификации
- Группировка по сервисам

## Совместимость

Изменения обратно совместимы:
- Новые поля помечены как nullable или имеют значения по умолчанию
- Старые записи будут работать с type='totp' по умолчанию
- Migration позволит обновить существующие данные

## Constraint

```sql
CHECK ((type = 'hotp' AND counter IS NOT NULL) OR (type = 'totp' AND counter IS NULL))
```

Обеспечивает корректность данных для каждого типа OTP.
