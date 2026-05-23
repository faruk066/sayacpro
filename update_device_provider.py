import re

with open('lib/providers/device_provider.dart', 'r') as f:
    content = f.read()

# Add import
import_str = "import 'package:flutter_secure_storage/flutter_secure_storage.dart';\n"
if "package:flutter_secure_storage/flutter_secure_storage.dart" not in content:
    # Add it after shared_preferences
    content = content.replace("import 'package:shared_preferences/shared_preferences.dart';", "import 'package:shared_preferences/shared_preferences.dart';\n" + import_str)

# Modify _performSave
perform_save_pattern = r"Future<void> _performSave\(\) async \{.*?try \{.*?final prefs = await SharedPreferences\.getInstance\(\);(.*?)(await prefs\.setString\('sayac_pro_session', encodedData\);)(.*?)catch \(e\) \{"
perform_save_repl = r"""Future<void> _performSave() async {
    try {
      const secureStorage = FlutterSecureStorage();\1await secureStorage.write(key: 'sayac_pro_session', value: encodedData);\3catch (e) {"""

content = re.sub(perform_save_pattern, perform_save_repl, content, flags=re.DOTALL)


# Modify loadSession
load_session_pattern = r"Future<void> loadSession\(\) async \{.*?try \{.*?final prefs = await SharedPreferences\.getInstance\(\);.*?final String\? sessionJson = prefs\.getString\('sayac_pro_session'\);(.*?)if \(sessionJson == null\) return;"
load_session_repl = r"""Future<void> loadSession() async {
    try {
      const secureStorage = FlutterSecureStorage();
      String? sessionJson = await secureStorage.read(key: 'sayac_pro_session');

      // Fallback and migration for unencrypted SharedPreferences data
      if (sessionJson == null) {
        final prefs = await SharedPreferences.getInstance();
        sessionJson = prefs.getString('sayac_pro_session');
        if (sessionJson != null) {
          // Migrate to secure storage
          await secureStorage.write(key: 'sayac_pro_session', value: sessionJson);
          // Remove plain text data
          await prefs.remove('sayac_pro_session');

          if (kDebugMode) {
            debugPrint('🔒 Oturum verileri güvenli depolamaya taşındı.');
          }
        }
      }
\1if (sessionJson == null) return;"""

content = re.sub(load_session_pattern, load_session_repl, content, flags=re.DOTALL)


# Modify clearSessionData
clear_session_pattern = r"Future<void> clearSessionData\(\) async \{.*?try \{.*?final prefs = await SharedPreferences\.getInstance\(\);.*?await prefs\.remove\('sayac_pro_session'\);"
clear_session_repl = r"""Future<void> clearSessionData() async {
    try {
      const secureStorage = FlutterSecureStorage();
      await secureStorage.delete(key: 'sayac_pro_session');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sayac_pro_session');"""

content = re.sub(clear_session_pattern, clear_session_repl, content, flags=re.DOTALL)

with open('lib/providers/device_provider.dart', 'w') as f:
    f.write(content)
