import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM（`firebase_messaging`）。送り先は、Firebase Installation ID（FID）で登録する（tech-risks.md 2.15）。
/// Firebase を初期化していない端末では、[available] が偽で、何もしない。
class PushMessagingService {
  PushMessagingService(this._messaging);

  /// Firebase を初期化していれば、FCM を返す。していなければ null。
  static FirebaseMessaging? instanceIfReady() =>
      Firebase.apps.isEmpty ? null : FirebaseMessaging.instance;

  final FirebaseMessaging? _messaging;

  bool get available => _messaging != null;

  /// FCM に登録し、送り先（FID）を返す。iOS は APNs のトークンを待つので、30秒で切る。
  Future<String> register() async {
    final messaging = _messaging!;
    final registered = messaging.onRegistered.first.timeout(
      const Duration(seconds: 30),
    );
    try {
      await messaging.register();
    } catch (_) {
      // 待っている onRegistered の打ち切りが、未処理のエラーにならないようにする。
      registered.ignore();
      rethrow;
    }
    return registered;
  }

  /// 送り先（FID）が登録された・変わったとき。
  Stream<String> get onRegistered =>
      _messaging?.onRegistered ?? const Stream.empty();

  /// アプリが終わっていたときに、通知を押して開いたなら、その通知。
  Future<RemoteMessage?> initialMessage() async =>
      _messaging?.getInitialMessage();

  /// アプリが裏にいるときに、通知を押して開いた。
  Stream<RemoteMessage> get onMessageOpenedApp =>
      available ? FirebaseMessaging.onMessageOpenedApp : const Stream.empty();

  /// アプリを開いているときに届いた。
  Stream<RemoteMessage> get onMessage =>
      available ? FirebaseMessaging.onMessage : const Stream.empty();
}
