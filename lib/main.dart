import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gym_tracker_app/app.dart';
import 'package:gym_tracker_app/util/legacy_database_cleanup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await deleteLegacyWorkoutDatabase();

  await Supabase.initialize(
    url: 'https://kxcxkducxaryjzzrtcpa.supabase.co',
    publishableKey: 'sb_publishable_bB5NM_o_iumfnA_AUzsBzA_9b28Je4m',
  );

  const webClientId =
      '791952466087-cea58i93srcvru1sqo002l4kkp3d431c.apps.googleusercontent.com';
  const iosClientId =
      '791952466087-q1khddlagnculpproa9ks0g79eeh1u5s.apps.googleusercontent.com';
  final googleSignIn = GoogleSignIn.instance;
  await googleSignIn.initialize(
    serverClientId: webClientId,
    clientId: iosClientId,
  );

  runApp(ProviderScope(child: const App()));
}
