import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData defaultIcon;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final Color? iconColor;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24.0,
    this.defaultIcon = Icons.person_rounded,
    this.backgroundColor,
    this.gradientColors,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        backgroundColor ??
        (gradientColors == null
            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
            : null);
    final fgColor = iconColor ?? theme.colorScheme.primary;

    Widget buildPlaceholder() {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          gradient: gradientColors != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors!,
                )
              : null,
        ),
        child: Icon(defaultIcon, color: fgColor, size: radius * 1.2),
      );
    }

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
          backgroundColor: Colors.transparent,
        ),
        placeholder: (context, url) => Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            gradient: gradientColors != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors!,
                  )
                : null,
          ),
          child: Center(
            child: SizedBox(
              width: radius,
              height: radius,
              child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
            ),
          ),
        ),
        errorWidget: (context, url, error) => buildPlaceholder(),
      );
    }

    return buildPlaceholder();
  }
}
