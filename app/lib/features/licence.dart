import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;

Future<void> registerEulaLicense() async {
  try {
    final eula = await rootBundle.loadString('assets/EULA.txt');
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(['EcoPulse (EULA)'], eula);
    });
  } catch (_) {}
}
