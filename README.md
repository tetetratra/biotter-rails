# Biotter

## !!サービス終了しました!!
2021年6月をもちまして、biotterのサービスを終了させていただきまました。
長らくのご利用、本当にありがとうございました。

---


ツイッターのプロフィール履歴を残すことができるwebサイト

サイト: https://biotter.herokuapp.com


Bot: <a href="https://twitter.com/_Biotter_">@\_Biotter\_</a>

Botをフォローすると登録、アンフォローで登録解除です。

---

## 技術的な

- サーバー
  - Ruby on Rails on heroku
- DB
  - herokuのDB
- 画像置き場
  - s3
- ssl非対応

環境変数

```
# Rails用
BUNDLE_WITHOUT=development:test
RAILS_MASTER_KEY
```

```
# Bot用
BIOTTER_ACCESS_TOKEN
BIOTTER_CONSUMER_KEY
BIOTTER_ACCESS_TOKEN_SECRET
BIOTTER_CONSUMER_SECRET
```
