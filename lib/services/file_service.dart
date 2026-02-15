
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/blog_post.dart';

class FileService {
  Future<List<BlogPost>> scanPosts(String blogPath, {String? postsPath}) async {
    final postsDirPath = postsPath ?? path.join(blogPath, 'source', '_posts');
    final postsDir = Directory(postsDirPath);
    final posts = <BlogPost>[];

    if (!await postsDir.exists()) {
      return posts;
    }

    await for (final file in postsDir.list()) {
      if (file is File && file.path.endsWith('.md')) {
        try {
          final content = await file.readAsString();
          final post = BlogPost.fromFile(content, filePath: file.path);
          posts.add(post);
        } catch (e) {
          print('Error reading ${file.path}: $e');
        }
      }
    }

    posts.sort((a, b) {
      final dateA = a.date ?? DateTime(0);
      final dateB = b.date ?? DateTime(0);
      return dateB.compareTo(dateA);
    });

    return posts;
  }

  Future<void> savePost(BlogPost post) async {
    final file = File(post.filePath!);
    final content = '${post.toYamlHeader()}\n\n${post.content}';
    await file.writeAsString(content);
  }

  Future<BlogPost> createPost(String blogPath, String title, {String? postsPath}) async {
    final postsDirPath = postsPath ?? path.join(blogPath, 'source', '_posts');
    final postsDir = Directory(postsDirPath);
    if (!await postsDir.exists()) {
      await postsDir.create(recursive: true);
    }

    final now = DateTime.now();
    final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final fileName = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-$slug.md';
    final filePath = path.join(postsDir.path, fileName);

    final post = BlogPost(
      title: title,
      content: '',
      date: now,
      filePath: filePath,
    );

    await savePost(post);
    return post;
  }

  Future<void> deletePost(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String?> readFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      print('Error reading file $path: $e');
      return null;
    }
  }

  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  Future<bool> directoryExists(String path) async {
    return Directory(path).exists();
  }

  Future<void> copyFile(String source, String destination) async {
    await File(source).copy(destination);
  }
}
