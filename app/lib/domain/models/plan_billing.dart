/// 発信者向けの課金（機能仕様書 4.6.6）。有料は、X連携プラン（商品「X連携プラン」）だけ。
/// ストアの購入（RevenueCat）から作る。
library;

/// ストアの価格。
class PlanPrice {
  const PlanPrice({
    required this.amount,
    required this.currencyCode,
    required this.formatted,
  });

  final double amount;
  final String currencyCode;

  /// ストアが書式を整えた価格（例：「¥290」）。
  final String formatted;

  bool get isYen => currencyCode == 'JPY';

  /// [amount] を、この価格と同じ書式（通貨の記号・小数の区切りと桁）で書く。
  /// ストアがくれない金額に使う。日本円は、[yen] で書く（表示言語の書式。日本語なら「290円」の形）。
  String format(double amount, {required String Function(int amount) yen}) {
    if (isYen) return yen(amount.round());
    final number = RegExp(
      r'\d[\d.,\s\u00a0\u202f]*\d|\d',
    ).firstMatch(formatted);
    if (number == null) return '$currencyCode ${amount.toStringAsFixed(2)}';
    final text = number.group(0)!;
    // 末尾の1〜2桁だけを小数とみなす（「12,000」の区切りは小数ではない）。
    final decimal = RegExp(r'([.,])(\d{1,2})$').firstMatch(text);
    var value = amount.toStringAsFixed(decimal?.group(2)!.length ?? 0);
    if (decimal?.group(1) == ',') value = value.replaceAll('.', ',');
    return formatted.replaceRange(number.start, number.end, value);
  }
}

/// 買える商品と価格（Offering `default`）。
class PlanOffer {
  const PlanOffer({required this.xOption});

  /// X連携プラン（`creator_x_monthly`）の価格。
  final PlanPrice xOption;
}

/// いまの加入（RevenueCat の Entitlement `x_option`）。
class PlanSubscription {
  const PlanSubscription({
    this.xOption = false,
    this.expiresAt,
    this.willRenew = false,
    this.managementUrl,
  });

  static const none = PlanSubscription();

  /// X連携プランに加入中か（猶予期間を含む）。
  final bool xOption;

  /// 次の更新日（解約済みなら、終わる日）。
  final DateTime? expiresAt;

  /// 自動で更新されるか。偽なら、解約済み。
  final bool willRenew;

  /// ストアのサブスクの管理の画面の URL。
  final String? managementUrl;
}

/// 購入の結果。
enum PlanPurchaseResult { purchased, cancelled, pending, failed }

/// サーバーに書いた加入の期限（`plan_subscriptions`、データ設計書 3.1.11）。
/// ストアの購入（[PlanSubscription]）と違い、課金を使えない端末や、ほかの OS で買った加入も分かる。
class ServerPlanSubscription {
  const ServerPlanSubscription({this.xOptionExpiresAt});

  /// 行がない（加入したことがない）。
  static const none = ServerPlanSubscription();

  factory ServerPlanSubscription.fromRow(Map<String, dynamic> row) =>
      ServerPlanSubscription(
        xOptionExpiresAt: _expiry(row['x_option_expires_at']),
      );

  /// X連携プランの期限。空なら、加入したことがない。
  final DateTime? xOptionExpiresAt;

  /// [now] に加入中か（X連携プランの期限が、[now] より後）。
  bool activeAt(DateTime now) {
    final expiresAt = xOptionExpiresAt;
    return expiresAt != null && expiresAt.isAfter(now);
  }

  /// 期限のない購入（`infinity`）は、遠い先の日時にする。
  static DateTime? _expiry(Object? value) {
    if (value is! String) return null;
    if (value == 'infinity') return DateTime.utc(9999, 12, 31);
    return DateTime.tryParse(value);
  }
}
