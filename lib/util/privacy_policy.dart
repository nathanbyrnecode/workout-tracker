import 'package:url_launcher/url_launcher.dart';

const privacyPolicyUrl = 'https://nathanbyrnecode.github.io/workout-tracker/';

Future<bool> openPrivacyPolicy() {
  return launchUrl(
    Uri.parse(privacyPolicyUrl),
    mode: LaunchMode.inAppBrowserView,
  );
}
