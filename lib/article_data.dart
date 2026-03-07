import 'package:flutter/material.dart';
import 'package:motherly_v1/firestore/firestore_service.dart';
import 'package:motherly_v1/models/LearnArticle.dart';
import 'package:motherly_v1/models/infant_model.dart';

class LearnScreen extends StatefulWidget {
  final bool isSinhala;
  final String infantId;
  final String infantName;
  final InfantModel infant;

  const LearnScreen({
    Key? key,
    required this.isSinhala,
    required this.infantId,
    required this.infantName,
    required this.infant,
  }) : super(key: key);

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late bool _isSinhala;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  bool _isLoadingCategories = true;
  int _selectedIndex = 0; // For bottom navigation

  final FirestoreService _firestoreService = FirestoreService();

  // Get theme color based on gender
  Color get _themeColor {
    final gender = widget.infant.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return Colors.blue;
    }
    return const Color(0xFFEC4899); // Modern pink
  }

  // Light theme color for backgrounds
  Color get _lightThemeColor {
    return _themeColor.withOpacity(0.1);
  }

  // Gradient background
  LinearGradient get _backgroundGradient {
    final gender = widget.infant.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE1F5FE), // Very light blue
          Color(0xFFB3E5FC), // Light blue
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFCE4EC), // Very light pink
        Color(0xFFF8BBD9), // Light pink
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _isSinhala = widget.isSinhala;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await _firestoreService.getCategories();
      setState(() {
        _categories = ['All', ...categories];
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

String _cleanContent(String content) {
  // Replace literal backslashes with actual newlines
  String cleaned = content.replaceAll('\\n', '\n');
  
  // Also clean markdown
  cleaned = cleaned.replaceAll('**', '');
  
  return cleaned;
}

// Function to format content with proper styling
List<Widget> _formatContent(String text) {
  // First clean the content
  String cleanText = _cleanContent(text);
  
  List<Widget> widgets = [];
  
  // Split by double newlines for paragraphs
  List<String> paragraphs = cleanText.split('\n\n');
  
  for (String paragraph in paragraphs) {
    if (paragraph.trim().isEmpty) continue;
    
    // Check if it's a numbered item (starts with number and dot)
    if (RegExp(r'^\d+\.').hasMatch(paragraph.trim())) {
      // Extract the number and the text
      final number = paragraph.trim().substring(0, paragraph.indexOf('.'));
      final content = paragraph.substring(paragraph.indexOf('.') + 1).trim();
      
      // Split into bold title and description if it has **
      if (content.contains('**')) {
        final boldStart = content.indexOf('**') + 2;
        final boldEnd = content.indexOf('**:', boldStart);
        
        if (boldStart > 1 && boldEnd > boldStart) {
          final boldText = content.substring(boldStart, boldEnd).trim();
          final description = content.substring(boldEnd + 2).trim();
          
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number circle
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _themeColor,
                          _themeColor.withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          boldText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _themeColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Fallback for items without proper bold formatting
          widgets.add(_buildSimpleListItem(number, content));
        }
      } else {
        // Simple numbered item without bold
        widgets.add(_buildSimpleListItem(number, content));
      }
    }
    // Check if it's a header/remember text
    else if (paragraph.contains('මතක තියාගන්න') || paragraph.contains(':')) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _lightThemeColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _themeColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates, color: _themeColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paragraph,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _themeColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Regular paragraph
    else {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            paragraph,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }
  }
  
  return widgets;
}

// Helper for simple list items
Widget _buildSimpleListItem(String number, String content) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(right: 8, top: 2),
          decoration: BoxDecoration(
            color: _themeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: _themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isSinhala ? 'ඉගෙනුම්' : 'Learn',
        ),
        backgroundColor: _themeColor,
        foregroundColor: Colors.white,
        actions: [
          // Language toggle in AppBar
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLangButton('EN', !_isSinhala),
                _buildLangButton('SI', _isSinhala),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: _backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Category Chips
              _buildCategoryChips(),
              
              // Articles List
              Expanded(
                child: _buildArticlesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper for language buttons
Widget _buildLangButton(String text, bool isSelected) {
  return GestureDetector(
    onTap: () {
      setState(() {
        _isSinhala = text == 'SI';
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? _themeColor : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    ),
  );
}

  Widget _buildCategoryChips() {
    if (_isLoadingCategories) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: _themeColor),
        ),
      );
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _themeColor : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? _themeColor : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? _themeColor.withOpacity(0.3) : Colors.transparent,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _isSinhala ? _getSinhalaCategory(category) : category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticlesList() {
    return StreamBuilder<List<LearnArticle>>(
      stream: _selectedCategory == 'All'
          ? _firestoreService.getLearnArticles()
          : _firestoreService.getLearnArticlesByCategory(_selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: _themeColor),
          );
        }

        final articles = snapshot.data ?? [];

        if (articles.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadCategories,
          color: _themeColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return _buildModernArticleCard(article);
            },
          ),
        );
      },
    );
  }

  Widget _buildModernArticleCard(LearnArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getCategoryColor(article.category),
                  _getCategoryColor(article.category).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                article.category.isNotEmpty ? article.category[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          title: Text(
            _isSinhala ? article.titleSi : article.titleEn,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _lightThemeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isSinhala ? _getSinhalaCategory(article.category) : article.category,
              style: TextStyle(
                color: _themeColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formatted content
                  ..._formatContent(
                    _isSinhala ? article.contentSi : article.contentEn
                  ),
                  
                  // Tips section
                  if ((_isSinhala && article.tipsSi != null && article.tipsSi!.isNotEmpty) || 
                      (!_isSinhala && article.tipsEn != null && article.tipsEn!.isNotEmpty)) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lightThemeColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _themeColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _themeColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '💡',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isSinhala ? 'උපදෙස' : 'Tip',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _themeColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isSinhala ? article.tipsSi! : article.tipsEn!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Date
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(article.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: _themeColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _isSinhala ? 'දෝෂයක් සිදු විය' : 'An error occurred',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(_isSinhala ? 'නැවත උත්සාහ කරන්න' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined, size: 80, color: _themeColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            _isSinhala ? 'ලිපි හමු නොවීය' : 'No articles found',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          if (_selectedCategory != 'All')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _isSinhala 
                    ? '$_selectedCategory කාණ්ඩයේ ලිපි නැත' 
                    : 'No articles in $_selectedCategory category',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'feeding':
      case 'පෝෂණය':
        return const Color(0xFFF97316); // Orange
      case 'hygiene':
      case 'සනීපාරක්ෂාව':
        return const Color(0xFF3B82F6); // Blue
      case 'skincare':
      case 'සම ආරක්ෂණය':
        return const Color(0xFFA855F7); // Purple
      case 'safety':
      case 'ආරක්ෂාව':
        return const Color(0xFFEF4444); // Red
      default:
        return _themeColor;
    }
  }

  String _getSinhalaCategory(String category) {
    switch (category.toLowerCase()) {
      case 'feeding':
        return 'පෝෂණය';
      case 'hygiene':
        return 'සනීපාරක්ෂාව';
      case 'skincare':
        return 'සම ආරක්ෂණය';
      case 'safety':
        return 'ආරක්ෂාව';
      case 'all':
        return 'සියල්ල';
      default:
        return category;
    }
  }
}