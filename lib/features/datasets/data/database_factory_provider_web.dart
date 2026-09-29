import 'package:sembast_web/sembast_web.dart';

/// Opens the browser-backed Sembast database used by web builds.
Future<Database> openAppDatabaseImpl() async {
  return databaseFactoryWeb.openDatabase('csvreader_web.db');
}
