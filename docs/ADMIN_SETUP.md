# 🔐 Как назначить администратора

## Вариант 1: Через Firebase Console (Рекомендуется)

1. **Откройте Firebase Console:**
   - Перейдите на [console.firebase.google.com](https://console.firebase.google.com)
   - Выберите свой проект TANDAU

2. **Откройте Firestore Database:**
   - В левом меню выберите **"Firestore Database"**
   - Перейдите в коллекцию **"users"**

3. **Найдите пользователя:**
   - Найдите документ с нужным email
   - Нажмите на документ чтобы открыть его

4. **Добавьте/измените поле `role`:**
   - Найдите поле `role` (или создайте если его нет)
   - Установите значение: **`admin`** (строка)
   - Нажмите **"Update"** или **"Save"**

5. **Готово!**
   - Пользователь перелогинится → станет админом
   - Увидит секцию "Инструменты разработчика"

---

## Вариант 2: Первый админ при регистрации

### Создайте тестового админа:

**Email:** `admin@tandau.kz`  
**Password:** `Admin123!`  
**Role:** Автоматически установится `admin` при регистрации

### Затем измените в Firebase:
1. Зарегистрируйтесь в приложении
2. Откройте Firebase Console → Firestore → users
3. Найдите созданного пользователя
4. Измените поле `role` на `admin`

---

## Проверка:

1. Войдите в приложение под админом
2. Перейдите на вкладку **"Profile"**
3. Прокрутите вниз
4. Должна появиться секция:
   ```
   🔧 Инструменты разработчика
   
   📤 Миграция данных
   ```

5. **У обычных пользователей эта секция НЕ ВИДНА**

---

## Структура в Firestore:

```json
users/{userId}/
{
  "uid": "abc123...",
  "name": "Admin User",
  "email": "admin@tandau.kz",
  "phone": "+7...",
  "role": "admin",     ← ВАЖНО!
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "favoriteUniversities": []
}
```

---

## Роли в системе:

- **`user`** (по умолчанию) - обычный пользователь, студент
- **`admin`** - администратор, разработчик
  - Видит "Инструменты разработчика"
  - Может делать миграцию данных
  - Полный доступ ко всем функциям

---

## Автоматизация (опционально):

Можно создать Cloud Function в Firebase, которая автоматически назначает админа по определенному email:

```javascript
// Firebase Cloud Function
exports.checkAdminEmails = functions.auth.user().onCreate(async (user) => {
  const adminEmails = ['admin@tandau.kz', 'your@email.com'];
  
  if (adminEmails.includes(user.email)) {
    await admin.firestore().collection('users').doc(user.uid).update({
      role: 'admin'
    });
  }
});
```
