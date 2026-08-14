# SW_BattleMatchmaker

`SW_BattleMatchmaker` は、Stormworks: Build and Rescue の Weapons DLC を使ったチーム戦を管理するサーバーアドオンです。

遊ぶ人は前半の「ユーザー向けガイド」を読めば参加できます。コマンド・設定・内部処理を確認する開発者やサーバー管理者は、後半の詳細仕様を参照してください。

## 1. ユーザー向けガイド

### このアドオンでできること

- RED / BLUE などのチームに分かれて対戦できます。
- 参加者の Ready 状態、試合時間、勝敗を自動で管理します。
- 自分の車両が登録されると、画面に車両名と HP が表示されます。
- 補給所から装備や弾薬を受け取れます。
- 味方の位置や戦闘エリアをマップで確認できます。

### 試合の簡単な流れ

1. **Standby に参加する**
   通常は短縮コマンドの `?mm j` だけを入力します。これは `?mm join` と同じコマンドで、チーム名を省略すると `Standby` に入ります。運営から直接チームを指定された場合は、`?mm j RED` や `?mm j BLUE` を使います。
2. **チーム分けを待つ**
   参加者が揃ったら、Admin が `?mm sh2`（`?mm shuffle2`）でチーム分けします。引数を省略した場合は2チームです。3チーム以上に分ける場合だけ、`?mm sh2 3` のようにチーム数を追加します。
3. **車両を登録する**
   自分の車両をスポーンするか、使用する車両の座席に座ります。画面に車両名と HP が出れば登録完了です。
4. **開始地点へ移動する**
   必要なら短縮コマンドの `?mm o`（`?mm order`）で、登録車両を自分の前へ呼び出します。
5. **準備完了にする**
   準備ができたら短縮コマンドの `?mm r`（`?mm ready`）を実行します。Ready を取り消すコマンドは `?mm wait` です。
6. **試合開始**
   全員が Ready になると、5 秒のカウントダウン後に試合が始まります。Admin は `?mm s`（`?mm start`）で強制開始を試みられます。
7. **試合終了**
   制限時間になるか、生存しているチームが 1 つ以下になると終了します。

操作が分からないときは `?mm` で使用可能なコマンドを確認できます。

### 画面の見方

| 表示 | 意味 |
| --- | --- |
| `Wait` | 試合前・準備待ち |
| `Ready` | 試合前・準備完了 |
| `Alive` | 試合中・生存 |
| `Logout` | 試合中にログアウト中 |
| `Dead` | 死亡・車両撃破済み |

画面にはチーム、プレイヤー名、状態、登録車両名、HP が表示されます。試合中にログアウトしても情報は保持され、同じ Steam アカウントで戻ると試合へ復帰します。ただし、ログアウト中は勝敗判定上の生存者には数えられません。

### プレイヤーがよく使うコマンド

| コマンド | 用途 |
| --- | --- |
| `?mm` | 使用できるコマンドと現在設定を表示 |
| `?mm join (チーム名)` / `?mm j (チーム名)` | チームへ参加。省略時は Standby |
| `?mm leave` / `?mm l` | チームから離脱 |
| `?mm ready` / `?mm r` | 準備完了にする |
| `?mm wait` | Ready を取り消す |
| `?mm order` / `?mm o` | 登録車両を自分の前へ呼び出す |
| `?mm remove` / `?mm rm` | 登録車両のグループを削除 |
| `?mm sit (vehicle_id)` | 登録車両または指定車両の空席へ座る |
| `?mm supply` | 自分用の補給所を設置 |
| `?mm delete_supply` | 自分用の補給所を削除 |
| `?mm give` | 基本装備を受け取る |
| `?mm tp` | 自チームに割り当てられた旗へ移動 |
| `?mm die` | 試合中に自分を死亡状態にする |
| `?mm reset_ui` | 画面表示を作り直す |

通常のプレイヤーコマンドには Auth が必要です。多くのワールドでは参加時に自動付与されます。

### 短縮コマンド一覧

短縮コマンドでも通常コマンドと同じ引数を指定できます。

| 権限 | 通常コマンド | 短縮コマンド |
| --- | --- | --- |
| Auth | `?mm join` | `?mm j` |
| Auth | `?mm leave` | `?mm l` |
| Auth | `?mm ready` | `?mm r` |
| Auth | `?mm order` | `?mm o` |
| Auth | `?mm remove` | `?mm rm` |
| Admin | `?mm shuffle2` | `?mm sh2` |
| Admin | `?mm start` | `?mm s` |
| Admin | `?mm flag` | `?mm f` |
| Admin | `?mm shuffle` | `?mm sh` |
| Admin | `?mm shuffle_airbase` | `?mm sa` |
| Admin | `?mm shuffle_ground_base` | `?mm sg` |
| Admin | `?mm debug_ground_base` | `?mm dgb` |
| Admin | `?mm SJAC` | `?mm sjac` |
| Admin | `?mm SGAC` | `?mm sgac` |
| Admin | `?mm battle_mode` | `?mm bm` |

### 補給の使い方

`?mm supply` で自分の前に補給所を設置できます。補給所のボタンからチーム参加、装備取得、装備解除ができます。試合が始まると補給所は自動で削除されます。

弾薬は、車両や拠点にある次の名前のボタンから受け取ります。

| 種類 | ボタン名の例 |
| --- | --- |
| Machine Gun | `MG_K`、`MG_AP`、`MG_I` |
| Light Auto Cannon | `LA_K`、`LA_HE`、`LA_F`、`LA_AP`、`LA_I` |
| Rotary Auto Cannon | `RA_K`、`RA_HE`、`RA_F`、`RA_AP`、`RA_I` |
| Heavy Auto Cannon | `HA_K`、`HA_HE`、`HA_F`、`HA_AP`、`HA_I` |
| Battle Cannon | `BS_K`、`BS_HE`、`BS_F`、`BS_AP`、`BS_I` |
| Artillery Cannon | `AS_HE`、`AS_F`、`AS_AP` |

弾薬を受け取る前に、大型装備スロットを空にしてください。

### ゲームモード

| モード | プレイヤー向けの違い |
| --- | --- |
| SJAC | `?mm sjac` で適用するプリセット。車両 HP は 50、ネームプレートは表示になります。 |
| SGAC | `?mm sgac` で適用する地上戦向けプリセット。車両 HP は 6000、ネームプレートは非表示になります。 |
| SGAC + CENTER | SGAC で利用できる追加モードです。中央に安全エリアが作られ、試合中にエリアが徐々に狭くなります。 |

ネームプレートの違いは SJAC / SGAC コマンドが適用する既定プリセットの差です。Admin が `nameplate_enabled` を変更した場合は、その設定が次回の試合開始時に使われます。

SGAC + CENTER では、マップの `BattleArea` 円内に留まってください。境界へ近づくと距離警告が表示され、エリア外の登録車両は砲撃を受けます。

### 困ったときは

- **画面左の一覧が出ない**: `?mm reset_ui`
- **車両名や HP が出ない**: チーム参加後に、座席のある車両へ一度座ってください。
- **`order` で車両が見つからない**: 車両が登録されているか確認してください。WebMap 連携時は保存済み車両の復元を試みる場合があります。
- **コマンドが Permission denied になる**: Auth または Admin 権限が必要です。
- **Ready を取り消したい**: `?mm wait`
- **補給所を消したい**: `?mm delete_supply`

## 2. 開発者・サーバー管理者向け仕様

以下は [`script.lua`](./script.lua) Version 1.6.3 を正本とした詳細仕様です。公開コマンド 40 件、変更可能設定 32 件、状態遷移、アドオン部品、外部連携をコードの実挙動に合わせて記載しています。

### 必要条件とアドオン構成

- Stormworks: Build and Rescue
- Weapons DLC
- 本アドオンの `playlist.xml`、`script.lua`、同梱の `vehicle_*.xml`
- WebMap 連携を使う場合のみ、アドオン名が `WebMap` の WebMap アドオン

ワールド作成時に本アドオンを有効化してください。既定値の多くはアドオンプロパティから変更できます。既存ワールドでは `g_savedata` の値が優先され、未保存の項目だけが現在の既定値で補完されます。

同梱アドオンには、スクリプトが検索する `name=supply`、`name=flag`、`name=flag_red`、`name=flag_blue`、`name=flag_center`、`name=iff_sender`、`name=alt` の各コンポーネントが含まれています。

スクリプト初期化時は、保存済みの補給オブジェクトと旗を削除し、待機中のゲーム設定を適用し、UI を作成し直します。新規ワールド作成時だけ固定 4 地点の IFF 送信機を作成します。その後、WebMap 検出と航空基地座標の解決を行います。

### 権限モデル

| 表記 | 実行条件 |
| --- | --- |
| 全員 | Auth / Admin を要求しない |
| Auth | Auth または Admin が必要 |
| Admin | Admin が必要 |

`auto_auth=true` の場合、参加時に Auth がないプレイヤーへ自動で Auth を付与します。Admin はすべての Auth コマンドも実行できます。

### チームとプレイヤー状態の詳細

- 標準チームは `RED`、`BLUE`、`PINK`、`YLW` です。
- `r`、`R`、`red` は `RED`、`b`、`B`、`blue` は `BLUE` に正規化されます。
- その他のチーム名は大文字化され、チーム名省略時は `Standby` です。
- `Standby` も Ready 数、チーム数、勝敗判定上の通常チームとして扱います。
- `join` と `leave` は試合中も禁止されていません。試合中の `join` は `alive=true`、`ready=true` で登録します。
- 全参加者が Ready かつ 2 チーム以上なら 300 tick のカウントダウンを開始します。Admin の強制開始では 1 チームでも開始できます。
- 全参加者の 50% 以上が Ready になると、未 Ready の生存者へ 20 秒ごとに催促し、移動ポップアップを最大 8 枚まで追加します。

試合中は、プレイヤー自身の死亡、`die`、登録車両の HP 0、水没、デスポーンで死亡状態になります。同じ車両に複数の生存者が紐付く場合、1 人の `die` だけでは車両を撃破しません。車両自体が撃破された場合は紐付く全員を死亡扱いにします。

勝敗判定では、接続中かつ `alive=true` のプレイヤーだけを生存者として数えます。生存チームが 1 チームなら勝利、0 チームなら引き分けです。参加者情報が 0 件なら中断します。時間切れは `TimeUp` で終了し、勝利チームを再計算しません。

試合中のログアウトではチーム、Alive、車両 ID、車両 HP を SteamID64 キーで保持します。Logout は勝敗判定の生存者に含めませんが、登録車両のダメージと水没は処理します。同じ SteamID64 で戻ると新しい `peer_id` へ状態を移します。試合外のログアウトは `leave` と同じで、試合終了時に残った Logout 情報は削除します。

### 試合開始時・終了時の処理

#### 試合開始時

- 制限時間を `game_time` 分に設定
- 参加者の Ready を解除
- 補給オブジェクトをすべて削除
- 三人称、ネームプレート、プレイヤーダメージ、標準マップ表示を試合用設定へ変更
- IFF 周波数を再生成
- WebMap があれば最大ダメージと SJAC / SGAC 開始イベントを送信

試合中は残り時間の 1/4 ごとに通知します。タイマーが残り 5 分ちょうどに到達した tick でネームプレートを強制的に有効化し、全車両をマップ表示対象にします。試合時間が最初から 5 分未満の場合、このネームプレート強制処理は通りませんが、独自マップ表示は残り 5 分以下として全対象を表示します。

#### 試合終了時

- 接続中の全キャラクターを蘇生し、HP を 100 に設定
- `auto_standby=true` なら全参加者を `alive=true`、`ready=false` にする
- ログアウト中の参加者を削除
- 三人称、ネームプレート、標準マップ表示を有効化し、車両・プレイヤーダメージを無効化
- `infinite_ammo` を有効化
- `?cleanup` コマンドを発行
- `auto_battle=true` かつ中止ではない場合、自動バトル準備を予約

本スクリプトは試合開始時に `infinite_ammo` を無効化しないため、待機処理で有効になった値はそのままです。

### 車両管理

#### 登録条件と所有車両

参加中かつ生存中のプレイヤーについて、次のタイミングで車両を登録します。

- `auto_link_on_spawn=true` のとき、自分がスポーンしたグループの親車両がロードされた時
- 車両の座席へ座った時。この経路は `auto_link_on_spawn` の値に関係なく動作します。
- WebMap キャッシュから車両が復元された時

座席のない車両は登録しません。新しい車両を登録すると、そのプレイヤーの現在車両は新しい ID に切り替わります。グループの移動・削除には、登録車両の `group_id` を使用します。

スポーンによる自動登録と `?mm order` は WebMap 復元キャッシュへ車両を登録しますが、単に別車両へ座っただけではキャッシュ登録しません。

#### HP

`adaptive_hp=false` の最大 HP は `vehicle_hp` です。

`adaptive_hp=true` の場合は、登録時に次の式で最大 HP を計算します。

```text
推定HP = ボクセル数 × hp_per_voxel
hp_step > 0 の場合、推定HPを hp_step 単位で切り捨て
最大HP = max(min(推定HP, vehicle_hp), min_hp)
最終的に 1 以上の整数へ変換
```

通常は `vehicle_hp` が Adaptive HP の上限、`min_hp` が下限です。ただし `min_hp > vehicle_hp` の設定では、コード上の計算順により `min_hp` が優先されます。HP 関連設定や弾薬回数を `?mm set` で変更しても、既に登録済みの車両へは通常さかのぼって適用されません。`?mm SJAC` / `?mm SGAC` は生存中の登録車両を再計算し、現在 HP も新しい最大 HP まで回復させます。

#### ダメージ・水没・撃破

- 正の `onVehicleDamaged` 値を tick 内で合計し、`max_damage` をその tick の上限として HP から減算します。
- HP 減算は試合中だけです。`max_damage=0` では HP ダメージが 0 に制限されます。
- `sunk_depth>0` の場合、車両 Y 座標が `-sunk_depth` より下になると撃破扱いです。この判定は試合外でも動作します。
- 撃破時は威力 `0.17` の爆発を発生させ、Tooltip を `Destroyed` にします。
- `gc_vehicle=true` の場合、撃破状態になってから 60 tick 後（通常約 1 秒）に車両グループを削除します。
- 車両が外部要因でデスポーンした場合も登録解除され、試合中なら紐付くプレイヤーを死亡扱いにします。

#### 車両上ポップアップ

- チームメンバーには、所有プレイヤー名と自分からの距離 km を常時表示します。所有者本人には名前を表示しません。
- `damage_popup=true` の場合、`min_damage_popup` 以上の蓄積ダメージと残 HP 率を表示します。
- 味方用ダメージは 180 tick、その他の閲覧者用は 120 tick 蓄積・表示します。
- 表示距離は `damage_popup_distance` です。
- 高さは距離 0 m で 3 m、距離 2,000 m で `damage_popup_max_height` となる線形補間です。

### マップ表示

`show_friends=true` かつプレイヤーが生存中の場合、登録車両またはキャラクターをチーム色で表示します。

- 同じチームの閲覧者には表示します。
- 自分のアイコンは通常の不透明度、他者は半透明です。
- Logout 中は車両だけを全閲覧者へ半透明表示します。
- Matchmaker に未参加の閲覧者には全対象が表示されます。
- 残り時間が 5 分以下になると、敵を含む全対象を表示します。

待機中は Stormworks 標準のプレイヤー・車両マップ表示を有効化し、試合中は無効化します。

### ゲームモード詳細

#### SJAC / SGAC プリセット

`?mm SJAC` と `?mm SGAC` は、モードフラグだけでなく関連設定と既存車両 HP をまとめて変更します。

| 項目 | SJAC | SGAC |
| --- | ---: | ---: |
| `game_mode_sjac` | `true` | `false` |
| `vehicle_hp` | 50 | 6000 |
| `max_damage` | 1000 | 3000 |
| `sunk_depth` | 1 | 5 |
| `game_time` | 15 | 15 |
| `damage_popup_max_height` | 15 | 15 |
| `nameplate_enabled` | `true` | `false` |
| `infinite_batteries` | `true` | `false` |
| WebMap `ground_mode` | `false` | `true` |

`?mm set game_mode_sjac true|false` はフラグ 1 個だけを変更し、このプリセット処理は実行しません。通常は `?mm SJAC` / `?mm SGAC` を使用してください。

新規ワールドでアドオンプロパティ `Game Mode SJAC:True SGAC:False` が `false` の場合、初期化時に SGAC プリセットを適用します。

#### Battle Mode 0: 通常

`battle_mode=0` は通常モードです。CENTER 旗は削除され、縮小戦域、境界警告、境界砲撃を使用しません。

#### Battle Mode 1: CENTER 縮小戦域

`battle_mode=1` にすると、RED と BLUE の旗の中点へ `CENTER` 旗を配置します。実際の縮小・警告・砲撃は SGAC、試合中、`battle_mode=1` のすべてを満たす場合だけ動作します。

- 初期半径は `max(300, RED-BLUE間距離 ÷ 2 × 1.5)` m です。
- 試合時間全体を使って 300 m まで線形に縮小します。
- CENTER のマップ円は 60 tick ごとに更新します。
- CENTER 上空 1,000 m の表示に、中心距離、現在半径、境界までの距離、境界到達予想時間をプレイヤー別に表示します。
- 境界まで 75 m 以下になると、最短方向と登録車両の前方進路上の交点へ警告を表示します。
- 境界付近では円周上に威力 `0.2` の爆発を確率発生させます。
- 戦域外では、生存プレイヤーの登録車両へ 1 tick あたり 1/40 の確率で威力 `0.2` の爆発を発生させます。
- Logout 中の生存者はプレイヤー位置の代わりに登録車両位置で監視します。

CENTER の地表高度は `name=alt` の高度チェッカーと `alt` ダイヤルで測定します。600 tick 以内に取得できなければ RED / BLUE 高度の中間値へフォールバックします。`flag_center` のピボット補正として地表から 27 m 上へ配置します。

### 全コマンド仕様

引数表記は `[必須]`、`(任意)` です。`?mm` だけを実行すると、自分が実行可能なコマンド一覧と現在の 32 設定値を表示します。

#### 全員が実行可能

| コマンド | 短縮コマンド | 説明 |
| --- | --- | --- |
| `?mm iff create` | なし | 現在位置へ IFF 送信機を 1 台追加します。 |
| `?mm iff create all` | なし | 既存 IFF 送信機を全削除し、固定 4 地点へ再配置します。 |
| `?mm iff delete` | なし | プレイヤーに最も近い IFF 送信機を 1 台削除します。 |
| `?mm iff delete all` | なし | IFF 送信機をすべて削除します。 |
| `?mm iff list` | なし | IFF 送信機の vehicle ID と座標一覧を表示します。 |

IFF 5 コマンドには、現行 `script.lua` 上で Auth / Admin 条件がありません。

#### Auth コマンド

| コマンド | 短縮コマンド | 説明・制約 |
| --- | --- | --- |
| `?mm join (チーム名) (peer_id)` | `?mm j (チーム名) (peer_id)` | チームを作成・参加します。省略時は Standby。試合中も実行可能です。Admin だけが対象 `peer_id` を指定できます。 |
| `?mm leave (peer_id)` | `?mm l (peer_id)` | チームから離脱します。試合中は勝敗再判定を予約します。Admin だけが対象 `peer_id` を指定できます。 |
| `?mm die (peer_id)` | なし | 試合中だけ対象を死亡状態にします。Admin だけが対象 `peer_id` を指定できます。 |
| `?mm ready (peer_id)` | `?mm r (peer_id)` | 試合前だけ Ready にし、死亡状態なら生存へ戻します。Admin だけが対象 `peer_id` を指定できます。SGAC では実行者の大型装備スロットが空または Torch の場合、Torch を 400 使用量で設定します。 |
| `?mm wait (peer_id)` | なし | 試合前だけ Wait にし、死亡状態なら生存へ戻します。Ready 解除時はカウントダウンを止めます。Admin だけが対象 `peer_id` を指定できます。 |
| `?mm order` | `?mm o` | 生存中の登録車両グループを正面 8 m・上方 2 mへ移動します。試合中は `order_enabled=false` かつ非 Pause のときだけ禁止です。車両がなければ WebMap キャッシュ復元を試みます。 |
| `?mm remove` | `?mm rm` | 自分の登録車両グループを即時デスポーンします。 |
| `?mm supply` | なし | 正面 8 m・上方 1 mへ自分用補給オブジェクトを配置します。1 人 1 台で、再実行時は旧オブジェクトを置換します。試合中は Admin だけ実行可能です。 |
| `?mm delete_supply` | なし | 自分用の補給オブジェクトを削除します。 |
| `?mm reset_ui` | なし | 全 UI ID を取り直し、ポップアップ、補給・旗・車両表示を再登録します。通知は全員へ送られます。 |
| `?mm sit (vehicle_id)` | なし | 指定車両、または省略時は自分の登録車両の空席へ着席します。名前に `passenger`、`padded`、`harness` を含む座席は除外します。 |
| `?mm give` | なし | FlashLight、Binoculars、Compass、NightVision、FirstAidKit をスロット 2～6 へ設定します。参加時にも同じ基本装備を自動配布します。 |
| `?mm airports_list` | なし | 組み込み航空基地の件数、tile、名前、X/Z 座標を表示します。 |
| `?mm tp` | なし | 所属チームに割り当てられた RED / BLUE 旗座標へテレポートします。生死や試合状態による制限はありません。 |

#### Admin コマンド

| コマンド | 短縮コマンド | 説明・制約 |
| --- | --- | --- |
| `?mm start` | `?mm s` | 全生存参加者を Ready にし、強制カウントダウンを開始します。 |
| `?mm abort` | なし | カウントダウン中なら停止、試合中なら中止して終了処理を実行します。 |
| `?mm pause` | なし | 試合中の制限時間を停止します。車両・境界など tick 処理全体を止める機能ではありません。 |
| `?mm resume` | なし | Pause 中の制限時間を再開します。 |
| `?mm add_time [分]` | なし | 試合中の残り時間へ正負を含む分数を加算します。 |
| `?mm shuffle (チーム数)` | `?mm sh (チーム数)` | 試合前だけ、2～4 チームへ単純ランダムかつ均等に振り分けます。省略時は 2。 |
| `?mm shuffle2 (チーム数)` | `?mm sh2 (チーム数)` | 試合前かつカウントダウン外だけ実行できる履歴考慮シャッフルです。省略時は 2。2 未満は 2 に補正し、上限は設けていません。 |
| `?mm dismiss [チーム名]` | なし | 試合前かつカウントダウン外で、指定名と完全一致するチームの全員を除外します。 |
| `?mm reset` | なし | 全プレイヤー・登録車両情報を空にし、補給・旗を削除して終了処理を実行します。 |
| `?mm clear_supply` | なし | 全補給オブジェクトを削除します。現行実装では同時に全旗も削除します。 |
| `?mm flag [名前] (x) (z) (y)` | `?mm f [名前] (x) (z) (y)` | 旗を配置します。座標配置は x、z、y の 3 値をすべて指定した場合だけで、それ以外は実行者の正面 8 m・上方 9 mへ配置します。 |
| `?mm delete_flag [名前]` | なし | 指定名を大文字化し、その旗車両とマップ表示を削除します。 |
| `?mm clear_flag` | なし | 全旗車両とマップ表示を削除します。 |
| `?mm set (設定名) (値)` | なし | 設定を変更します。引数なしで設定名と型の一覧を表示します。 |
| `?mm SJAC` | `?mm sjac` | SJAC プリセットを適用します。 |
| `?mm SGAC` | `?mm sgac` | SGAC プリセットを適用します。 |
| `?mm battle_mode [0\|1]` | `?mm bm [0\|1]` | 通常モード 0 / CENTER 縮小戦域 1 を切り替えます。 |
| `?mm airports_resolve` | なし | X/Z が両方 0 または未設定の航空基地を tile 名から再解決します。 |
| `?mm shuffle_airbase (範囲m)` | `?mm sa (範囲m)` | RED / BLUE の航空基地を選び、旗を配置します。省略時 20,000 m。 |
| `?mm shuffle_ground_base` | `?mm sg` | 組み込み地上基地ペアを 1 組選び、RED / BLUE へ割り当てます。 |
| `?mm debug_ground_base` | `?mm dgb` | デバッグ用。全地上基地点と各ペアの CENTER 円を同時表示します。 |

### シャッフル仕様

#### `shuffle`

参加者をランダムに取り出し、RED、BLUE、PINK、YLW の順へ循環配置します。人数差は最大 1 人です。Ready は全解除され、既存カウントダウンは停止します。

#### `shuffle2`

- チーム人数差を最大 1 人にします。
- 最新割り当てと同じチームに残る人数を、各チーム人数の 40% を切り上げた数以下にする方向で評価します。
- 直近 4 回の履歴から、同じ組み合わせになったペアへペナルティを加えます。
- 12 回の初期割り当てと各 300 回の交換探索を行い、評価の良い割り当てを採用します。
- 探索に失敗した場合は単純 `shuffle` へフォールバックします。
- 履歴は `g_savedata.shuffle_history` に新しい順で最大 4 回保存します。
- 既定 4 チームを超える指定では `TEAM5`、`TEAM6` のような名前を生成します。

`shuffle2` コマンドは Admin 専用で、試合中またはカウントダウン中には実行できません。チーム数の上限は設けていません。

### 基地と旗

#### 航空基地

| 名前 | Tile | 備考 |
| --- | --- | --- |
| Oneill AirBase | `mega_island_12_6` | 初期化時に座標解決 |
| Harrison AirBase | `mega_island_2_6` | 初期化時に座標解決 |
| CoastGurd Outpost | `island_15` | 初期化時に座標解決 |
| Military Base | `island_34_military` | 初期化時に座標解決 |
| Donkk AirBase | `island_33_tile_33` | 固定 X=-19100, Z=-4700 |
| Multiplayer Island Base | `island_43_multiplayer_base` | 初期化時に座標解決 |
| FJ Warner | `arid_island_26_14` | 初期化時に座標解決 |
| Clarke Airfield | `arid_island_19_11` | 初期化時に座標解決 |
| Ender Airfield | `arid_island_7_5` | 初期化時に座標解決 |

`shuffle_airbase` は最初の基地をランダムに選び、指定範囲内の別基地をランダムに選びます。範囲内候補がなければ最寄り基地を使います。距離 5 km 以下のペアは最大 2 回選び直し、すべて近距離なら試行中で最も遠いペアを採用します。

航空基地の RED / BLUE 旗は、設定された Y が正数なら車両自体を Y=-100 へスポーンします。一方、チーム割り当てには基地テーブルの Y を保持するため、`tp` はその設定 Y を使用します。

#### 地上基地

| ペア | RED (X, Z) | BLUE (X, Z) |
| --- | ---: | ---: |
| 1 | (4000, -6000) | (1300, -3700) |
| 2 | (1500, -8700) | (3000, -10600) |
| 3 | (1100, -9400) | (-200, -12000) |
| 4 | (-5700, -11000) | (-8100, -12000) |
| 5 | (1000, -6120) | (-1300, -5500) |

`shuffle_ground_base` は 5 ペアから 1 組をランダムに選びます。高度チェッカーで地表高度を取得し、RED / BLUE 旗を地表から 10 m 上へ配置します。

#### 旗の仕様と注意

- CENTER の戦闘エリア半径は可変です。`battle_mode=1` では RED-BLUE 間距離から初期半径を計算し、SGAC の試合中は残り時間に合わせて最終半径 300 m まで縮小します。SJAC または試合外では初期半径のまま縮小しません。
- RED は `flag_red`、BLUE は `flag_blue`、CENTER は `flag_center`、その他は `flag` コンポーネントを使用します。
- RED / BLUE を配置するとチーム割り当て座標を更新し、`battle_mode=1` なら CENTER を再作成します。
- `tp` は旗車両そのものではなく、チーム割り当て座標を使います。
- 現行コードの `delete_flag`、`clear_flag`、`clear_supply` 内の `clearFlags()` は旗車両とマップ表示を消しますが、`g_flag_assignments` は消しません。そのため再割り当てまで `tp` が旧座標を参照できる場合があります。
- 自動バトル有効時の通常終了と `shuffle_ground_base` は、専用処理で RED / BLUE / CENTER の割り当ても消去します。

### 自動バトル

`auto_battle=true` の通常終了後は次の処理を行います。試合を自動開始する機能ではありません。

1. RED / BLUE / CENTER の旗と割り当てを削除します。
2. 30 秒カウント後、`shuffle2(2)` と `shuffle_airbase(20000)` 相当を実行します。
3. さらに 10 秒後、登録車両を撃破状態にし、接続中の参加者を所属チーム旗へテレポートします。
4. 自動処理を終了します。Ready 設定や試合開始は行いません。

`abort` で終了した場合は自動バトル予約を解除します。自動バトル無効時、通常の試合終了は旗割り当てを自動削除しません。

### 弾薬補給仕様

`ammo_supply=true` の場合、次の名前を付けたオン状態のボタンを押すと、大型装備スロットへ弾薬を設定します。大型装備スロットが空でなければ補給しません。

| Weapon Type | Kinetic | High Explosive | Fragmentation | Armor Piercing | Incendiary | 1回の装填数 |
| --- | --- | --- | --- | --- | --- | ---: |
| Machine Gun | `MG_K` | - | - | `MG_AP` | `MG_I` | 50 |
| Light Auto Cannon | `LA_K` | `LA_HE` | `LA_F` | `LA_AP` | `LA_I` | 50 |
| Rotary Auto Cannon | `RA_K` | `RA_HE` | `RA_F` | `RA_AP` | `RA_I` | 25 |
| Heavy Auto Cannon | `HA_K` | `HA_HE` | `HA_F` | `HA_AP` | `HA_I` | 10 |
| Battle Cannon | `BS_K` | `BS_HE` | `BS_F` | `BS_AP` | `BS_I` | 1 |
| Artillery Cannon | - | `AS_HE` | `AS_F` | `AS_AP` | - | 1 |

ボタンが登録車両上にある場合は、その車両の登録時に `ammo_mg`～`ammo_as` から砲種別の残り補給回数を初期化します。

- `0`: 補給不可
- 正数: 補給成功ごとに 1 減少
- `-1`: 無制限。コードは値を `-1` のまま維持します。
- 未登録車両または拠点上のボタン: 回数を消費せず無制限

### 補給オブジェクト仕様

`?mm supply` で 1 人 1 台まで配置でき、再配置、個別削除、ログアウト、全削除、試合開始時に削除されます。マップには `supply` ラベルを表示します。

補給オブジェクトでは次のボタン名を処理します。

| ボタン名 | 動作 |
| --- | --- |
| `Join RED` / `Join BLUE` / `Join PINK` / `Join YLW` | 対象チームへ参加 |
| `Leave` | チーム離脱 |
| `Take Extinguisher` | Extinguisher を大型装備スロットへ設定 |
| `Take Torch` | Torch を大型装備スロットへ設定 |
| `Take Welder` | Welder を大型装備スロットへ設定 |
| `Take FlashLight` | FlashLight を空き小型スロットへ設定 |
| `Take Binoculars` | Binoculars を空き小型スロットへ設定 |
| `Take NightVision` | NightVision を空き小型スロットへ設定 |
| `Take Compass` | Compass を空き小型スロットへ設定 |
| `Take FirstAidKit` | FirstAidKit を空き小型スロットへ設定 |
| `Clear Large Equipment` | スロット 1 を空にする |
| `Clear Small Equipments` | スロット 2～9 を空にする |
| `Clear Outfit` | スロット 10 を空にする |

補給車両に限らず、ボタン名 `?mm die` と `?mm ready` はそれぞれ死亡・Ready 操作として処理します。

### IFF

新規ワールド作成時は、既存 IFF を消して次の 4 地点へ `name=iff_sender` を配置します。

| # | X | Y | Z |
| ---: | ---: | ---: | ---: |
| 1 | 2768 | 5 | -30222 |
| 2 | -20750 | 5 | -30100 |
| 3 | -18855 | 5 | -5100 |
| 4 | 10745 | 5 | -8500 |

試合開始時とスクリプト初期化時に RED、BLUE、PINK 用のランダム周波数を生成します。YLW は 4 番目の標準チームのため、現行 IFF 配信対象外です。

- 登録済み生存車両の `mm_iff_freq` キーパッドへ自チーム周波数を書き込みます。
- IFF 送信機の `mm_iff_freq_1`～`mm_iff_freq_3` へ各チーム周波数を書き込みます。
- RED / BLUE / PINK それぞれ最大 10 台の X・高度・Z を、各チーム 20 個の数値スロットへ 2 float/台で配信します。
- 座標は -128,000～128,000 にクランプして 18 bit ずつ格納します。
- プレイヤー名は小文字化し、`0-9`、`a-z`、`_` だけを最大 10 文字送ります。その他の文字は除外します。
- 周波数は変更時に加え、600 tick ごとにプレイヤー車両へ再送します。

### WebMap 連携

初期化時にアドオン名を小文字化して `webmap` と一致するアドオンを探します。見つからなくても Matchmaker 本体は動作します。

見つかった場合は次を連携します。

- 登録車両のチーム色: RED、BLUE、PINK、YLW/Standby
- 車両ごとの最大 HP
- 試合全体の 1 tick 最大ダメージ
- SJAC / SGAC の開始・勝敗終了イベント
- SJAC / SGAC 切り替え時の ground mode
- 自分がスポーンした車両と `order` 済み車両の復元キャッシュ

WebMap 車両キャッシュは SteamID64 単位です。登録車両が Matchmaker 側に見つからない状態で `?mm order` を実行すると、同じスクリプトセッション中に登録成功したキャッシュだけを使い、正面 8 m・上方 2 mへ復元要求を送ります。Lua 再読み込み前の Bridge 側キャッシュは意図的に使用しません。復元車両は最大 600 tick、ロード完了と親車両の登録を再試行します。

単に車両へ座って紐付けただけでは WebMap キャッシュへ登録されません。

WebMap の `finish_SJAC` / `finish_SGAC` は生存チーム判定による勝利・引き分け時だけ送信します。時間切れ、Admin による中止、参加者 0 件による中断の経路では送信しません。

### 変更可能な設定

`?mm set [設定名] [値]` で変更します。boolean は小文字の `true` / `false` だけを受け付けます。表の既定値は新規データで使う値で、アドオンプロパティまたは保存済み `g_savedata` により異なる場合があります。

#### 車両・ダメージ

| 設定名 | 型・範囲 | 既定値 | 実際の効果 |
| --- | --- | ---: | --- |
| `vehicle_hp` | integer, 1以上 | 50 | 固定最大 HP。Adaptive HP 時は上限。 |
| `adaptive_hp` | boolean | `false` | ボクセル数連動 HP を有効化。 |
| `min_hp` | integer, 1以上 | 2000 | Adaptive HP の下限。 |
| `hp_per_voxel` | number, 0以上 | 3 | 1 ボクセルあたりの推定 HP。 |
| `hp_step` | integer, 0以上 | 500 | 推定 HP の切り捨て単位。0 なら切り捨てなし。 |
| `max_damage` | integer, 0以上 | 1000 | 1 tick に HP へ反映する最大ダメージ。 |
| `sunk_depth` | integer, 0以上 | 1 | Y `< -sunk_depth` を撃破扱い。0 で無効。 |
| `gc_vehicle` | boolean | `true` | 撃破車両グループを 60 tick 後に自動削除。 |
| `auto_link_on_spawn` | boolean | `true` | 自分がスポーンした親車両をロード後に自動登録。コードには旧キー `auto_sit_on_spawn` の移行分岐がありますが、現行順序では先に新キーが既定値補完されるため、通常は旧値で上書きされません。 |

#### 弾薬

| 設定名 | 型・範囲 | 既定値 | 実際の効果 |
| --- | --- | ---: | --- |
| `ammo_supply` | boolean | `true` | ボタンによる弾薬補給を有効化。 |
| `ammo_mg` | integer, -1以上 | -1 | Machine Gun の車両別補給回数。 |
| `ammo_la` | integer, -1以上 | -1 | Light Auto Cannon の車両別補給回数。 |
| `ammo_ra` | integer, -1以上 | -1 | Rotary Auto Cannon の車両別補給回数。 |
| `ammo_ha` | integer, -1以上 | -1 | Heavy Auto Cannon の車両別補給回数。 |
| `ammo_bs` | integer, -1以上 | -1 | Battle Cannon の車両別補給回数。 |
| `ammo_as` | integer, -1以上 | -1 | Artillery Cannon の車両別補給回数。 |

#### 試合・表示

| 設定名 | 型・範囲 | 既定値 | 実際の効果 |
| --- | --- | ---: | --- |
| `game_time` | number, 1以上 | 15 | 試合時間（分）。 |
| `order_enabled` | boolean | `true` | 非 Pause の試合中に `order` を許可。試合前と Pause 中は値に関係なく許可。 |
| `tps_enabled` | boolean | `true` | 試合中のキャラクター・車両三人称視点。 |
| `nameplate_enabled` | boolean | `true` | 試合中のネームプレート。残り 5 分で強制的に true。 |
| `player_damage` | boolean | `false` | 試合中のプレイヤーダメージ。 |
| `show_friends` | boolean | `true` | Matchmaker 独自の味方・終盤全車両マップ表示。 |
| `auto_standby` | boolean | `true` | 試合終了時に全保持プレイヤーを生存・Wait へ戻す。 |
| `auto_battle` | boolean | `false` | 通常終了後に 30 秒後シャッフル・基地割当、さらに 10 秒後テレポートを予約。 |
| `damage_popup` | boolean | `true` | ダメージ値・残 HP 率の車両ポップアップを有効化。味方名・距離表示自体は別処理。 |
| `min_damage_popup` | integer, 0以上 | 30 | ダメージを表示する最小蓄積値。 |
| `damage_popup_max_height` | integer, 0以上 | 15 | 遠距離時の車両ポップアップ高さ。 |
| `damage_popup_distance` | integer, 0以上 | 4500 | 車両ポップアップ表示距離。 |

#### 権限・モード

| 設定名 | 型・範囲 | 既定値 | 実際の効果 |
| --- | --- | ---: | --- |
| `auto_auth` | boolean | `true` | プレイヤー参加時に Auth を自動付与。 |
| `auto_admin` | boolean | `false` | SteamID64 `76561198925749199`、`76561198024666675`、`76561197994178477` に限り、参加時に Admin を自動付与。 |
| `game_mode_sjac` | boolean | `true` | SJAC 分岐なら true、SGAC 分岐なら false。`set` では関連プリセットを変更しない。 |
| `battle_mode` | integer, 0～1 | 0 | 0=通常、1=CENTER 縮小戦域。変更時に CENTER 旗を更新。 |

### 現行実装上の注意

- IFF 管理コマンドは全員実行可能です。
- `join` / `leave` は試合中も実行可能です。
- `clear_supply` は補給だけでなく旗も削除します。
- `delete_flag` / `clear_flag` は旗割り当て座標を消さないため、`tp` が旧座標を使う場合があります。
- `pause` は制限時間だけを止めます。ダメージ、車両 GC、UI、境界砲撃などは継続します。
- `show_friends` という名前ですが、未参加閲覧者と残り 5 分以下の参加者には敵も表示します。
- HP・弾薬設定の通常の `set` は登録済み車両へ遡及しません。
- `auto_battle` は次戦を自動開始せず、チーム分け・基地割当・テレポートまでです。
- `finishGame()` は毎回 `?cleanup`、`leave()` は `?iff_force_leave [peer_id]` をサーバーコマンドとして発行します。これらの受信側がない場合でも本スクリプトは呼び出しを行います。

### アドオン連携仕様

#### 必須アドオンコンポーネントタグ

| タグ | 用途 |
| --- | --- |
| `name=supply` | 補給オブジェクト |
| `name=flag` | 汎用旗 |
| `name=flag_red` | RED 旗 |
| `name=flag_blue` | BLUE 旗 |
| `name=flag_center` | CENTER 旗 |
| `name=iff_sender` | IFF 送信機 |
| `name=alt` | 地表高度チェッカー。`alt` 名のダイヤルが必要 |

#### プレイヤー車両インターフェース

- Keypad `mm_iff_freq`: RED / BLUE / PINK の自チーム IFF 周波数
- 弾薬補給: 「弾薬補給」節に記載したボタン名
- 任意ボタン `?mm ready` / `?mm die`: Ready / 死亡操作
- 車両登録には少なくとも 1 個の座席が必要

#### IFF 送信機インターフェース

- Keypad `mm_iff_freq_1`～`mm_iff_freq_3`: RED / BLUE / PINK 周波数
- 数値 Keypad `1`～`20`: RED の最大 10 台分
- 数値 Keypad `101`～`120`: BLUE の最大 10 台分
- 数値 Keypad `201`～`220`: PINK の最大 10 台分
- 1 台につき奇数側が X と Z 上位、偶数側が Z 下位・高度・名前トークンを含む独自 30 bit float エンコード

### 実装対応索引

README の各仕様は、主に次の [`script.lua`](./script.lua) の定義・関数へ対応します。仕様を変更するときは、該当コードと本文を同時に更新してください。

| README の対象 | `script.lua` の対応箇所 |
| --- | --- |
| コマンド名・権限・引数 | `g_commands`、`g_command_aliases`、`onCustomCommand`、`checkAuth`、`validateArgs` |
| 変更可能設定・既定値 | `g_settings`、`g_default_savedata`、`set` コマンド処理 |
| チーム参加・Ready・死亡・ログアウト | `join`、`leave`、`ready`、`wait`、`kill`、`logoutPlayer`、`resumeLoggedOutPlayer` |
| カウントダウン・開始・終了・勝敗 | `startCountdown`、`stopCountdown`、`startGame`、`finishGame`、`checkFinish` |
| 車両登録・HP・ダメージ・撃破 | `registerVehicle`、`getVehicleMaxHp`、`updateVehicle`、`onVehicleDamaged`、`unregisterVehicle` |
| UI・マップ・Ready 催促 | `updateTeamStatus`、`updatePlayerStatus`、`updatePlayerMapObject`、`updateReadyReminderPopups` |
| SJAC / SGAC | `setGameMode`、`enableSJAC`、`enableSGAC`、`setSettingsToBattle`、`setSettingsToStandby` |
| CENTER 縮小戦域 | `updateCenterFlag`、`getFlagMapRadius`、`updateCenterInfoPopups`、`updateBoundaryWarningPopups`、`updateCenterBoundaryExplosions` |
| 航空・地上基地と旗 | `airports`、`ground_base`、`assignAirbases`、`assignGroundBase`、`spawnFlagAtAdjustedAltitude`、`spawnFlagAt` |
| 補給・弾薬 | `g_ammo_supply_buttons`、`g_item_supply_buttons`、`onButtonPress`、`spawnSupply` |
| IFF | `g_iff_spawn_positions`、`generateIffFreqs`、`createIffSender`、`encodeCoords`、`buildNameTokens`、`onTick` 内 IFF 更新 |
| WebMap | `requestWebMapVehicleCache`、`requestWebMapVehicleRestore`、`handleWebMapCacheEvent`、`bindVehicleTeamToWebMap` |
| 自動バトル | `scheduleAutoBattle`、`processAutoBattle` |

### ライセンス

本リポジトリは [`LICENSE`](./LICENSE) のとおり、The Unlicense によりパブリックドメインへ提供されています。
