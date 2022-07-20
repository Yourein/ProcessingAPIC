# ProcessingAPIC

Javaの基本機能のみを用いてmp3からアルバムアートを抜き出すことができるライブラリです。
主にProcessingで使うことを想定しています。

## Constructor

```processing
AlbumArtExtractor ext        = new AlbumArtExtractor(); //Debug出力なし
AlbumArtExtractor extWoDebug = new AlbumArtExtractor(false); //Debug出力なし
AlbumArtExtractor extWDebug  = new AlbumArtExtractor(true); //Debug出力あり
```

## 使い方

インスタンスのpublicメソッド、```generateAlbumArt()```にID3v2.3でタグ情報が書き込まれたmp3ファイルの絶対パスを与えてください。
返り値は以下の通りです。

|return value|value mean|
|------|---|
|-1|No file exported|
|1|jpeg file exported|
|2|png file exported|

返り値が1, 2のとき、Processingのスケッチが存在するフォルダに```out.jpeg```もしくは```out.png```を作成します。
これを```loadImage```することで、Processing内でmp3ファイルのアルバムアート取得を完結できます。

詳しくは、```ProcessingAPIC.pde```内のサンプルコードを確認してください。

## モチベーション

minimライブラリでは一部ID3メタデータの取得をサポートしていますが、APICタグを始めとする複数のタグには対応していません。
このライブラリではAPICタグの取得、書き出しをサポートすることで、minim使用時のコーディングをサポートすることを目的としています。

やる気があれば、ID3v2.xに対応します。(x not equal 3)