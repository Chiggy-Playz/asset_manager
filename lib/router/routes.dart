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

  // Requests (for users)
  static const requests = '/home/requests';

  // Admin (admin only)
  static const admin = '/home/admin';
  static const adminUsers = '/home/admin/users';
  static const adminLocations = '/home/admin/locations';
  static const adminFieldOptions = '/home/admin/field-options';
  static const adminRequests = '/home/admin/requests';

  // Settings
  static const settings = '/home/settings';

  // Helper for dynamic routes
  static String assetDetailPath(String id) => '/home/assets/$id';
  static String assetEditPath(String id) => '/home/assets/$id/edit';
}
