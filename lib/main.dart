import 'package:afoso1/app.dart';
import 'package:afoso1/router/router_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // ProviderScope est obligatoire pour Riverpod
    const ProviderScope(child: AfosoApp()),
  );
}

class AfosoApp extends ConsumerWidget {
  const AfosoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AFOSO Microfinance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
