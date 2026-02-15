import 'package:yaml/yaml.dart';
class BlogPost {
  String title;
  String? slug;
  String content;
  DateTime? date;
  DateTime? updated;
  List<String> tags;
  List<String> categories;
  bool isDraft;
  String? filePath;
  String? excerpt;

  BlogPost({
    required this.title,
    this.slug,
    required this.content,
    this.date,
    this.updated,
    this.tags = const [],
    this.categories = const [],
    this.isDraft = false,
    this.filePath,
    this.excerpt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'slug': slug,
      'content': content,
      'date': date?.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'tags': tags,
      'categories': categories,
      'isDraft': isDraft,
      'filePath': filePath,
      'excerpt': excerpt,
    };
  }

  factory BlogPost.fromMap(Map<String, dynamic> map) {
    return BlogPost(
      title: map['title'] ?? '',
      slug: map['slug'],
      content: map['content'] ?? '',
      date: map['date'] != null ? DateTime.tryParse(map['date']) : null,
      updated: map['updated'] != null ? DateTime.tryParse(map['updated']) : null,
      tags: List<String>.from(map['tags'] ?? []),
      categories: List<String>.from(map['categories'] ?? []),
      isDraft: map['isDraft'] ?? false,
      filePath: map['filePath'],
      excerpt: map['excerpt'],
    );
  }

  String toYamlHeader() {
    final buffer = StringBuffer('---\n');
    buffer.writeln('title: "$title"');
    if (date != null) {
      buffer.writeln('date: ${date!.toIso8601String()}');
    }
    if (updated != null) {
      buffer.writeln('updated: ${updated!.toIso8601String()}');
    }
    if (tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in tags) {
        buffer.writeln('  - $tag');
      }
    }
    if (categories.isNotEmpty) {
      buffer.writeln('categories:');
      for (final category in categories) {
        buffer.writeln('  - $category');
      }
    }
    buffer.writeln('---');
    return buffer.toString();
  }

  factory BlogPost.fromFile(String content, {String? filePath}) {
    final headerMatch = RegExp(r'^---\r?\n([\s\S]*?)\r?\n---').firstMatch(content);
    
    if (headerMatch == null) {
      return BlogPost(
        title: 'Untitled',
        content: content,
        filePath: filePath,
      );
    }

    final headerContent = headerMatch.group(1)!;
    final bodyContent = content.substring(headerMatch.end);
    
    Map<String, dynamic> frontMatter = {};
    
    try {
      final yamlData = loadYaml(headerContent);
      if (yamlData is Map) {
        frontMatter = Map<String, dynamic>.from(yamlData);
      }
    } catch (e) {
      print('Error parsing YAML front matter: $e');
    }

    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      if (value is String) {
        return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    return BlogPost(
      title: frontMatter['title']?.toString() ?? 'Untitled',
      slug: frontMatter['slug']?.toString(),
      date: frontMatter['date'] != null ? DateTime.tryParse(frontMatter['date'].toString()) : null,
      updated: frontMatter['updated'] != null ? DateTime.tryParse(frontMatter['updated'].toString()) : null,
      tags: parseList(frontMatter['tags']),
      categories: parseList(frontMatter['categories']),
      isDraft: frontMatter['draft'] ?? false,
      content: bodyContent.trim(),
      filePath: filePath,
    );
  }

  BlogPost copyWith({
    String? title,
    String? slug,
    String? content,
    DateTime? date,
    DateTime? updated,
    List<String>? tags,
    List<String>? categories,
    bool? isDraft,
    String? filePath,
    String? excerpt,
  }) {
    return BlogPost(
      title: title ?? this.title,
      slug: slug ?? this.slug,
      content: content ?? this.content,
      date: date ?? this.date,
      updated: updated ?? this.updated,
      tags: tags ?? this.tags,
      categories: categories ?? this.categories,
      isDraft: isDraft ?? this.isDraft,
      filePath: filePath ?? this.filePath,
      excerpt: excerpt ?? this.excerpt,
    );
  }
}
