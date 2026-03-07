import 'package:cloud_firestore/cloud_firestore.dart';

class LearnArticle {
  final String id;
  final String category;
  final DateTime createdAt;
  final String titleEn;
  final String contentEn;
  final String? tipsEn;
  final String titleSi;
  final String contentSi;
  final String? tipsSi;

  LearnArticle({
    required this.id,
    required this.category,
    required this.createdAt,
    required this.titleEn,
    required this.contentEn,
    this.tipsEn,
    required this.titleSi,
    required this.contentSi,
    this.tipsSi,
  });

  factory LearnArticle.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  
  // Helper to clean content
  String cleanContent(String? content) {
    if (content == null) return '';
    // Replace literal backslashes with newlines
    return content.replaceAll('\\n', '\n').replaceAll('**', '');
  }
  
  return LearnArticle(
    id: doc.id,
    category: data['category'] ?? '',
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    titleEn: data['en']?['title'] ?? '',
    contentEn: cleanContent(data['en']?['content']),
    tipsEn: data['en']?['tips'],
    titleSi: data['si']?['title'] ?? '',
    contentSi: cleanContent(data['si']?['content']),
    tipsSi: data['si']?['tips'],
  );
}
}