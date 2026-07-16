import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/notification_model.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final SupabaseClient _supabase;
  StreamSubscription? _subscription;

  NotificationCubit(this._supabase) : super(NotificationInitial());

  void loadNotifications() {
    emit(NotificationLoading());
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      emit(const NotificationError('User not logged in'));
      return;
    }

    // Subscribe to realtime updates
    _subscription?.cancel();
    _subscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen(
      (data) {
        try {
          final notifications = data.map((e) => NotificationModel.fromJson(e)).toList();
          final unreadCount = notifications.where((n) => !n.isRead).length;
          emit(NotificationLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
          ));
        } catch (e) {
          emit(NotificationError('Erreur lors du traitement des notifications: $e'));
        }
      },
      onError: (e) {
        emit(NotificationError('Erreur de chargement: $e'));
      },
    );
  }

  Future<void> markAsRead(String id) async {
    final current = state;
    if (current is! NotificationLoaded) return;

    try {
      // Optimistic UI update
      final updatedNotifications = current.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

      emit(NotificationLoaded(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      ));

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      // Revert in case of error (reload)
      loadNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    final current = state;
    if (current is! NotificationLoaded) return;
    if (current.unreadCount == 0) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final updatedNotifications = current.notifications.map((n) => n.copyWith(isRead: true)).toList();
      emit(NotificationLoaded(notifications: updatedNotifications, unreadCount: 0));

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      loadNotifications();
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
