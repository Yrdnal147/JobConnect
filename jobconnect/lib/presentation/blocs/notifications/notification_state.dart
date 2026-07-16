import '../../../data/models/notification_model.dart';

abstract class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);
}
