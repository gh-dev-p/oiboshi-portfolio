import 'dart:async';
import 'dart:typed_data';

import 'package:oiboshi/data/services/common/image_picker_service.dart';

/// 端末の写真を選ぶ代わり。[picked] を返す（null なら、選ばなかった）。
class FakeImagePickerService implements ImagePickerService {
  FakeImagePickerService({this.picked});

  Uint8List? picked;

  /// 選んだ回数。
  int picks = 0;

  @override
  Future<Uint8List?> pickImage({required double maxSide}) async {
    picks++;
    return picked;
  }
}
