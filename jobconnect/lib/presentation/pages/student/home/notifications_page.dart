import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../blocs/notifications/notification_cubit.dart';
import '../../../blocs/notifications/notification_state.dart';
import '../../../../data/models/notification_model.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'match':
        return Icons.auto_awesome_rounded;
      case 'application_retained':
        return Icons.celebration_rounded;
      case 'application_refused':
        return Icons.info_outline_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'match':
        return AppColorsLight.primary;
      case 'application_retained':
        return AppColorsLight.success;
      case 'application_refused':
        return AppColorsLight.error;
      case 'message':
        return AppColorsLight.secondary;
      default:
        return AppColorsLight.textTertiary;
    }
  }

  List<Color> _gradientForType(String type) {
    switch (type) {
      case 'match':
        return [AppColorsLight.primary, AppColorsLight.secondary];
      case 'application_retained':
        return [AppColorsLight.success, const Color(0xFF00C9A7)];
      case 'application_refused':
        return [AppColorsLight.error, const Color(0xFFFF8C69)];
      case 'message':
        return [AppColorsLight.secondary, AppColorsLight.primary];
      default:
        return [AppColorsLight.textTertiary, AppColorsLight.textTertiary];
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'match':
        return 'IA Match';
      case 'application_retained':
        return 'Retenu';
      case 'application_refused':
        return 'Refusé';
      case 'message':
        return 'Message';
      default:
        return 'Notif';
    }
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) {
      return 'time.minutes'.tr(args: [difference.inMinutes.toString()]);
    } else if (difference.inHours < 24) {
      return 'time.hours'.tr(args: [difference.inHours.toString()]);
    } else if (difference.inDays == 1) {
      return 'time.yesterday'.tr();
    } else {
      return 'time.days'.tr(args: [difference.inDays.toString()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        List<NotificationModel> notifications = [];
        bool isLoading = state is NotificationLoading;

        if (state is NotificationLoaded) {
          notifications = state.notifications;
          unreadCount = state.unreadCount;
        }

        return Scaffold(
          backgroundColor: AppColorsLight.bgDark,
          body: Stack(
            children: [
              // ── En-tête Violet ────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.28,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColorsLight.primary, Color(0xFF4A148C)],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Text(
                                    'settings.notifications'.tr(),
                                    style: AppTypography.headingMedium.copyWith(color: Colors.white),
                                  ),
                                  if (unreadCount > 0) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                      ),
                                      child: Text(
                                        unreadCount > 1
                                            ? 'home.notifications_plural'.tr(args: [unreadCount.toString()])
                                            : 'home.notifications_single'.tr(args: [unreadCount.toString()]),
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            IconButton(
                              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                              tooltip: 'home.mark_all_read'.tr(),
                              onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Carte Blanche Flottante ───────────────────────────
              Positioned.fill(
                top: MediaQuery.of(context).size.height * 0.14,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppColorsLight.primary))
                            : notifications.isEmpty
                                ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColorsLight.textTertiary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                size: 40,
                                color: AppColorsLight.textTertiary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'home.empty_notifications_title'.tr(),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'home.empty_notifications_subtitle'.tr(),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColorsLight.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          final isRead = notif.isRead;
                          final type = notif.type;
                          final color = _colorForType(type);
                          final gradient = _gradientForType(type);
                          final label = _labelForType(type);

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColorsLight.bgCard,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(
                                color: isRead
                                    ? AppColorsLight.bgSurface
                                    : color.withValues(alpha: 0.25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isRead
                                      ? Colors.black.withValues(alpha: 0.03)
                                      : color.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  if (!isRead) {
                                    context.read<NotificationCubit>().markAsRead(notif.id);
                                  }
                                  
                                  // Navigation logic if data contains relevant IDs
                                  if (notif.data != null) {
                                    final data = notif.data!;
                                    if (type == 'application_retained' || type == 'application_refused') {
                                      if (data['application_id'] != null) {
                                        context.push('/student/applications/${data['application_id']}');
                                      }
                                    } else if (type == 'message') {
                                      if (data['conversation_id'] != null) {
                                        context.push('/student/messages/${data['conversation_id']}');
                                      }
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Icône en cercle dégradé
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isRead
                                                ? [
                                                    color.withValues(alpha: 0.15),
                                                    color.withValues(alpha: 0.15),
                                                  ]
                                                : gradient,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: isRead
                                              ? []
                                              : [
                                                  BoxShadow(
                                                    color:
                                                        color.withValues(alpha: 0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                        ),
                                        child: Icon(
                                          _iconForType(type),
                                          color: isRead ? color : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),

                                      // Contenu
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Titre + badge type
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif.title,
                                                    style: AppTypography
                                                        .headingSmall
                                                        .copyWith(
                                                      fontWeight: isRead
                                                          ? FontWeight.w500
                                                          : FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        color.withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppSpacing.radiusFull),
                                                  ),
                                                  child: Text(
                                                    label,
                                                    style: AppTypography.caption
                                                        .copyWith(
                                                      color: color,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notif.body,
                                              style:
                                                  AppTypography.bodySmall.copyWith(
                                                color: AppColorsLight.textPrimary
                                                    .withValues(
                                                        alpha: isRead ? 0.55 : 0.8),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            // Temps + point non-lu
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.schedule_rounded,
                                                  size: 12,
                                                  color: AppColorsLight.textTertiary,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  _formatTime(notif.createdAt),
                                                  style:
                                                      AppTypography.caption.copyWith(
                                                    color:
                                                        AppColorsLight.textTertiary,
                                                  ),
                                                ),
                                                if (!isRead) ...[
                                                  const Spacer(),
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              ),
            ],
          ),
        );
      },
    );
  }
}