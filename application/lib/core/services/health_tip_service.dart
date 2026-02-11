import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class HealthTip {
  final String id;
  final String title;
  final String description;

  HealthTip({
    required this.id,
    required this.title,
    required this.description,
  });

  factory HealthTip.fromJson(Map<String, dynamic> json) {
    return HealthTip(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class HealthTipService {
  static Future<List<HealthTip>> fetchHealthTips() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.healthTips));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => HealthTip.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching health tips: $e');
      return [];
    }
  }
}
