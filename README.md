# AnonymousPost4Mstdn
ダイレクトメッセージを受け取るとその内容をpublicに投稿することで、匿名でコミュニケーションを取ることができます。色々問題があるので使うときにはサーバー管理者の許可を得た方が良いと思います。

## 使い方
1. 以下を参考に`key.yml`という設定ファイルを作成し、どうにかして`base_url`と`access_token`を入手して記載する。`account`には名前を入れてください。
```key.yml
base_url: theboss.tech
access_token: tx8j4j3yb5ibxuns6i3w73ndpffmg4c7jxcr7jr5psgn5de4a38k5d5jjc4tsir8
account: AnonymousPost
```
3. `bundle install`
4. `bundle exec ruby main.rb`
5.  ✌('ω'✌ )三✌('ω')✌三( ✌'ω')✌

## 現状の問題
- リプライの処理
- 連投を制限？

## その他
問題を発見した方は連絡していただけるとありがたいです。
