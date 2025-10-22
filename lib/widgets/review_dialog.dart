import 'package:flutter/material.dart';
import '../services/review_service.dart';

class ReviewDialog extends StatelessWidget {
  const ReviewDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ReviewDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stelline vuote per umiltà
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                    (index) => Icon(
                  Icons.star_border,
                  size: 40,
                  color: Colors.amber[700],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Testo personalizzato
            const Text(
              'Una tua recensione ci aiuta\na migliorare.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 15),

            // Testo con cuore
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'La tua opinione conta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '💙',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Bottone principale
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await ReviewService().markAsReviewed();
                  await ReviewService().openPlayStore();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'SCRIVI RECENSIONE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Bottone secondario
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Magari più tardi',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}