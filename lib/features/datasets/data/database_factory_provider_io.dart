import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// Opens the app database in the platform application-documents directory.
Future<Database> openAppDatabaseImpl() async {
  final directory = await getApplicationDocumentsDirectory();
  final dbPath = p.join(directory.path, 'csvreader.db');
  return databaseFactoryIo.openDatabase(dbPath);
}
