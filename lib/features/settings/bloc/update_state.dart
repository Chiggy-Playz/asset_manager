import '../../../data/models/update_info_model.dart';

sealed class UpdateState {}

class UpdateInitial extends UpdateState {}

class UpdateChecking extends UpdateState {}

class UpdateAvailable extends UpdateState {
  final UpdateInfoModel updateInfo;
  UpdateAvailable(this.updateInfo);
}

class UpdateNotAvailable extends UpdateState {}

class UpdateDownloading extends UpdateState {
  final double progress;
  UpdateDownloading(this.progress);
}

class UpdateDownloaded extends UpdateState {
  final String filePath;
  UpdateDownloaded(this.filePath);
}

class UpdateError extends UpdateState {
  final String message;
  UpdateError(this.message);
}
