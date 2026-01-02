import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

abstract class PlatformUtils {
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool get isWeb => kIsWeb;
}
