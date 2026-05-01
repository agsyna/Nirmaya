import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'app/providers/home_view_model.dart';
import 'app/providers/access_view_model.dart';
import 'app/providers/share_view_model.dart';
import 'app/views/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nqsatkwnhxksqywtlmfs.supabase.co',
    anonKey: 'sb_publishable__Ap14g4amYKLHDoqcXQM6g_CEpM8mS1',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => AccessViewModel()),
        ChangeNotifierProvider(create: (_) => ShareViewModel()),
      ],
      child: MaterialApp(
        title: 'Nirmaya',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}