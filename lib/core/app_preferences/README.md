### App Preferences
A simple wrapper around SharedPreferences with typed keys and change listeners.

```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init(); // важно
  runApp(MyApp());
}

// Сохранить
await Prefs.set(Keys.token, 'abc123');
await Prefs.set(Keys.counter, 42);
await Prefs.set(Keys.favorites, ['a', 'b']);

// Прочитать
String? token = Prefs.get<String>(Keys.token);
int? c = Prefs.get<int>(Keys.counter);

// Слушать изменения
final tokenListenable = Prefs.listen<String>(Keys.token);
tokenListenable.addListener(() {
  print('Token changed: ${tokenListenable.value}');
});
tokenListenable.dispose(); // не забыть вызвать при удалении виджета
```