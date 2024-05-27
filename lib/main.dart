import 'package:flutter/material.dart';
import 'package:tugas_akhir_tpm_123210060/Page/Login.dart';
import 'package:tugas_akhir_tpm_123210060/Service/NotificationService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liga 1 App',
      home: Login(),
    );
  }
}