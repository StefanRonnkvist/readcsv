import 'package:sembast/sembast.dart';

import 'database_factory_provider_io.dart'
    if (dart.library.html) 'database_factory_provider_web.dart';

/// Opens the Sembast database using the implementation for this platform.
Future<Database> openAppDatabase() => openAppDatabaseImpl();
