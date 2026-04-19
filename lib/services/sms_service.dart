import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class SmsService {
  static const String apiKey = "yR4UOTOQqCSAUDvmvwoL";
  static const String baseUrl = "https://bulksmsbd.net/api/smsapi";

  static String formatNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    // If it starts with 0 (like 017...), add 88
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      return '88$cleaned';
    } 
    // If it starts with 1 (like 17...), add 880
    if (cleaned.startsWith('1') && cleaned.length == 10) {
      return '880$cleaned';
    }
    // If it's already 880...
    return cleaned;
  }

  /// Returns a message string for the UI (Success or Error Details)
  static Future<String> sendCustomSms({
    required String phoneNumber,
    required String message,
  }) async {
    final String formattedNumber = formatNumber(phoneNumber);
    
    try {
      // We use a more standard approach for BulkSMSBD
      final url = Uri.parse(baseUrl).replace(queryParameters: {
        "api_key": apiKey,
        "type": "text",
        "number": formattedNumber,
        "senderid": "8809617611085", // Non-masking Default
        "message": message,
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 202 is the successful submission code for BulkSMSBD
        if (data['response_code'] == 202) {
          return "SUCCESS";
        } else {
          // Return the actual error from their server
          return data['error_message'] ?? data['success_message'] ?? "Error: ${response.body}";
        }
      } else {
        return "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      return "App Error: $e";
    }
  }

  static String generateFineMessage({
    required String name,
    required int ballsLost,
    required double totalFine,
    required double givenAmount,
    required double dueAmount,
  }) {
    if (dueAmount > 0) {
      if (givenAmount > 0) {
        return "Hello $name, your fine for $ballsLost balls is $totalFine. You gave $givenAmount. Due: $dueAmount. Please clear it. - Ball Killer by Mini Cricket";
      } else {
        return "Hello $name, you have a fine of $totalFine for $ballsLost balls lost. Please pay to club treasurer. - Ball Killer by Mini Cricket";
      }
    } else {
      return "Hello $name, thank you for clearing your fine of $totalFine for $ballsLost balls. Play safe! - Ball Killer by Mini Cricket";
    }
  }
}
