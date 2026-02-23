import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubApiService {
  final String accessToken;
  final String baseUrl = 'https://api.github.com';

  GitHubApiService({required this.accessToken});

  Map<String, String> get _headers => {
    'Authorization': 'token $accessToken',
    'Accept': 'application/vnd.github.v3+json',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(url, headers: _headers);
        break;
      case 'POST':
        response = await http.post(
          url,
          headers: _headers,
          body: jsonEncode(body),
        );
        break;
      case 'PUT':
        response = await http.put(
          url,
          headers: _headers,
          body: jsonEncode(body),
        );
        break;
      case 'DELETE':
        response = await http.delete(url, headers: _headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'GitHub API error: ${response.statusCode}');
    }
  }

  Future<List<String>> _requestList(
    String method,
    String endpoint,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e.toString()).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'GitHub API error: ${response.statusCode}');
    }
  }

  String _parseRepoInfo(String remoteUrl) {
    if (remoteUrl.contains('github.com')) {
      final parts = remoteUrl.split('github.com/')[1].split('/');
      return '${parts[0]}/${parts[1].replaceAll('.git', '')}';
    }
    throw Exception('Invalid GitHub URL');
  }

  Future<Map<String, dynamic>> getRepository(String remoteUrl) async {
    final repoInfo = _parseRepoInfo(remoteUrl);
    return await _request('GET', '/repos/$repoInfo');
  }

  Future<List<String>> getBranches(String remoteUrl) async {
    final repoInfo = _parseRepoInfo(remoteUrl);
    final url = Uri.parse('$baseUrl/repos/$repoInfo/branches');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e['name'] as String).toList();
    }
    return [];
  }

  Future<String> getDefaultBranch(String remoteUrl) async {
    final repo = await getRepository(remoteUrl);
    return repo['default_branch'] ?? 'main';
  }

  Future<Map<String, dynamic>> getFileContent(
    String remoteUrl,
    String path, {
    String branch = 'main',
  }) async {
    final repoInfo = _parseRepoInfo(remoteUrl);
    return await _request('GET', '/repos/$repoInfo/contents/$path?ref=$branch');
  }

  Future<Map<String, dynamic>> createOrUpdateFile({
    required String remoteUrl,
    required String path,
    required String content,
    required String message,
    String? sha,
    String branch = 'main',
  }) async {
    final repoInfo = _parseRepoInfo(remoteUrl);
    final body = {
      'message': message,
      'content': base64Encode(utf8.encode(content)),
      'branch': branch,
    };
    if (sha != null) {
      body['sha'] = sha;
    }
    return await _request('PUT', '/repos/$repoInfo/contents/$path', body: body);
  }

  Future<void> deleteFile({
    required String remoteUrl,
    required String path,
    required String message,
    required String sha,
    String branch = 'main',
  }) async {
    final repoInfo = _parseRepoInfo(remoteUrl);
    await _request('DELETE', '/repos/$repoInfo/contents/$path', body: {
      'message': message,
      'sha': sha,
      'branch': branch,
    });
  }

  Future<List<Map<String, dynamic>>> getCommits(
    String remoteUrl, {
    String branch = 'main',
    int perPage = 30,
  }) async {
    final repoInfo = _parseRepoInfo(remoteUrl);
    final url = Uri.parse(
      '$baseUrl/repos/$repoInfo/commits?sha=$branch&per_page=$perPage',
    );
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> createBranch({
    required String remoteUrl,
    required String newBranch,
    required String fromBranch,
  }) async {
    final repoInfo = _parseRepoInfo(remoteUrl);
    
    final refUrl = Uri.parse('$baseUrl/repos/$repoInfo/git/refs/heads/$fromBranch');
    final refResponse = await http.get(refUrl, headers: _headers);
    
    if (refResponse.statusCode != 200) {
      throw Exception('Failed to get source branch reference');
    }
    
    final refData = jsonDecode(refResponse.body);
    final sha = refData['object']['sha'];

    return await _request('POST', '/repos/$repoInfo/git/refs', body: {
      'ref': 'refs/heads/$newBranch',
      'sha': sha,
    });
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _request('GET', '/user');
  }
}
