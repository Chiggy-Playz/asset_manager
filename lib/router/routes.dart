abstract class Routes {
  static const splash = '/';
  static const login = '/login';
  static const otpVerify = '/otp-verify';
  static const createProfile = '/create-profile';
  static const home = '/home';

  // Assets
  static const assets = '/home/assets';
  static const assetCreate = '/home/assets/new';
  static const assetDetail = '/home/assets/:id';
  static const assetEdit = '/home/assets/:id/edit';

  // Admin (admin only)
  static const admin = '/home/admin';
  static const adminUsers = '/home/admin/users';
  static const adminLocations = '/home/admin/locations';

  // Settings
  static const settings = '/home/settings';

  // Helper for dynamic routes
  static String assetDetailPath(String id) => '/home/assets/$id';
  static String assetEditPath(String id) => '/home/assets/$id/edit';
}
