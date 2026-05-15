# Инструкция по сборке APK на своём ПК

Этот проект написан на Flutter. Чтобы собрать APK-файл для Android на своём компьютере, выполните следующие шаги:

## Требования

1. **Flutter SDK** (версия 3.x или выше)
   - Скачайте с официального сайта: https://docs.flutter.dev/get-started/install
   - Добавьте Flutter в PATH вашей системы

2. **Android Studio** (или только Android SDK)
   - Скачайте с: https://developer.android.com/studio
   - Установите Android SDK и Android SDK Build-Tools

3. **Java Development Kit (JDK)** версии 11 или выше
   - Скачайте с: https://www.oracle.com/java/technologies/downloads/

4. **Настроенный эмулятор Android** или подключённое физическое устройство (опционально, только для тестирования)

## Настройка окружения

### 1. Проверка установки Flutter

Откройте терминал (Command Prompt, PowerShell или Terminal) и выполните:

```bash
flutter doctor
```

Команда покажет состояние вашего окружения. Убедитесь, что:
- ✅ Flutter установлен корректно
- ✅ Android toolchain настроен
- ✅ Android SDK установлен
- ✅ Устройство (эмулятор или физическое) обнаружено (опционально)

Если есть проблемы, `flutter doctor` подскажет, что нужно исправить.

### 2. Настройка Android SDK

Если Android SDK не найден:
1. Откройте Android Studio
2. Перейдите в **Tools → SDK Manager**
3. Установите:
   - Android SDK Platform (последнюю версию)
   - Android SDK Build-Tools
   - Android Emulator (если нужен эмулятор)

Запомните путь к SDK (обычно `C:\Users\<ВашеИмя>\AppData\Local\Android\Sdk` на Windows или `~/Library/Android/sdk` на macOS).

Установите переменную окружения:
```bash
# Windows (PowerShell от имени администратора)
setx ANDROID_HOME "C:\Users\<ВашеИмя>\AppData\Local\Android\Sdk"
setx PATH "%PATH%;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools\bin"

# macOS/Linux (~/.bashrc или ~/.zshrc)
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools/bin"
```

## Сборка APK

### Шаг 1: Клонирование и переход в директорию проекта

```bash
cd /path/to/eco_habit_diary
```

### Шаг 2: Установка зависимостей

```bash
flutter pub get
```

Эта команда загрузит все необходимые пакеты, указанные в `pubspec.yaml`.

### Шаг 3: Проверка проекта

```bash
flutter doctor
```

Убедитесь, что нет критических ошибок.

### Шаг 4: Сборка APK

#### Для отладки (Debug APK)

```bash
flutter build apk --debug
```

APK-файл будет создан в:
```
build/app/outputs/flutter-apk/app-debug.apk
```

#### Для релиза (Release APK)

```bash
flutter build apk --release
```

APK-файл будет создан в:
```
build/app/outputs/flutter-apk/app-release.apk
```

#### Для конкретного устройства (ABI)

Если хотите уменьшить размер APK, можно собрать только для конкретных архитектур:

```bash
flutter build apk --split-per-abi
```

Будут созданы отдельные APK для каждой архитектуры:
- `app-armeabi-v7a-release.apk` (для старых устройств)
- `app-arm64-v8a-release.apk` (для современных устройств)
- `app-x86_64-release.apk` (для эмуляторов)

### Шаг 5: Проверка собранного APK

Подключите Android-устройство по USB (с включённой отладкой по USB) или запустите эмулятор, затем:

```bash
flutter install
```

Или вручную установите APK через ADB:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Дополнительные команды

### Очистка сборки

Если возникают проблемы со сборкой, очистите кэш:

```bash
flutter clean
flutter pub get
```

### Сборка App Bundle (для Google Play)

Для публикации в Google Play Store рекомендуется использовать Android App Bundle:

```bash
flutter build appbundle --release
```

Файл будет создан в:
```
build/app/outputs/bundle/release/app-release.aab
```

### Просмотр логов

Для отладки запущенного приложения:

```bash
flutter logs
```

## Возможные проблемы и решения

### 1. Ошибка "SDK not found"

Убедитесь, что переменная окружения `ANDROID_HOME` установлена правильно и указывает на папку с Android SDK.

### 2. Ошибка "License not accepted"

Примите лицензии Android SDK:

```bash
flutter doctor --android-licenses
```

Нажимайте `y` для принятия всех лицензий.

### 3. Ошибка при сборке Gradle

Обновите Gradle и плагин Android в файлах:
- `android/build.gradle`
- `android/app/build.gradle`

Или выполните:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### 4. Недостаточно памяти

Увеличьте память для Gradle в файле `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx2048m -XX:MaxPermSize=512m
```

### 5. Проблемы с Firebase

Убедитесь, что файлы конфигурации Firebase находятся в проекте:
- `android/app/google-services.json` (для Android)
- `ios/GoogleService-Info.plist` (для iOS)

## Быстрая команда для сборки

Для быстрой сборки релизного APK одной командой:

```bash
flutter clean && flutter pub get && flutter build apk --release
```

Готовый APK будет находиться в папке `build/app/outputs/flutter-apk/`.

## Примечания

- Первая сборка может занять несколько минут из-за загрузки зависимостей и компиляции
- Релизный APK оптимизирован и имеет меньший размер, чем debug-версия
- Для публикации в Google Play используйте `appbundle`, а не `apk`
- Debug-версия содержит отладочную информацию и не должна использоваться для распространения
