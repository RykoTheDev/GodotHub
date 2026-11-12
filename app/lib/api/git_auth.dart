import '../src/rust/api/dto.dart' as dto;
import '../src/rust/api/git_auth.dart' as rust;
import '../src/rust/api/types.dart';

abstract final class GitAuthApi {
  static Future<GitAuthState> getState() => rust.getGitAuthState();

  static Future<CreateRepoResult> createRemoteRepo(String provider, String name, bool privateRepo, String path) =>
      rust.createRemoteRepo(provider: provider, name: name, privateRepo: privateRepo, path: path);

  static Future<DeviceFlowStart> startDeviceFlow(String provider, [String? baseUrl, String? clientId]) =>
      rust.startDeviceFlow(provider: provider, baseUrl: baseUrl, clientId: clientId);

  static Future<dto.DeviceFlowPoll> pollDeviceFlow(String provider, String deviceCode, [String? baseUrl, String? clientId]) =>
      dto.pollDeviceFlow(provider: provider, deviceCode: deviceCode, baseUrl: baseUrl, clientId: clientId);

  static Future<void> disconnect(String provider) => rust.disconnectGitAuth(provider: provider);

  static Future<UserRepoPage> listUserRepos(String provider, int page) => rust.listUserRepos(provider: provider, page: page);

  static Future<void> savePat(String host, String username, String token) => rust.saveGitPat(host: host, username: username, token: token);

  static Future<void> removePat(String host) => rust.removeGitPat(host: host);

  static Future<bool> branchProtection(String path) => rust.gitBranchProtection(path: path);

  static Future<String> openPullRequest(String path, String branch, String base, String title) =>
      rust.gitOpenPullRequest(path: path, branch: branch, base: base, title: title);
}
