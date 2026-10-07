class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool read;

  AppNotification asRead() => AppNotification(
        id: id,
        title: title,
        body: body,
        time: time,
        read: true,
      );
}
