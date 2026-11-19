# 星のキャラクターの絵（assets/characters/original/*.webp）から、アプリで使う背景の透明な PNG を作る。
# 背景（白に近い一色）を、外側からつながった部分だけ透明にする。目の白とハイライトは、外とつながっていないので残る。
# 足元の影（背景を暗くしただけの色）は、黒の半透明にする（暗い画面でも白く浮かない）。
# 使い方（app/ で。Pillow が要る）：python3 tool/character_cutout.py assets/characters/original/blue.webp assets/characters/blue.png
import sys
from collections import deque
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
LOW, HIGH = 14.0, 60.0  # 背景との色の差：LOW 未満は透明、HIGH 以上は不透明、その間はなめらかに
SHADOW = 130.0  # 色みのない（灰色の）影は、ここまで外からたどり、黒の半透明にする
im = Image.open(src).convert('RGB'); W, H = im.size; px = im.load()
cs = [px[0,0], px[W-1,0], px[0,H-1], px[W-1,H-1]]
bg = tuple(sum(c[i] for c in cs)/4 for i in range(3))
def d(c): return max(abs(c[i]-bg[i]) for i in range(3))
alpha = [[255]*W for _ in range(H)]
seen = bytearray(W*H); q = deque()
for x in range(W):
    q.append((x,0)); q.append((x,H-1))
for y in range(H):
    q.append((0,y)); q.append((W-1,y))
while q:
    x,y = q.popleft(); i = y*W+x
    if seen[i]: continue
    seen[i] = 1
    c = px[x,y]; dv = d(c)
    df = [bg[i]-c[i] for i in range(3)]
    grey = max(df) - min(df) < 16 and min(df) > -4  # 背景を暗くしただけの色（影）
    if dv >= (SHADOW if grey else HIGH): continue
    if dv < LOW: alpha[y][x] = 0
    elif grey: alpha[y][x] = -max(1, int(255*(1 - sum(c)/sum(bg))))  # 影（負の数で印を付ける）
    else: alpha[y][x] = int(255*(dv-LOW)/(HIGH-LOW))
    for nx,ny in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)):
        if 0<=nx<W and 0<=ny<H and not seen[ny*W+nx]: q.append((nx,ny))
out = Image.new('RGBA', (W,H)); op = out.load()
for y in range(H):
    for x in range(W):
        a = alpha[y][x]; c = px[x,y]
        if a == 0: op[x,y] = (0,0,0,0); continue
        if a < 0: op[x,y] = (0,0,0,min(255,-a)); continue
        if a < 255:  # 背景の色を混ぜ込んだ縁の色を戻す
            f = a/255
            c = tuple(max(0,min(255,int(round((c[i]-bg[i]*(1-f))/f)))) for i in range(3))
        op[x,y] = (*c, a)
box = out.getbbox(); m = 12
box = (max(0,box[0]-m), max(0,box[1]-m), min(W,box[2]+m), min(H,box[3]+m))
out = out.crop(box)
HEIGHT = 480  # アプリで使う大きさ（カードでは高さ 56 前後で出す。3倍の画面でも足りる）
out = out.resize((round(out.width * HEIGHT / out.height), HEIGHT), Image.LANCZOS)
out.save(dst, optimize=True)
print(dst, out.size)
