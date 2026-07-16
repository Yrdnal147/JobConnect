import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension StringExtensions on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get initials {
    final parts = trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }
}

extension DateTimeExtensions on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} mois';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  String get formatted => '$day/$month/$year';
}

extension IntExtensions on int {
  Color get scoreColor {
    if (this >= 75) return AppColorsLight.success;
    if (this >= 50) return AppColorsLight.warning;
    return AppColorsLight.error;
  }

  String get scoreLabel {
    if (this >= 75) return 'Excellent';
    if (this >= 50) return 'Bon';
    if (this >= 25) return 'Moyen';
    return 'Faible';
  }
}

extension OfferTypeExtensions on String {
  String get offerTypeLabel {
    switch (this) {
      case 'cdi':
        return 'CDI';
      case 'cdd':
        return 'CDD';
      case 'stage_academique':
        return 'Stage académique';
      case 'stage_professionnel':
        return 'Stage professionnel';
      case 'freelance':
        return 'Freelance';
      default:
        return this;
    }
  }

  Color get offerTypeColor {
    switch (this) {
      case 'cdi':
        return AppColorsLight.success;
      case 'cdd':
        return AppColorsLight.primary;
      case 'stage_academique':
        return AppColorsLight.warning;
      case 'stage_professionnel':
        return AppColorsLight.secondary;
      case 'freelance':
        return AppColorsLight.accentRed;
      default:
        return AppColorsLight.textTertiary;
    }
  }
}