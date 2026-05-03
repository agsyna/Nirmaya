import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'app/providers/auth_provider.dart';
import 'app/providers/home_view_model.dart';
import 'app/providers/access_view_model.dart';
import 'app/providers/share_view_model.dart';
import 'app/providers/report_provider.dart';
import 'app/providers/medication_provider.dart';
import 'app/providers/emergency_view_model.dart';
import 'modules/doctor/provider/doctor_provider.dart';
import 'app/providers/nominee_provider.dart';
import 'app/providers/patient_profile_provider.dart';
import 'app/views/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  await StorageService().init();
  await NotificationService().init();

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
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => AccessViewModel()),
        ChangeNotifierProvider(create: (_) => ShareViewModel()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => NomineeProvider()),
        ChangeNotifierProvider(create: (_) => PatientProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Nirmaya',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
