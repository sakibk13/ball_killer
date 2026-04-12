import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusDialog {
  static void show(BuildContext context, {
    required String message,
    required bool isSuccess,
    required String title,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color: const Color(0xFF020C3B),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSuccess ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon instead of GIF for faster response
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                    size: 60,
                  ),
                ),                const SizedBox(height: 30),
                Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bebasNeue(
                    color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 28,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess ? Colors.green : Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      'CONTINUE',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 20,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}