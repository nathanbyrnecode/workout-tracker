import 'package:url_launcher/url_launcher.dart';

const privacyPolicyUrl = 'https://fittenup.app/privacy';

Future<bool> openPrivacyPolicy() {
  return launchUrl(
    Uri.parse(privacyPolicyUrl),
    mode: LaunchMode.inAppBrowserView,
  );
}
