import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oiboshi/data/services/common/image_picker_service.dart';

/// 渡された大きさを覚えておく ImagePicker の代わり。写真は選ばない。
class _RecordingPicker extends Fake implements ImagePicker {
  double? maxWidth;
  double? maxHeight;
  int? imageQuality;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    this.imageQuality = imageQuality;
    return null;
  }
}

void main() {
  test('写真は、幅だけでなく長辺で縮める（縦長の写真も大きいまま上げない）', () async {
    final picker = _RecordingPicker();

    final bytes = await ImagePickerService(picker).pickImage(maxSide: 1600);

    expect(bytes, isNull);
    expect(picker.maxWidth, 1600);
    expect(picker.maxHeight, 1600);
    expect(picker.imageQuality, 85);
  });
}
