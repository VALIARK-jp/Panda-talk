// Valiark 横断の認証説明・公開リンク（文言・URL は必要に応じて差し替え）。

class ValiarkSisterAppLink {
  const ValiarkSisterAppLink({required this.title, required this.uri});

  final String title;
  final Uri uri;
}

/// 他 Valiark アプリなど（ストア・Web）。URL は公開後に [uri] だけ更新すればよい。
final valiarkSisterAppLinks = <ValiarkSisterAppLink>[
  ValiarkSisterAppLink(
    title: 'Who eats',
    uri: Uri.parse('https://valiark.jp'),
  ),
];

/// ログイン／新規登録時の主メッセージ（アプリ間でアカウント・認証が共通であること）。
const valiarkUnifiedAccountLeadJa =
    'ログイン・新規登録に使うアカウントは、VALIARK合同会社が提供するアプリどうしで共通です。'
    'メール・LINE・Apple・Google など、どの方法でサインインしても同じアカウントとして扱われます。'
    'ほかの Valiark アプリでも、そのログイン情報のままお使いいただけます。';

/// 取得情報の扱い（全ログイン方式共通の補足）。
const valiarkAuthSupplementJa =
    '取得する情報は各アプリの提供に必要な範囲に限定します。';
