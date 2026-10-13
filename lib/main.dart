import 'package:bakehub/firebase_options.dart';
import 'package:bakehub/routers/app_routes.dart';
import 'package:bakehub/provider/auth_provider.dart';
import 'package:bakehub/utils/init_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize app settings in Firebase (runs once, safe to call multiple times)
  await initializeAppSettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider.instance,
      child: MaterialApp.router(
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        title: 'BakeHub',
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }
}
