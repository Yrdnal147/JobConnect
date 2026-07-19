import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../../blocs/messaging/messaging_cubit.dart';
import '../../../blocs/messaging/messaging_state.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  late final MessagingCubit _cubit;
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<MessagingCubit>();
    _cubit.loadStudentConversations();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Trigger lazy loading
      _cubit.loadStudentConversations(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<MessagingCubit, MessagingState>(
        builder: (context, state) {
          final size = MediaQuery.of(context).size;

          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: AppColorsLight.bgDark,
            body: Stack(
              children: [
                // ── En-tête Violet ────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.28,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColorsLight.primary,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [

                                    Text(
                                      (state is ConversationsLoaded &&
                                              state.filterType == 'archived')
                                          ? 'Archives'
                                          : 'messaging.title'.tr(),
                                      style: AppTypography.displayMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 26,
                                      ),
                                    ),
                                  ],
                                ),
                                if (state is ConversationsLoaded)
                                  IconButton(
                                    icon: Icon(
                                      state.filterType == 'archived'
                                          ? Icons.unarchive_rounded
                                          : Icons.archive_outlined,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    tooltip: state.filterType == 'archived'
                                        ? 'Voir les messages'
                                        : 'Voir les archives',
                                    onPressed: () => _cubit.setFilterType(
                                      state.filterType == 'archived'
                                          ? 'all'
                                          : 'archived',
                                      isStudent: true,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Barre de recherche
                            Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                                horizontal: 0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: AppSpacing.md),
                                  Icon(
                                    Icons.search_rounded,
                                    color: _searchController.text.isNotEmpty
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.8),
                                    size: 22,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: Colors.white,
                                      ),
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        hintText: 'messaging.search_hint'.tr(),
                                        hintStyle: AppTypography.bodyLarge
                                            .copyWith(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                      ),
                                      onChanged: (val) {
                                        setState(() {});
                                        _cubit.setSearchQuery(val);
                                      },
                                    ),
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _cubit.setSearchQuery('');
                                        setState(() {});
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Carte Blanche Glassmorphism ──────────────────────
                Positioned.fill(
                  top: size.height * 0.22,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            // Pilules de filtrage
                            _buildFilterChips(state),
                            const SizedBox(height: AppSpacing.sm),
                            Expanded(child: _buildBody(context, state)),
                          ],
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

  Widget _buildFilterChips(MessagingState state) {
    String currentFilter = 'all';
    if (state is ConversationsLoaded) {
      if (state.filterType == 'archived') {
        return const SizedBox.shrink();
      }
      currentFilter = state.filterType;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _buildChip(
            'messaging.filters.all'.tr(),
            'all',
            currentFilter == 'all',
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildChip(
            'messaging.filters.unread'.tr(),
            'unread',
            currentFilter == 'unread',
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildChip(
            'messaging.filters.read'.tr(),
            'read',
            currentFilter == 'read',
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, bool isSelected) {
    return GestureDetector(
      onTap: () => _cubit.setFilterType(value, isStudent: true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColorsLight.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColorsLight.primary
                : AppColorsLight.textTertiary.withOpacity(0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColorsLight.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColorsLight.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MessagingState state) {
    if (state is ConversationsLoading) {
      return _buildLoadingList();
    }

    if (state is ConversationsError) {
      return _buildErrorState(state.message);
    }

    if (state is ConversationsLoaded) {
      if (state.conversations.isEmpty) {
        return _buildEmptyState(state.filterType == 'archived');
      }

      return RefreshIndicator(
        color: AppColorsLight.primary,
        onRefresh: () => _cubit.loadStudentConversations(loadMore: false),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            100,
          ),
          itemCount: state.conversations.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.conversations.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final conv = state.conversations[index];
            return _buildConversationTile(
              context,
              conv,
              state.filterType == 'archived',
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildConversationTile(
    BuildContext context,
    ConversationItem conv,
    bool isArchived,
  ) {
    final hasUnread = conv.unreadCount > 0;

    return Dismissible(
      key: Key(conv.conversationId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (isArchived) {
          _cubit.unarchiveConversation(conv.conversationId, true);
        } else {
          _cubit.archiveConversation(conv.conversationId, true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArchived
                  ? 'messaging.restored_success'.tr()
                  : 'messaging.archived_success'.tr(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColorsLight.bgDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: isArchived
              ? AppColorsLight.success.withOpacity(0.8)
              : AppColorsLight.error.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Icon(
          isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColorsLight.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColorsLight.textTertiary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: hasUnread
                ? AppColorsLight.primary.withOpacity(0.5)
                : AppColorsLight.textTertiary.withOpacity(0.1),
            width: hasUnread ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                context.push('/student/messages/${conv.conversationId}'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColorsLight.bgCard,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColorsLight.primary.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: UserAvatar(
                          imageUrl: conv.otherPartyPhotoUrl,
                          radius: 26,
                          defaultIcon: Icons.business_rounded,
                          backgroundColor: AppColorsLight.primary.withOpacity(
                            0.1,
                          ),
                          iconColor: AppColorsLight.primary,
                        ),
                      ),
                      if (conv.isOnline)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColorsLight.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColorsLight.success.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                conv.otherPartyName,
                                style: AppTypography.headingSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              conv.lastMessageAt,
                              style: AppTypography.caption.copyWith(
                                color: hasUnread
                                    ? AppColorsLight.primary
                                    : AppColorsLight.textTertiary,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        if (conv.otherPartySubtitle.isNotEmpty)
                          Text(
                            conv.otherPartySubtitle,
                            style: AppTypography.caption.copyWith(
                              color: AppColorsLight.primary.withOpacity(0.7),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conv.lastMessage,
                                style: AppTypography.bodySmall.copyWith(
                                  color: hasUnread
                                      ? AppColorsLight.textPrimary
                                      : AppColorsLight.textTertiary,
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: const EdgeInsets.only(
                                  left: AppSpacing.sm,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorsLight.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${conv.unreadCount}',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isArchived) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColorsLight.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isArchived
                    ? Icons.archive_outlined
                    : Icons.chat_bubble_outline_rounded,
                size: 48,
                color: AppColorsLight.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isArchived
                  ? 'messaging.empty.archived_title'.tr()
                  : 'messaging.empty.title'.tr(),
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isArchived
                  ? 'messaging.empty.archived_subtitle'.tr()
                  : 'messaging.empty.subtitle'.tr(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColorsLight.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColorsLight.error,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'messaging.error.title'.tr(),
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColorsLight.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => _cubit.loadStudentConversations(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsLight.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('messaging.error.retry'.tr()),
          ),
        ],
      ),
    );
  }
}
