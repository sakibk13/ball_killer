import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class SmsService {
  static const String apiKey = "yR4UOTOQqCSAUDvmvwoL";
  static const String baseUrl = "https://bulksmsbd.net/api/smsapi";

  static String formatNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      return '88$cleaned';
    } else if (cleaned.startsWith('1')) {
      return '880$cleaned';
    }
    return cleaned;
  }

  static Future<bool> sendCustomSms({
    required String phoneNumber,
    required String message,
  }) async {
    final String formattedNumber = formatNumber(phoneNumber);
    
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          "api_key": apiKey,
          "type": "text",
          "number": formattedNumber,
          "senderid": "8809617611085",
          "message": message,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Bulk SMS BD returns "success" in response_code for successful submission
        if (data['response_code'] == 202 || data['success_message'] != null) {
          debugPrint("SMS Sent successfully to $formattedNumber");
          return true;
        } else {
          debugPrint("SMS API Error: ${response.body}");
          return false;
        }
      } else {
        debugPrint("SMS HTTP Error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("SMS Exception: $e");
      return false;
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
        return "Hello $name, your fine for $ballsLost balls is $totalFine BDT. You gave $givenAmount BDT. Pending due: $dueAmount BDT. Please clear it soon. - Ball Killer by Mini Cricket";
      } else {
        return "Hello $name, you have a fine of $totalFine BDT for $ballsLost balls lost. Please pay to the club treasurer. - Ball Killer by Mini Cricket";
      }
    } else {
      return "Hello $name, thank you for clearing your fine of $totalFine BDT for $ballsLost balls. Play safe! - Ball Killer by Mini Cricket";
    }
  }
}
