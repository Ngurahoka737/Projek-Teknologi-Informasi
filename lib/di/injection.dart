import 'package:get_it/get_it.dart';

import '../data/services/auth_service.dart';
import '../data/services/db_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> initDependencies() async {
  getIt.registerLazySingleton<DBService>(() => DBService.instance);
  getIt.registerLazySingleton<AuthService>(() => AuthService());
}
