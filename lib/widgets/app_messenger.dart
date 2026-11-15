import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_messenger.g.dart';

/// The app's root [ScaffoldMessenger], set on the `MaterialApp`. Messages
/// sent through it outlive the sheet or screen that caused them.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

const workoutSavedMessage = 'Workout saved';
const workoutNotSavedMessage =
    "Couldn't save your workout. It's kept on this phone and will sync later.";
const workoutExpiredMessage =
    'Your last workout ran over 12 hours, so it was ended at your last set.';

/// Shows short messages in a [SnackBar] from anywhere, including after the
/// widget that started an upload has gone.
class AppMessenger {
  const AppMessenger(this._key);

  final GlobalKey<ScaffoldMessengerState> _key;

  void show(String message) => _key.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  /// Tells the user how saving a workout went, once it is known.
  ///
  /// [saved] is whether the server had it within the wait. If not and
  /// [stillUploading] is null, the upload already failed. Otherwise the
  /// result is reported when [stillUploading] completes.
  void reportUpload({required bool saved, Future<bool>? stillUploading}) {
    if (saved) {
      return;
    }
    if (stillUploading == null) {
      show(workoutNotSavedMessage);
      return;
    }
    stillUploading.then(
      (uploaded) =>
          show(uploaded ? workoutSavedMessage : workoutNotSavedMessage),
    );
  }
}

@Riverpod(keepAlive: true)
AppMessenger appMessenger(Ref ref) => AppMessenger(rootScaffoldMessengerKey);
