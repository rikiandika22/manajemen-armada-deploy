import 'package:flutter/material.dart';
import 'package:mobile/app.dart';

import 'package:mobile/core/auth/auth_state.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await AuthState.instance.checkAuthStatus();
  runApp(const App());
}
