import 'mbus_interface.dart';

import 'mbus_mobile.dart' if (dart.library.html) 'mbus_web.dart';

MBusInterface getMBusService() {
  return createMBusService();
}
