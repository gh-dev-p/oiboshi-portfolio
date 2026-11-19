import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OiboshiClipboard") {
      ClipboardChannel.register(messenger: registrar.messenger())
    }
  }
}

/// 初回起動の引き継ぎ（届ける・広める仕様書 4.3.4、tech-risks 2.31）で、クリップボードに URL らしいものがあるかを、
/// 中身を読まずに確かめる。`detectPatterns` は iOS の「ペーストを許可」の確認を出さない。中身を読むのは Dart の側。
enum ClipboardChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.example.oiboshi/clipboard", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let pasteboard = UIPasteboard.general
      switch call.method {
      case "hasProbableWebUrl":
        // 中身を読まない（確認は出ない）。何も無ければ、確かめるまでもない。
        guard pasteboard.numberOfItems > 0 else {
          result(false)
          return
        }
        pasteboard.detectPatterns(for: [\.probableWebURL]) { detected in
          let found = (try? detected.get())?.contains(\.probableWebURL) ?? false
          DispatchQueue.main.async { result(found) }
        }
      case "readProbableWebUrl":
        // URL らしい部分の中身を読む（「ペーストを許可」の確認が出る）。許可されなければ nil。
        // 確認を待つあいだメインスレッドを止めないよう、非同期に読む detectValues を使う（Flutter の Clipboard.getData は同期に読む）。
        // シミュレーター（署名なし）では、同期でも非同期でも、確認が画面に出ずに断られた（2026-11-15）。実機で確かめる（tech-risks 2.31）。
        pasteboard.detectValues(for: [\.probableWebURL]) { detected in
          let url = (try? detected.get())?.probableWebURL
          DispatchQueue.main.async { result(url) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
