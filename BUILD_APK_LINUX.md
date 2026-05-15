# Инструкция по сборке APK на Linux

## Требования
- Flutter SDK
- Android SDK и Build Tools
- Java Development Kit (JDK 11 или выше)
- Git

## 1. Установка Java (JDK)

### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install openjdk-11-jdk -y
```

### Fedora/RHEL:
```bash
sudo dnf install java-11-openjdk-devel -y
```

### Arch Linux:
```bash
sudo pacman -S jdk11-openjdk
```

Проверьте установку:
```bash
java -version
javac -version
```

## 2. Установка Flutter

### Скачивание Flutter:
```bash
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
```

*Замените версию на актуальную с [официального сайта](https://docs.flutter.dev/get-started/install/linux)*

### Распаковка:
```bash
tar xf flutter_linux_*.tar.xz
sudo mv flutter /opt/flutter
```

### Добавление в PATH:
Откройте файл оболочки (`~/.bashrc`, `~/.zshrc` или `~/.profile`):
```bash
nano ~/.bashrc
```

Добавьте строку в конец файла:
```bash
export PATH="$PATH:/opt/flutter/bin"
```

Примените изменения:
```bash
source ~/.bashrc
```

### Проверка установки:
```bash
flutter doctor
```

## 3. Установка Android SDK

### Вариант A: Через Android Studio (рекомендуется)
1. Скачайте Android Studio с [официального сайта](https://developer.android.com/studio)
2. Установите:
   ```bash
   sudo snap install android-studio --classic
   ```
   Или скачайте `.tar.gz` архив и распакуйте вручную.

3. Запустите Android Studio, откройте **SDK Manager** и установите:
   - Android SDK Platform (минимум API 21)
   - Android SDK Build-Tools
   - Android Emulator (опционально)
   - Android SDK Command-line Tools

### Вариант B: Только Command-line Tools
```bash
mkdir -p ~/Android/Sdk/cmdline-tools
cd ~/Android/Sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-*.zip
mv cmdline-tools latest
```

Настройте переменные окружения (добавьте в `~/.bashrc`):
```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

Примените изменения:
```bash
source ~/.bashrc
```

Установите необходимые компоненты:
```bash
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

Примите лицензии:
```bash
sdkmanager --licenses
```

## 4. Настройка эмулятора (опционально)

Создайте виртуальное устройство:
```bash
avdmanager create avd -n my_avd -k "system-images;android-34;default;x86_64"
```

Запустите эмулятор:
```bash
emulator -avd my_avd
```

Или подключите физическое устройство через USB (включите отладку по USB).

## 5. Подготовка проекта

Перейдите в директорию проекта:
```bash
cd /workspace
```

Установите зависимости:
```bash
flutter pub get
```

Проверьте конфигурацию:
```bash
flutter doctor -v
```

Убедитесь, что все проверки пройдены (особенно Android toolchain).

## 6. Сборка APK

### Debug-версия (для тестирования):
```bash
flutter build apk --debug
```

### Release-версия (для распространения):
```bash
flutter build apk --release
```

### APK для разных архитектур (уменьшает размер):
```bash
flutter build apk --split-per-abi
```

### Сборка с конкретным flavor (если настроено):
```bash
flutter build apk --flavor production --target lib/main_production.dart
```

## 7. Где найти готовый APK

Файлы находятся в директории:
```
build/app/outputs/flutter-apk/
```

- Debug: `app-debug.apk`
- Release: `app-release.apk`
- Split по архитектурам:
  - `app-armeabi-v7a-release.apk` (32-bit ARM)
  - `app-arm64-v8a-release.apk` (64-bit ARM, большинство современных устройств)
  - `app-x86_64-release.apk` (эмуляторы)

## 8. Подпись APK для публикации

Для публикации в Google Play нужно подписать APK ключом.

### Создание keystore:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Вам предложат ввести пароль и данные организации.

### Настройка подписи в проекте

Создайте файл `android/key.properties`:
```properties
storePassword=<ваш_пароль_хранилища>
keyPassword=<ваш_пароль_ключа>
keyAlias=upload
storeFile=/home/<ваш_пользователь>/upload-keystore.jks
```

**Важно:** Добавьте `key.properties` в `.gitignore`, чтобы не коммитить пароли!

Измените `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            ...
        }
    }
}
```

Теперь при сборке release-версии APK будет автоматически подписан.

## 9. Решение проблем

### Ошибка: No connected devices
- Подключите устройство через USB с включённой отладкой
- Или запустите эмулятор
- Проверьте: `flutter devices`

### Ошибка: License not accepted
```bash
sdkmanager --licenses
```

### Ошибка: Gradle build failed
Очистите проект:
```bash
flutter clean
flutter pub get
```

### Ошибка: Недостаточно памяти
Увеличьте память для Gradle в `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4G
```

### Ошибка: Найдены несколько JDK
Убедитесь, что `JAVA_HOME` указывает на правильную версию:
```bash
echo $JAVA_HOME
```

При необходимости установите:
```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

## 10. Полезные команды

```bash
# Проверка состояния
flutter doctor -v

# Список подключённых устройств
flutter devices

# Запуск приложения на устройстве
flutter run

# Просмотр логов
flutter logs

# Обновление Flutter
flutter upgrade

# Анализ кода
flutter analyze
```

## Готово!

Теперь у вас есть полностью настроенная среда для разработки и сборки Flutter-приложений на Linux. Готовый APK можно передать пользователям или загрузить в Google Play Console.
