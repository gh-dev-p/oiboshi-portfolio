import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// 端末の写真から1枚を選ぶ（発信者のカバー・アイコン）。image_picker を包むだけで、状態は持たない。
class ImagePickerService {
  ImagePickerService(this._picker);

  final ImagePicker _picker;

  /// 写真を選び、長辺が [maxSide] に収まるよう縮めて（品質 85）バイト列で返す。選ばなければ null。
  Future<Uint8List?> pickImage({required double maxSide}) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: 85,
    );
    return file?.readAsBytes();
  }
}
