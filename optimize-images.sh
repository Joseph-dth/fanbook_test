#!/bin/bash
set -e

cd "$(dirname "$0")/src/images"

echo "=== A. Hero 照片 (21MB → ~250KB) ==="
cwebp -q 80 -resize 1200 0 "Hero/樊登高清.jpg" -o "Hero/樊登高清.webp"
echo "Done: Hero/樊登高清.webp"

echo ""
echo "=== B. 假 SVG → WebP ==="

# Hero portrait SVG (render at 500px wide)
rsvg-convert -w 500 "Hero/樊登.svg" -o /tmp/fansvg_temp.png
cwebp -q 85 /tmp/fansvg_temp.png -o "Hero/樊登.webp"
rm /tmp/fansvg_temp.png
echo "Done: Hero/樊登.webp"

# Category icons (render at 180px)
for svg in "三大工具" "重塑觀念" "閱讀素養" "心靈成長" "職場商業" "人文經典" "親子家庭"; do
  rsvg-convert -w 180 "${svg}.svg" -o /tmp/icon_temp.png
  cwebp -q 85 /tmp/icon_temp.png -o "${svg}.webp"
  rm /tmp/icon_temp.png
  echo "Done: ${svg}.webp"
done

# Comparison badge (render at 300px)
rsvg-convert -w 300 "樊登說書讚.svg" -o /tmp/badge_temp.png
cwebp -q 85 /tmp/badge_temp.png -o "樊登說書讚.webp"
rm /tmp/badge_temp.png
echo "Done: 樊登說書讚.webp"

echo ""
echo "=== C. App 截圖 (10MB → ~400KB) ==="
for f in app_screen/帆書APP-screen-0{1,2,3,4}.png; do
  base=$(basename "$f" .png)
  cwebp -q 82 -resize 800 0 "$f" -o "app_screen/${base}.webp"
  echo "Done: app_screen/${base}.webp"
done

echo ""
echo "=== D. Event 圖 ==="
cwebp -q 80 "event.png" -o "event.webp"
echo "Done: event.webp"

echo ""
echo "=== E. 書封面 ==="
for dir in "個人成長" "職場商業" "親子家庭" "人文歷史"; do
  for f in "${dir}"/*.jpg "${dir}"/*.png; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    name="${base%.*}"
    cwebp -q 80 "$f" -o "${dir}/${name}.webp"
    echo "Done: ${dir}/${name}.webp"
  done
done

echo ""
echo "=== 完成！比較大小 ==="
echo "原始總大小:"
du -sh .
echo ""
echo "WebP 檔案大小:"
find . -name "*.webp" -exec ls -lh {} \; | awk '{print $5, $NF}'
