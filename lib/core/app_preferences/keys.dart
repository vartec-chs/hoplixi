/// 1) Типизированный ключ.
class PrefKey<T> {
  final String key;
  final bool isHiddenUI; // для UI, скрыть из настроек
  final bool isCanEdit; // для UI, можно ли редактировать вручную (json)
  const PrefKey(this.key, {this.isHiddenUI = false, this.isCanEdit = true});
}

enum HomeScreenMode { singleDB, multiDB }

/// Пример списка ключей
class Keys {
  static const PrefKey<bool> autoOpenLastStorage = PrefKey<bool>(
    'auto_open_last_storage',
    isHiddenUI: false,
    isCanEdit: true,
  );
  //theme
  static const PrefKey<String> themeMode = PrefKey<String>(
    'theme_mode',
    isHiddenUI: false,
    isCanEdit: true,
  );

  //is first run
  static const PrefKey<bool> isFirstRun = PrefKey<bool>(
    'is_first_run',
    isHiddenUI: false,
    isCanEdit: false,
  );
  //last app launch time
  static const PrefKey<int> lastAppLaunchTime = PrefKey<int>(
    'last_app_launch_time',
    isHiddenUI: true,
    isCanEdit: false,
  );

  //home screen mode (singleDB/multiDB)
  static const PrefKey<String> homeScreenMode = PrefKey<String>(
    'home_screen_mode',
    isHiddenUI: false,
    isCanEdit: true,
  );
}
