
class GitConfig {
  String? repoPath;
  String? remoteUrl;
  String? branch;
  String? username;
  String? email;
  String? accessToken;

  GitConfig({
    this.repoPath,
    this.remoteUrl,
    this.branch,
    this.username,
    this.email,
    this.accessToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'repoPath': repoPath,
      'remoteUrl': remoteUrl,
      'branch': branch,
      'username': username,
      'email': email,
      'accessToken': accessToken,
    };
  }

  factory GitConfig.fromMap(Map<String, dynamic> map) {
    return GitConfig(
      repoPath: map['repoPath'],
      remoteUrl: map['remoteUrl'],
      branch: map['branch'],
      username: map['username'],
      email: map['email'],
      accessToken: map['accessToken'],
    );
  }

  GitConfig copyWith({
    String? repoPath,
    String? remoteUrl,
    String? branch,
    String? username,
    String? email,
    String? accessToken,
  }) {
    return GitConfig(
      repoPath: repoPath ?? this.repoPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      branch: branch ?? this.branch,
      username: username ?? this.username,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
