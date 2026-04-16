# Debug 筆記：手機 Hero 「兩段黃色」問題

## 症狀

手機版 hero section 看起來像被分成兩段：文字區塊在中間、上下各有一段金色背景露出，感覺 overlay 沒有罩滿整個 hero。

## 錯誤的假設（走了很多冤枉路）

依序試過這些假設，都不是真正原因：

1. **「Overlay 沒有罩滿 hero」** → 以為是 `.hero-overlay` 的 `position: absolute; inset: 0` 沒對齊 `.hero`。其實 overlay 跟 hero 都是 177×390，DevTools 的粉紅斜紋區是 overlay 的 padding，不是 overlay 外面。

2. **「`.hero::before` 的 linear-gradient 造成上暗中亮下暗的分段」** → 把 gradient 改成平的 `rgba(0,0,0,0.22)` 也沒解決。

3. **「Hero-media 的 16:9 aspect 太扁，內容太長」** → 縮小字體、縮小 padding 讓內容裝得下 16:9 也沒改善。

4. **「Grid 結構可以讓 overlay 撐開 hero」** → 改成 `display: grid` + `grid-area: 1/1` 後，`.hero` 跟 `.hero-overlay` 的確同高，但還是看到分段。

5. **「`align-self: stretch` 沒生效」** → 加了 `align-self: stretch; height: 100%; width: 100%` 都沒改變 overlay 的實際高度（因為本來就 stretch 了）。

6. **「h1 UA margin (0.67em) 沒被 reset」** → 其實 `h1 { margin-block-start: 0 }` 跟 `* { margin: 0 }` 都有正確覆蓋，不是問題。

## 關鍵轉折：停止猜，開始量

加了一段 debug script 把三個元素的**座標 + 尺寸 + transform 同時 log 出來**（原本只量尺寸看不出問題）：

```js
window.addEventListener('load', () => setTimeout(() => {
  const hero = document.querySelector('.hero');
  const overlay = document.querySelector('.hero-overlay');
  const media = document.querySelector('.hero-media');
  console.log('hero:   ', hero.getBoundingClientRect());
  console.log('overlay:', overlay.getBoundingClientRect());
  console.log('media:  ', media.getBoundingClientRect());
  console.log('overlay transform:', getComputedStyle(overlay).transform);
  console.log('media transform:', getComputedStyle(media).transform);
  console.log('is-visible:', overlay.classList.contains('is-visible'));
}, 1500));
```

**輸出揭露真相：**
```
hero:    (0,123) 390x177 → bottom:300
media:   (3,140) 384x174 → bottom:314
overlay: (0,138) 390x177 → bottom:315
overlay transform: matrix(1, 0, 0, 1, 0, 15.2)            ← translateY(15.2px)
media transform: matrix(0.985, 0, 0, 0.985, 0, 16)        ← scale(0.985) + translateY(16)
is-visible: true
```

三個元素**尺寸都一樣**（390×177），但：
- `.hero` 起點 y=123
- `.hero-overlay` 起點 y=138（**下移 15px**）
- `.hero-media` 起點 y=140（**下移 17px，還縮小 98.5%**）

都 `is-visible: true` 了，`transform` 還在，沒有被 reset 成 `none`。**上面那段 15px 的金色就是 overlay 被 transform 往下推留出的 hero 背景。**

## 根本原因：CSS specificity 平手 + source order

專案的 reveal 動畫有三條相關規則：

```css
/* line 386：所有 [data-reveal] 的初始狀態 */
.motion-ready [data-reveal] {             /* specificity 0,2,0 */
  opacity: 0;
  transform: translateY(1.25rem);
  filter: blur(0.38rem);
}

/* line 396：變成可見時 reset */
.motion-ready [data-reveal].is-visible {  /* specificity 0,3,0 */
  opacity: 1;
  filter: blur(0);
  transform: none;
}

/* line 401：hero-overlay 特製初始 transform */
.motion-ready .hero-overlay[data-reveal] {  /* specificity 0,3,0 ← 一樣！*/
  transform: translateY(0.95rem);
}

/* line 404：hero-media 特製初始 transform */
.motion-ready .hero-media[data-reveal] {    /* specificity 0,3,0 ← 一樣！*/
  transform: translateY(1rem) scale(0.985);
}
```

- `.motion-ready [data-reveal].is-visible`（line 396）specificity = 0,3,0
- `.motion-ready .hero-overlay[data-reveal]`（line 401）specificity = 0,3,0

**兩者 specificity 一樣**（都是 3 個 class-level selector），**source order 後者贏**，所以 hero-overlay 永遠保留 `translateY(0.95rem)` 不管有沒有 `is-visible` class。

其他 reveal 元素（如 `.intro-hero-copy`）沒這個 bug，因為它們 is-visible reset 規則涵蓋得到。

## 修法

加特定 is-visible override 把 specificity 提高：

```css
.motion-ready .hero-overlay[data-reveal].is-visible {  /* specificity 0,4,0 */
  transform: none;
}
.motion-ready .hero-media[data-reveal].is-visible {
  transform: none;
}
```

Specificity 0,4,0 > 0,3,0，而且順序上也在後面，兩重保險。

## 帶走的教訓

1. **「Overlay 沒罩滿」的視覺感受 ≠ overlay size 錯。** 大小可能正確但被 transform 偏移了。量尺寸之外還要量座標。

2. **`getBoundingClientRect()` 會把 transform 算進去**，但 `offsetHeight` 不會。兩個一起看可以判斷是 transform 錯位還是 size 錯位：
   - rect.height ≠ offsetHeight → 有 scale
   - rect.top ≠ 正常起點 → 有 translate

3. **CSS specificity 平手時不要依賴 source order**。如果兩條規則想覆蓋彼此，最好讓「後寫的」specificity 真的比較高，不要靠順序。最安全：加上額外 class 或 attribute selector 提高精確度。

4. **Debug CSS layout 的通用流程：**
   - 加一塊 `<pre>` debug overlay 把尺寸、座標、transform、computed styles 全 log 出來
   - 放在 `setTimeout` 裡等動畫跑完再量（避免抓到中間態）
   - 量完直接 console.log 或貼到畫面上，不用一直開 DevTools 切 tab

5. **IntersectionObserver + transform 動畫要小心 specificity cascade**。「通用 reset」規則如果 specificity 低於「特定初始狀態」規則，reset 永遠不會真的生效。

## 相關 commit

- 修正：`.motion-ready .hero-overlay[data-reveal].is-visible { transform: none }`（以及 hero-media 同理）
- 順便 refactor：`.hero` 從 absolute/inset 疊加改成 `display: grid` + `grid-area: 1/1`，overlay 跟 media 自然疊合，更乾淨
- 手機版加 `min-height: 25vh`，避免內容很少時 hero 太扁
