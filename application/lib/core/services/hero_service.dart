import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class HeroSection {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final int order;
  final String type;

  HeroSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.order,
    required this.type,
  });

  factory HeroSection.fromJson(Map<String, dynamic> json) {
    return HeroSection(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: ApiConstants.resolveImageUrl(json['imageUrl']),
      order: json['order'] ?? 0,
      type: json['type'] ?? 'both',
    );
  }
}

class HeroService {
  static Future<List<HeroSection>> fetchHeroSections(String type) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.heroSections}?activeOnly=true&type=$type'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => HeroSection.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching hero sections: $e');
      return [];
    }
  }
}
