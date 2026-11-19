import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/event.dart';
import 'package:oiboshi/l10n/app_localizations_en.dart';
import 'package:oiboshi/l10n/app_localizations_ja.dart';
import 'package:oiboshi/ui/core/ui/l10n_labels.dart';

void main() {
  test('ツイキャスのリンクは、表示言語の SNS の名前で出す', () {
    const link = EventLink(url: 'https://twitcasting.tv/c:example/shopcart');
    expect(link.isTwitCasting, isTrue);
    expect(AppLocalizationsJa().eventLinkSite(link), 'ツイキャス');
    expect(AppLocalizationsEn().eventLinkSite(link), 'TwitCasting');
  });

  test('チケットサイトのリンクは、Model のサイトの名前で出す', () {
    const link = EventLink(
      url: 'https://t.pia.jp/pia/event/event.do?eventCd=1',
    );
    expect(link.isTwitCasting, isFalse);
    expect(AppLocalizationsEn().eventLinkSite(link), 'チケットぴあ');
  });
}
