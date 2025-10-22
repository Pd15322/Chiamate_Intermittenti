import 'package:flutter/material.dart';
import '../services/review_service.dart';
import 'review_dialog.dart';

class ReviewChecker {
  static final ReviewService _reviewService = ReviewService();

  /// Controlla se mostrare il dialog di recensione
  static Future<void> checkAndShowReview(BuildContext context) async {
    // Aspetta un momento per non interferire con altre operazioni
    await Future.delayed(const Duration(seconds: 1));

    // Controlla GOLD (priorità)
    if (await _reviewService.shouldRequestGoldReview()) {
      await _showReviewDialog(context, isGold: true);
      return;
    }

    // Controlla SILVER
    if (await _reviewService.shouldRequestSilverReview()) {
      await _showReviewDialog(context, isGold: false);
      return;
    }
  }

  /// Mostra il dialog e traccia la richiesta
  static Future<void> _showReviewDialog(BuildContext context, {required bool isGold}) async {
    if (!context.mounted) return;

    await ReviewDialog.show(context);

    // Segna che è stata fatta la richiesta
    if (isGold) {
      await _reviewService.markGoldRequested();
    } else {
      await _reviewService.markSilverRequested();
    }
  }
}