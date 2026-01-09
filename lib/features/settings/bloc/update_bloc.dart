import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/models/update_info_model.dart';
import '../../../data/repositories/update_repository.dart';
import 'update_event.dart';
import 'update_state.dart';

class UpdateBloc extends Bloc<UpdateEvent, UpdateState> {
  final UpdateRepository _updateRepository;
  UpdateInfoModel? _updateInfo;

  UpdateBloc({required UpdateRepository updateRepository})
      : _updateRepository = updateRepository,
        super(UpdateInitial()) {
    on<UpdateCheckRequested>(_onCheckRequested);
    on<UpdateDownloadRequested>(_onDownloadRequested);
  }

  Future<void> _onCheckRequested(
    UpdateCheckRequested event,
    Emitter<UpdateState> emit,
  ) async {
    emit(UpdateChecking());

    try {
      final updateInfo = await _updateRepository.checkForUpdate();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      _updateInfo = updateInfo;

      if (updateInfo.versionCode > currentVersionCode) {
        emit(UpdateAvailable(updateInfo));
      } else {
        emit(UpdateNotAvailable());
      }
    } catch (e) {
      emit(UpdateError(e.toString()));
    }
  }

  Future<void> _onDownloadRequested(
    UpdateDownloadRequested event,
    Emitter<UpdateState> emit,
  ) async {
    if (_updateInfo == null) {
      emit(UpdateError('No update info available'));
      return;
    }

    emit(UpdateDownloading(0));

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/app-update.apk';

      final dio = Dio();
      await dio.download(
        _updateInfo!.apkUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            emit(UpdateDownloading(received / total));
          }
        },
      );

      emit(UpdateDownloaded(filePath));
    } catch (e) {
      emit(UpdateError('Download failed: $e'));
    }
  }
}
