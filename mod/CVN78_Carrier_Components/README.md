# CVN-78 Carrier Components

このフォルダには、`SW_BattleMatchmaker` の CVN-78 空母用カスタムコンポーネント mod が含まれています。`mod.xml` は mod 名を `CVN-78 Carrier Components` と定義し、`manifest.json` は車両 ID `13`・`15`・`14` と必要な component definition 名を対応付けています。各 definition の `.bin` は `data/components/` にあります。

リポジトリの [`vehicle_13.xml`](../../vehicle_13.xml)、[`vehicle_15.xml`](../../vehicle_15.xml)、[`vehicle_14.xml`](../../vehicle_14.xml) は、`c` 要素の `d` 属性でこの mod の component definition を参照します。対応する `vehicle_13/`、`vehicle_15/`、`vehicle_14/` フォルダ内の `.bin` ファイルも車両アセットの一部です。`playlist.xml`、車両 XML、同名フォルダ、`mod/` 以下の構成をまとめて保ってください。

利用環境での mod 導入先やインポート手順は、このリポジトリからは確定できません。利用環境で確立済みの Stormworks mod 導入手順に従ってください。ゲーム内での読み込みや空母の実動作は未検証です。全体の使用方法は [リポジトリ README](../../README.md#cvn-78-空母) を参照してください。
