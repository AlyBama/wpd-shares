# طبيب معاينة واتساب v2

## التشغيل (Termux)
```bash
cd /storage/emulated/0/b/whatsapp-preview-doctor-v2
pip install pillow
bash run.sh      # يعمل على http://127.0.0.1:8081
bash stop.sh     # للإيقاف
```

## العنوان العام (مطلوب لواتساب)
واتساب لا يستطيع الوصول إلى localhost. اربط التطبيق بنفق HTTPS:

```bash
pkg install cloudflared   # أو: npm i -g cloudflared
cloudflared tunnel --url http://127.0.0.1:8081
```

انسخ عنوان `https://...` الناتج والصقه في حقل «العنوان العام» داخل التطبيق ثم احفظ.
بدون ذلك تعمل روابط المشاركة محليًا فقط ولن تظهر معاينتها في واتساب.

ملاحظة: قد تحتفظ واتساب بنسخة مخزنة مؤقتًا؛ المعاينة ليست فورية ولا مضمونة.

## النشر الدائم المجاني (الحل الجذري — بلا بطاقة بنكية)

نفق cloudflared المجاني **مؤقت**: عنوانه يتغير مع كل تشغيل، ويموت إن نام الهاتف —
وأي رابط وُلد بعنوان ميت يبقى ميتًا. الحل الدائم المجاني تمامًا:
**Render.com (خطة free، لا تطلب بطاقة) + تنبيه مجاني يمنع نوم الخادم.**

### الخطوة 1: رفع الكود إلى GitHub (مرة واحدة، من Termux)

```bash
pkg install -y git
cd /storage/emulated/0/b/whatsapp-preview-doctor-v2
git init -b main
git add Dockerfile requirements.txt .dockerignore render.yaml \
  server.py analyzer.py images.py config.py store.py static README.md
git commit -m "deploy"
```

- أنشئ حساب GitHub مجانيًا من المتصفح، ثم مستودعًا جديدًا فارغًا.
- اربط وادفع (سيطلب اسم المستخدم، وكلمة المرور = رمز PAT تنشئه من
  GitHub ← Settings ← Developer settings ← Personal access tokens):

```bash
git remote add origin https://github.com/<اسمك>/<المستودع>.git
git push -u origin main
```

### الخطوة 2: النشر على Render (مجاني، بلا بطاقة)

1. أنشئ حسابًا مجانيًا على `render.com` (بالإيميل فقط).
2. New ← Blueprint ← اختر المستودع ← Apply (اترك `PUBLIC_BASE_URL` فارغًا الآن).
3. انتظر حتى تصبح الحالة `Live` (أول نشر قد يستغرق ~10 دقائق).
4. انسخ رابط خدمتك `https://<اسم-خدمتك>.onrender.com` والصقه في لوحة Render
   ← Environment ← `PUBLIC_BASE_URL` ← Save (سيعيد النشر تلقائيًا).

### الخطوة 3: منع نوم الخادم (ضروري — مجاني أيضًا)

الخطة المجانية تُسبت الخادم بعد 15 دقيقة بلا زيارات، فيفشل جلب واتساب.
الحل: تنبيه مجاني يوقظه كل 5 دقائق:

1. أنشئ حسابًا مجانيًا على `uptimerobot.com` (بلا بطاقة).
2. Add New Monitor ← نوع `HTTP(s)` ← الرابط:
   `https://<اسم-خدمتك>.onrender.com/api/health`
   والفاصل `5 minutes` ← Create.

بعدها استخدم `https://<اسم-خدمتك>.onrender.com` مباشرة من أي متصفح —
وكل روابط المشاركة المولدة منه **دائمة** بلا هاتف ولا نفق.

### قيود الصدق في الخطة المجانية

- **لا قرص دائم**: إعادة النشر تمسح المعاينات القديمة — تجنّب إعادة النشر
  دون حاجة، وأعد توليد أي رابط مات بعدها.
- أول طلب بعد فترة صمت طويلة قد يتأخر ثوانٍ (إقلاع بارد) — المنبّه
  الدوري يجعل هذا نادرًا.
- 750 ساعة تشغيل شهريًا تكفي خدمة واحدة تعمل طوال الشهر.

متغيرات البيئة المدعومة: `PORT` / `WPD_PORT` للمنفذ (Render يحقن `PORT`
تلقائيًا والكود يحترمه)، `WPD_DATA_DIR` لمجلد البيانات،
`PUBLIC_BASE_URL` للعنوان العام.

## واجهات API
- `GET /api/health`
- `GET /api/config` / `POST /api/config`
- `POST /api/analyze {"url"}`
- `POST /api/upload` (ملف `image` حتى 8MB — بديل عند حجب الموقع)
- `POST /api/generate {"image_url"|"upload_id","page_url","title","description","mode"}`
- `GET /api/sharecheck/<token>` (فحص ما يراه الروبوت + كشف العنوان القديم)
- `GET /share/<token>` (صفحة OG + تحويل)
- `GET /preview/<token>.jpg` (الصورة 1200×630)
- `GET /robots.txt`

## الأمان
- يقبل http/https فقط، ويمنع SSRF (localhost والشبكات الداخلية) قبل كل طلب وبعد كل تحويل.
- مهلات وحدود حجم، والتحقق من الصور عبر Pillow.
- لا إعادة محاولة لـ 404/410، ومحاولة واحدة مبررة لـ 403 مع Referer.
