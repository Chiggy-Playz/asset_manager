class UpdateInfoModel {
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String? sha256;

  UpdateInfoModel({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.sha256,
  });

  factory UpdateInfoModel.fromJson(Map<String, dynamic> json) {
    return UpdateInfoModel(
      versionCode: json['versionCode'] as int,
      versionName: json['versionName'] as String,
      apkUrl: json['apkUrl'] as String,
      sha256: json['sha256'] as String?,
    );
  }
}
