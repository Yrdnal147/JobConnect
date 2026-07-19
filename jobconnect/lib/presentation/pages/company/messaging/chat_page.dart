import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../../blocs/messaging/messaging_cubit.dart';
import '../../../blocs/messaging/messaging_state.dart';

class CompanyChatPage extends StatefulWidget {
  final String conversationId;
  const CompanyChatPage({super.key, required this.conversationId});

  @override
  State<CompanyChatPage> createState() => _CompanyChatPageState();
}

class _CompanyChatPageState extends State<CompanyChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final MessagingCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<MessagingCubit>();
    _cubit.openChat(widget.conversationId); // isStudent: false par défaut
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _cubit.closeChat(); // isStudent: false par défaut
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? text]) {
    final content = text ?? _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    _cubit.sendMessage(content);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<MessagingCubit, MessagingState>(
        listener: (context, state) {
          if (state is ChatLoaded) _scrollToBottom();
        },
        builder: (context, state) {
          final name = state is ChatLoaded ? state.otherPartyName : '...';
          final subtitle = state is ChatLoaded ? state.otherPartySubtitle : '';
          final photoUrl = state is ChatLoaded
              ? state.otherPartyPhotoUrl
              : null;
          final jobDetails = state is ChatLoaded ? state.jobDetails : <String>[];

          return Scaffold(
            backgroundColor: AppColorsLight.bgDark,
            body: Stack(
              children: [
                // ── En-tête Violet ────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.25,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColorsLight.primary,
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
                                Icons.arrow_back_ios_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.go('/company/messages');
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            // Avatar étudiant avec photo si disponible
                            UserAvatar(
                              imageUrl: photoUrl,
                              radius: 20,
                              defaultIcon: Icons.person_rounded,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              iconColor: Colors.white,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Nom + poste
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    style: AppTypography.headingSmall.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty)
                                    Text(
                                      subtitle,
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.call_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              onPressed: () {
                                context.push('/call', extra: {
                                  'name': name,
                                  'photoUrl': photoUrl,
                                  'subtitle': subtitle,
                                  'jobDetails': jobDetails,
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.videocam_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              onPressed: () {
                                context.push('/video-call', extra: {
                                  'name': name,
                                  'photoUrl': photoUrl,
                                  'subtitle': subtitle,
                                  'jobDetails': jobDetails,
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Carte Blanche Glassmorphism ──────────────────────
                Positioned.fill(
                  top: size.height * 0.16,
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
                          child: _buildBody(context, state),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget initialsWidget(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: AppTypography.labelLarge.copyWith(
          color: AppColorsLight.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, MessagingState state) {
    if (state is ChatLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColorsLight.primary),
      );
    }

    if (state is ChatError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: AppColorsLight.textTertiary,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'company.messages.chat_error_loading'.tr(),
                style: AppTypography.headingSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => _cubit.openChat(widget.conversationId),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('company.messages.retry'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsLight.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ChatLoaded) {
      return Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) => _MessageBubble(
                      message: state.messages[index],
                      onLongPress: (msg) =>
                          _handleMessageLongPress(context, msg),
                    ),
                  ),
          ),
          if (state.showSuggestions && state.suggestions.isNotEmpty)
            _buildSuggestions(state.suggestions),
          _buildInput(state.isSending),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _handleMessageLongPress(BuildContext context, MessageItem message) {
    if (!message.isMe || message.isDeleted) return;

    final diff = DateTime.now().toUtc().difference(message.rawCreatedAt);
    final canEdit = diff.inMinutes <= 15; // Modification limitée à 15 min

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorsLight.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColorsLight.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (canEdit)
                ListTile(
                  leading: const Icon(
                    Icons.edit_rounded,
                    color: AppColorsLight.textPrimary,
                  ),
                  title: const Text(
                    'Modifier',
                    style: TextStyle(color: AppColorsLight.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showEditDialog(message);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColorsLight.error,
                ),
                title: const Text(
                  'Supprimer',
                  style: TextStyle(color: AppColorsLight.error),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showDeleteConfirmDialog(message);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(MessageItem message) {
    final editController = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColorsLight.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Text(
            'Modifier le message',
            style: AppTypography.headingSmall.copyWith(
              color: AppColorsLight.textPrimary,
            ),
          ),
          content: TextField(
            controller: editController,
            maxLines: null,
            autofocus: true,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColorsLight.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColorsLight.bgSurface.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColorsLight.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColorsLight.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Annuler',
                style: TextStyle(color: AppColorsLight.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newText = editController.text.trim();
                if (newText.isNotEmpty && newText != message.content) {
                  _cubit.editMessage(message.messageId, newText);
                }
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsLight.primary,
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(MessageItem message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColorsLight.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Text(
            'Supprimer',
            style: AppTypography.headingSmall.copyWith(
              color: AppColorsLight.error,
            ),
          ),
          content: Text(
            'Voulez-vous vraiment supprimer ce message ? Cette action est irréversible pour vous et votre interlocuteur.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Annuler',
                style: TextStyle(color: AppColorsLight.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _cubit.deleteMessage(message.messageId);
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsLight.error,
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Suggestions ─────────────────────────────────────────────────────────

  Widget _buildSuggestions(List<String> suggestions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: AppColorsLight.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'company.messages.ai_suggestions'.tr(),
                style: AppTypography.caption.copyWith(
                  color: AppColorsLight.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () {
                      _messageController.text = suggestion;
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: suggestion.length),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorsLight.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                        border: Border.all(
                          color: AppColorsLight.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 11,
                            color: AppColorsLight.primary,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              suggestion,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColorsLight.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Input ────────────────────────────────────────────────────────────────

  Widget _buildInput(bool isSending) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(top: BorderSide(color: AppColorsLight.bgSurface)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: AppColorsLight.bgSurface),
              ),
              child: TextField(
                controller: _messageController,
                style: AppTypography.bodyLarge.copyWith(color: Colors.black),
                enabled: !isSending,
                decoration: InputDecoration(
                  hintText: 'company.messages.write_message_hint'.tr(),
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              gradient: isSending
                  ? LinearGradient(
                      colors: [
                        AppColorsLight.primary.withOpacity(0.5),
                        AppColorsLight.secondary.withOpacity(0.5),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppColorsLight.textPrimary,
                        AppColorsLight.primary,
                      ],
                    ),
              shape: BoxShape.circle,
              boxShadow: isSending
                  ? []
                  : [
                      BoxShadow(
                        color: AppColorsLight.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: IconButton(
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: isSending ? null : () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Chat vide

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColorsLight.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'company.messages.start_chat'.tr(),
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'company.messages.start_chat_desc'.tr(),
              style: AppTypography.bodySmall.copyWith(
                color: AppColorsLight.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

//  Bulle message

class _MessageBubble extends StatelessWidget {
  final MessageItem message;
  final Function(MessageItem) onLongPress;

  const _MessageBubble({required this.message, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => onLongPress(message),
      child: Align(
        alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: message.isDeleted
                ? AppColorsLight.bgSurface.withOpacity(0.5)
                : (message.isMe
                      ? AppColorsLight.primary
                      : AppColorsLight.bgCard),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppSpacing.radiusLg),
              topRight: const Radius.circular(AppSpacing.radiusLg),
              bottomLeft: Radius.circular(
                message.isMe ? AppSpacing.radiusLg : 4,
              ),
              bottomRight: Radius.circular(
                message.isMe ? 4 : AppSpacing.radiusLg,
              ),
            ),
            border: (message.isMe && !message.isDeleted)
                ? null
                : Border.all(color: AppColorsLight.bgSurface),
            boxShadow: [
              BoxShadow(
                color: message.isMe && !message.isDeleted
                    ? AppColorsLight.primary.withOpacity(0.18)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: message.isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (message.isDeleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.dangerous_rounded,
                      size: 16,
                      color: AppColorsLight.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        message.content.replaceAll('🚫 ', ''),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColorsLight.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  message.content,
                  style: AppTypography.bodyMedium.copyWith(
                    color: message.isMe
                        ? Colors.white
                        : AppColorsLight.textPrimary,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.isEdited && !message.isDeleted
                        ? '${message.createdAt} (modifié)'
                        : message.createdAt,
                    style: AppTypography.caption.copyWith(
                      color: message.isDeleted
                          ? AppColorsLight.textTertiary
                          : (message.isMe
                                ? Colors.white.withOpacity(0.7)
                                : AppColorsLight.textTertiary),
                    ),
                  ),
                  if (message.isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 13,
                      color: message.isRead
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
