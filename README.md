poyon.js
========================================
はじめに
----------------------------------------
**poyon.js**はなんか*ふわふわ*してて，
スクロールすると*むにょん*として，
指で弾くと*ぽよん*とするような，
画像を円形に表示するためのライブラリです．


注意点
----------------------------------------
* canvasを用いているため，古いブラウザ(IE8以下など)では表示されません．
  別の方法を用いるか，諦めてください．

* 次のライブラリに依存していますので読み込んでください．
    + jquery.js
    + underscore.js

使い方
----------------------------------------

### html
必ず`data-image`属性に利用する画像を設定してください．
幅や高さはCSSで設定しても構いません．

```html
<script src="http://cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min.js"></script>
<script src="http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.5.2/underscore-min.js"></script>

<canvas class="poyon" data-image="target1.jpg" width="200" height="200"></canvas>
<canvas class="poyon" data-image="target2.jpg" width="200" height="200"></canvas>
<canvas class="poyon" data-image="target3.jpg" width="200" height="200"></canvas>
```

### javascript
`radius`のみ必須のオプションです．
他のオプションは後述します．
```javascript
$(function(){
  $(".poyon").poyon({
    radius: 70
    // other options
  });
});
```

オプション
----------------------------------------
|名前|必須|初期値|説明|
|:---|:--:|:--:|:---|
|radius|**必須**|--|円形図形の基本半径|
|warp|任意|true|時間経過で円が歪む|
|scroll|任意|true|スクロールに反応して円が歪む|
|flick|任意|true|マウス操作で円が歪む|
|vertexNumber|任意|8|円の頂点数|
|warpLevel|任意|0.5|warpの歪みの強さ|
|warpAngularVelocity|任意|0.05|warpの動きの速さ|
|spring|任意|0.015|元に戻ろうとする力の割合|
|friction|任意|0.93|摩擦力の割合|
|renderHiddenVisible|任意|true|画面範囲外の要素のレンダリングを行うか否か|

加速度を持った頂点
----------------------------------------
`scroll`や`flick`オプションを`true`にしている場合，頂点は加速度用いて計算します．

以下の計算を毎フレームにX軸とY軸に対して行います．
```
戻る力 = - 現在の位置 * spring
加速度 = (加速度 + 戻る力) * friction
現在の位置 += 加速度
```
オプションの`spring`と`friction`はここで用いられますのでご**注意**ください．
