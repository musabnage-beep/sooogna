/**
 * Seed 100 realistic ads into Firestore for Souq Sudan.
 *
 * Usage:
 *   cd scripts && npm install && node seed_ads.mjs
 *
 * Real product images via loremflickr (keyword-matched, deterministic lock seed).
 * Uses Google Cloud Firestore client with ADC from Firebase CLI login.
 */

import { readFileSync } from 'fs';
import { homedir } from 'os';
import { Firestore, Timestamp } from '@google-cloud/firestore';
import { OAuth2Client } from 'google-auth-library';

// ── Auth: reuse Firebase CLI refresh token ──
const PROJECT_ID = 'souq-sudan-prod';
const configPath = `${homedir()}/.config/configstore/firebase-tools.json`;
const config = JSON.parse(readFileSync(configPath, 'utf8'));

const oauth2Client = new OAuth2Client(
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
  'j9iVZfS8kkCEFUPaAeJV0sAi',
);
oauth2Client.setCredentials({ refresh_token: config.tokens.refresh_token });

const db = new Firestore({ projectId: PROJECT_ID, authClient: oauth2Client });

// ── Data pools ──
const cities = [
  'الخرطوم', 'أم درمان', 'بحري', 'مدني', 'بورتسودان',
  'كسلا', 'الأبيض', 'نيالا', 'عطبرة', 'الفاشر',
  'دنقلا', 'القضارف', 'سنار', 'كوستي', 'الدمازين',
];

const states = [
  'ولاية الخرطوم', 'ولاية الجزيرة', 'ولاية كسلا', 'ولاية البحر الأحمر',
  'ولاية شمال كردفان', 'ولاية جنوب دارفور', 'ولاية نهر النيل',
  'ولاية شمال دارفور', 'ولاية القضارف', 'ولاية سنار',
];

function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function randInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function randPrice(min, max, step = 500000) {
  return Math.round((Math.random() * (max - min) + min) / step) * step;
}

// Real photo, keyword-matched, deterministic per lock seed.
function imageUrl(tags, lock) {
  return `https://loremflickr.com/640/480/${tags}?lock=${lock}`;
}

// ── 100 ad templates (with image keywords) ──
const adTemplates = [
  // ─── CARS (25) ───
  { cat: 'cars', img: 'toyota,corolla,car', title: 'تويوتا كورولا 2020', desc: 'سيارة نظيفة جداً، صيانة منتظمة في الوكالة، لا تحتاج إلى أي مصروف. جاهزة للبيع فوراً.', price: 18500000 },
  { cat: 'cars', img: 'hyundai,tucson,suv', title: 'هيونداي توسان 2019', desc: 'محرك 1600 تيربو، فتحة سقف، كاميرا خلفية، حساسات أمامية وخلفية. حالة ممتازة.', price: 23000000 },
  { cat: 'cars', img: 'kia,sportage,suv', title: 'كيا سبورتاج 2021', desc: 'موديل جديد، قطعت مسافة قليلة، فل كامل مع شاشة تاتش وبلوتوث.', price: 28500000 },
  { cat: 'cars', img: 'nissan,sedan,car', title: 'نيسان صني 2018', desc: 'سيارة اقتصادية ممتازة، استهلاك وقود منخفض، مناسبة للعائلة.', price: 9500000 },
  { cat: 'cars', img: 'toyota,hilux,pickup', title: 'تويوتا هايلكس 2022 دبل كابينة', desc: 'ديزل 2.4 لتر، دفع رباعي، مستخدمة استخدام خفيف، اللون أبيض.', price: 52000000 },
  { cat: 'cars', img: 'mercedes,car,luxury', title: 'مرسيدس C200 2017', desc: 'فل أوبشن، جلد، فتحة، نافيجيشن، صيانة وكالة كاملة.', price: 41000000 },
  { cat: 'cars', img: 'honda,civic,car', title: 'هوندا سيفيك 2020', desc: 'سبورت، محرك 1.5 تيربو، شاشة كبيرة، كاميرا 360 درجة.', price: 26000000 },
  { cat: 'cars', img: 'suzuki,swift,car', title: 'سوزوكي سويفت 2019', desc: 'سيارة صغيرة عملية، مثالية للتنقل داخل المدينة، حالة ممتازة.', price: 8500000 },
  { cat: 'cars', img: 'toyota,landcruiser,suv', title: 'تويوتا لاندكروزر 2018', desc: 'GXR V8، دفع رباعي، مجهزة بالكامل، مناسبة للطرق الوعرة.', price: 95000000 },
  { cat: 'cars', img: 'chevrolet,car', title: 'شيفروليه كروز 2017', desc: 'أوتوماتيك، تكييف ممتاز، السيارة خالية من الحوادث.', price: 11000000 },
  { cat: 'cars', img: 'ford,ranger,pickup', title: 'فورد رينجر 2021', desc: 'بيك أب قوي، ديزل، مناسب للعمل والرحلات، حالة وكالة.', price: 47000000 },
  { cat: 'cars', img: 'toyota,camry,sedan', title: 'تويوتا كامري 2019', desc: 'فل كامل، محرك V6، جلد بيج، السيارة نظيفة من الداخل والخارج.', price: 24000000 },
  { cat: 'cars', img: 'hyundai,accent,car', title: 'هيونداي أكسنت 2020', desc: 'موديل جديد، قير أوتوماتيك، شاشة تاتش، بلوتوث ويو اس بي.', price: 13000000 },
  { cat: 'cars', img: 'bmw,car,luxury', title: 'بي ام دبليو 320i 2018', desc: 'سبورت لاين، محرك تيربو، داخلية جلد أسود، حالة نادرة.', price: 38000000 },
  { cat: 'cars', img: 'mitsubishi,lancer,car', title: 'ميتسوبيشي لانسر 2016', desc: 'سيارة عملية واقتصادية، صيانة منتظمة، مكيف ممتاز.', price: 7500000 },
  { cat: 'cars', img: 'toyota,fortuner,suv', title: 'تويوتا فورتشنر 2020', desc: 'ديزل، 7 مقاعد، دفع رباعي، مثالية للعائلة والرحلات.', price: 58000000 },
  { cat: 'cars', img: 'kia,rio,car', title: 'كيا ريو 2021', desc: 'هاتشباك، لون رمادي، قطعت 15 ألف كيلو فقط، ضمان ساري.', price: 15000000 },
  { cat: 'cars', img: 'nissan,patrol,suv', title: 'نيسان باترول 2019', desc: 'V6 تيربو، فل أوبشن، شاشتين خلفية، جلد ملون، حالة فخمة.', price: 105000000 },
  { cat: 'cars', img: 'toyota,yaris,car', title: 'تويوتا يارس 2020', desc: 'سيارة صغيرة اقتصادية، مناسبة للشباب والطلاب.', price: 10500000 },
  { cat: 'cars', img: 'hyundai,creta,suv', title: 'هيونداي كريتا 2021', desc: 'SUV مدمجة، تصميم عصري، شاشة كبيرة، كاميرا خلفية.', price: 24000000 },
  { cat: 'cars', img: 'mazda,suv,car', title: 'مازدا CX-5 2019', desc: 'تصميم أنيق، محرك سكاي أكتيف، استهلاك اقتصادي.', price: 30000000 },
  { cat: 'cars', img: 'volkswagen,golf,car', title: 'فولكسفاجن جولف 2018', desc: 'GTI، محرك تيربو رياضي، مقاعد رياضية، حالة ممتازة.', price: 21000000 },
  { cat: 'cars', img: 'renault,duster,suv', title: 'رينو داستر 2020', desc: 'دفع رباعي، مناسبة للطرق المتنوعة، سعر مناسب.', price: 15000000 },
  { cat: 'cars', img: 'peugeot,sedan,car', title: 'بيجو 301 2019', desc: 'سيدان عملية، محرك اقتصادي، تكييف قوي، حالة جيدة جداً.', price: 9000000 },
  { cat: 'cars', img: 'suv,car,silver', title: 'شيري تيجو 8 2021', desc: 'SUV صينية فاخرة، 7 مقاعد، شاشة بانوراما، سعر منافس.', price: 26000000 },

  // ─── REAL ESTATE (20) ───
  { cat: 'real_estate', img: 'apartment,interior,modern', title: 'شقة فاخرة للبيع - الرياض', desc: '3 غرف نوم + صالة كبيرة + مطبخ أمريكي + 2 حمام. الطابق الرابع مع مصعد. تشطيب سوبر لوكس.', price: 60000000 },
  { cat: 'real_estate', img: 'land,plot,field', title: 'أرض سكنية في الخرطوم 2', desc: 'مساحة 400 متر مربع، مسورة ومردومة، واجهة عريضة، شارعين.', price: 75000000 },
  { cat: 'real_estate', img: 'villa,house,luxury', title: 'فيلا للبيع - المنشية', desc: 'فيلا دوبلكس، 5 غرف، حديقة واسعة، جراج لسيارتين، تشطيب فاخر.', price: 200000000 },
  { cat: 'real_estate', img: 'apartment,room,bedroom', title: 'شقة للإيجار - بحري', desc: 'غرفتين نوم + صالة، مكيفة بالكامل، قريبة من الخدمات.', price: 1000000 },
  { cat: 'real_estate', img: 'shop,storefront,commercial', title: 'محل تجاري للبيع - سوق أم درمان', desc: 'موقع ممتاز في قلب السوق، مساحة 50 متر، مناسب لأي نشاط تجاري.', price: 45000000 },
  { cat: 'real_estate', img: 'house,home,exterior', title: 'منزل عربي للبيع - الثورة', desc: '4 غرف، حوش واسع، مطبخ خارجي، مساحة 500 متر.', price: 80000000 },
  { cat: 'real_estate', img: 'apartment,furnished,livingroom', title: 'شقة مفروشة للإيجار اليومي', desc: 'شقة فندقية مفروشة بالكامل، واي فاي، تكييف، موقع مميز.', price: 100000 },
  { cat: 'real_estate', img: 'land,commercial,plot', title: 'أرض تجارية على شارع رئيسي', desc: 'مساحة 800 متر، واجهة 30 متر على الشارع العام، مناسبة لمشروع تجاري.', price: 300000000 },
  { cat: 'real_estate', img: 'house,home,building', title: 'بيت للبيع - جبرة', desc: '3 غرف + صالون + مطبخ، مسور، بوابة حديد، كهرباء ومياه.', price: 55000000 },
  { cat: 'real_estate', img: 'office,workspace,interior', title: 'مكتب للإيجار - برج الفاتح', desc: 'مكتب 80 متر، تكييف مركزي، مصعد، حارس، موقف سيارات.', price: 3500000 },
  { cat: 'real_estate', img: 'apartment,garden,house', title: 'شقة طابق أرضي مع حديقة', desc: '3 غرف نوم، حديقة خاصة 100 متر، مدخل مستقل.', price: 60000000 },
  { cat: 'real_estate', img: 'land,plot,empty', title: 'قطعة أرض في أركويت', desc: 'مساحة 300 متر، منطقة سكنية هادئة، قريبة من المدارس.', price: 110000000 },
  { cat: 'real_estate', img: 'building,apartment,block', title: 'عمارة استثمارية - كافوري', desc: '8 شقق مؤجرة، دخل شهري ممتاز، بناء حديث.', price: 400000000 },
  { cat: 'real_estate', img: 'villa,pool,resort', title: 'استراحة للبيع - شرق النيل', desc: 'استراحة بمسبح وحديقة، 3 غرف، صالة كبيرة، مثالية للعطلات.', price: 100000000 },
  { cat: 'real_estate', img: 'penthouse,apartment,view', title: 'شقة بنتهاوس - المقرن', desc: 'إطلالة بانورامية على النيل، 4 غرف، تراس واسع، تشطيب فخم.', price: 160000000 },
  { cat: 'real_estate', img: 'office,coworking,desk', title: 'غرفة مكتبية مشتركة', desc: 'مساحة عمل مشتركة مع إنترنت سريع ومكيف، مناسبة للفريلانسرز.', price: 350000 },
  { cat: 'real_estate', img: 'house,home,simple', title: 'بيت شعبي للبيع - الحاج يوسف', desc: 'غرفتين وصالة، مسور، قريب من الشارع العام.', price: 32000000 },
  { cat: 'real_estate', img: 'farm,agriculture,field', title: 'مزرعة 10 فدان - النيل الأبيض', desc: 'مزرعة مروية، بها أشجار مثمرة ومنزل للمزارع.', price: 70000000 },
  { cat: 'real_estate', img: 'shop,store,retail', title: 'دكان في مجمع تجاري', desc: 'مساحة 25 متر، واجهة زجاج، تكييف، مناسب للملابس أو الإلكترونيات.', price: 22000000 },
  { cat: 'real_estate', img: 'apartment,new,building', title: 'شقة تمليك جديدة - الأمارات', desc: 'تسليم فوري، 2 غرف نوم، مصعد، حارس 24 ساعة.', price: 45000000 },

  // ─── MOBILES (15) ───
  { cat: 'mobiles', img: 'iphone,smartphone', title: 'iPhone 14 Pro Max 256GB', desc: 'لون أسود، حالة ممتازة، بطارية 95%، مع جميع الملحقات والكرتونة.', price: 6200000 },
  { cat: 'mobiles', img: 'samsung,galaxy,smartphone', title: 'Samsung Galaxy S23 Ultra', desc: 'قلم S-Pen، كاميرا 200 ميجابكسل، ذاكرة 256GB، حالة جديدة.', price: 7000000 },
  { cat: 'mobiles', img: 'iphone,phone,blue', title: 'iPhone 13 128GB', desc: 'مستخدم شهرين فقط، بطارية 100%، لون أزرق، ضمان ساري.', price: 4500000 },
  { cat: 'mobiles', img: 'samsung,smartphone,android', title: 'Samsung Galaxy A54', desc: 'شاشة AMOLED، كاميرا ثلاثية، بطارية 5000 مللي أمبير.', price: 2500000 },
  { cat: 'mobiles', img: 'smartphone,xiaomi,phone', title: 'Xiaomi 13T Pro', desc: 'معالج MediaTek Dimensity 9200+، شحن سريع 120 واط.', price: 3200000 },
  { cat: 'mobiles', img: 'iphone,smartphone,titanium', title: 'iPhone 15 Pro 256GB', desc: 'تيتانيوم أزرق، Action Button، USB-C، كاميرا 48 ميجا.', price: 8500000 },
  { cat: 'mobiles', img: 'foldable,smartphone,samsung', title: 'Samsung Galaxy Z Fold 5', desc: 'شاشة قابلة للطي، 256GB، حالة ممتازة مع الغطاء الأصلي.', price: 10000000 },
  { cat: 'mobiles', img: 'smartphone,oppo,phone', title: 'Oppo Reno 10 Pro', desc: 'كاميرا تليفوتو، شاشة منحنية، شحن سريع 80 واط.', price: 2800000 },
  { cat: 'mobiles', img: 'smartphone,pixel,google', title: 'Google Pixel 8 Pro', desc: 'أفضل كاميرا هاتف، معالج Tensor G3، أندرويد نقي.', price: 6000000 },
  { cat: 'mobiles', img: 'smartphone,huawei,phone', title: 'Huawei P60 Pro', desc: 'كاميرا Leica، تصميم فاخر، بطارية كبيرة، حالة جديدة.', price: 5000000 },
  { cat: 'mobiles', img: 'smartphone,phone,mobile', title: 'Realme GT 3', desc: 'شحن 240 واط، الأسرع في العالم، شاشة 144Hz.', price: 3000000 },
  { cat: 'mobiles', img: 'iphone,apple,phone', title: 'iPhone SE 2022 64GB', desc: 'هاتف أبل الاقتصادي، معالج A15 Bionic، مثالي للاستخدام اليومي.', price: 2500000 },
  { cat: 'mobiles', img: 'samsung,phone,smartphone', title: 'Samsung Galaxy S22 128GB', desc: 'مستخدم بحالة نظيفة، شاشة Dynamic AMOLED، كاميرا ثلاثية.', price: 4000000 },
  { cat: 'mobiles', img: 'nokia,phone,smartphone', title: 'Nokia G60 5G', desc: 'هاتف متين، بطارية تدوم يومين، دعم 5G، سعر مناسب.', price: 1400000 },
  { cat: 'mobiles', img: 'oneplus,smartphone,phone', title: 'OnePlus 11 256GB', desc: 'Snapdragon 8 Gen 2، شحن 100 واط، شاشة 120Hz.', price: 4200000 },

  // ─── ELECTRONICS (10) ───
  { cat: 'electronics', img: 'laptop,dell,computer', title: 'لابتوب Dell XPS 15', desc: 'معالج i7 الجيل 12، رام 16GB، SSD 512GB، شاشة 4K OLED.', price: 10000000 },
  { cat: 'electronics', img: 'television,tv,smarttv', title: 'شاشة تلفزيون Samsung 55 بوصة', desc: 'Smart TV، 4K Crystal UHD، واي فاي مدمج، نظام Tizen.', price: 4000000 },
  { cat: 'electronics', img: 'playstation,console,gaming', title: 'PlayStation 5 + يدين تحكم', desc: 'مع 3 ألعاب أصلية، حالة ممتازة، كرتونة كاملة.', price: 5000000 },
  { cat: 'electronics', img: 'macbook,laptop,apple', title: 'MacBook Air M2 2022', desc: 'لون Midnight، رام 8GB، SSD 256GB، بطارية ممتازة.', price: 8500000 },
  { cat: 'electronics', img: 'camera,canon,dslr', title: 'كاميرا Canon EOS R6', desc: 'ميرورليس فل فريم، 20 ميجابكسل، تصوير فيديو 4K60.', price: 12500000 },
  { cat: 'electronics', img: 'airpods,earbuds,apple', title: 'سماعات AirPods Pro 2', desc: 'إلغاء ضوضاء فعال، USB-C، بطارية ممتازة، حالة جديدة.', price: 2000000 },
  { cat: 'electronics', img: 'ipad,tablet,apple', title: 'iPad Pro 12.9 M2', desc: 'شاشة Liquid Retina XDR، قلم Apple Pencil 2، 256GB.', price: 7500000 },
  { cat: 'electronics', img: 'printer,office,hp', title: 'طابعة HP LaserJet Pro', desc: 'طباعة ليزر ملونة، واي فاي، سرعة 28 صفحة/دقيقة.', price: 2200000 },
  { cat: 'electronics', img: 'router,wifi,network', title: 'راوتر هواوي 5G CPE Pro', desc: 'راوتر 5G منزلي، سرعات فائقة، يدعم 64 جهاز متصل.', price: 1500000 },
  { cat: 'electronics', img: 'monitor,screen,computer', title: 'شاشة كمبيوتر LG UltraWide 34', desc: 'شاشة منحنية، دقة WQHD، مثالية للعمل والألعاب.', price: 4000000 },

  // ─── FURNITURE (10) ───
  { cat: 'furniture', img: 'sofa,couch,livingroom', title: 'طقم كنب مودرن 7 مقاعد', desc: 'قماش تركي مقاوم للبقع، ألوان متعددة متاحة، ضمان سنتين.', price: 4500000 },
  { cat: 'furniture', img: 'bedroom,bed,furniture', title: 'غرفة نوم كاملة - خشب زان', desc: 'سرير + دولاب 6 أبواب + تسريحة + كومودينو عدد 2.', price: 7500000 },
  { cat: 'furniture', img: 'diningtable,table,chairs', title: 'طاولة طعام 8 أشخاص', desc: 'خشب طبيعي مع 8 كراسي مبطنة، تصميم كلاسيكي أنيق.', price: 3000000 },
  { cat: 'furniture', img: 'desk,office,wood', title: 'مكتب خشبي مع أدراج', desc: 'مكتب عمل مريح، 3 أدراج جانبية، سطح واسع 140 سم.', price: 1100000 },
  { cat: 'furniture', img: 'bunkbed,kids,bedroom', title: 'سرير أطفال طابقين', desc: 'خشب صلب مع سلم آمن ودرابزين، مناسب لغرف الأطفال الصغيرة.', price: 1500000 },
  { cat: 'furniture', img: 'wardrobe,closet,furniture', title: 'خزانة ملابس 4 أبواب', desc: 'مرايا داخلية، رفوف قابلة للتعديل، أدراج سفلية.', price: 2200000 },
  { cat: 'furniture', img: 'officechair,chair,leather', title: 'كرسي مكتب دوار جلد', desc: 'ارتفاع قابل للتعديل، مسند ظهر مريح، عجلات مطاطية.', price: 550000 },
  { cat: 'furniture', img: 'kitchen,cabinet,interior', title: 'مطبخ ألومنيوم جاهز', desc: 'مطبخ كامل 3 أمتار مع حوض ستانلس وخلاطة.', price: 3000000 },
  { cat: 'furniture', img: 'bathroom,sink,interior', title: 'طقم حمام فاخر', desc: 'مغسلة + مرحاض + حوض استحمام + خلاطات، ماركة إيطالية.', price: 2500000 },
  { cat: 'furniture', img: 'curtains,window,interior', title: 'ستائر بلاك آوت مع تركيب', desc: 'ستائر معتمة للنوم، ألوان متعددة، تركيب مجاني داخل الخرطوم.', price: 350000 },

  // ─── SERVICES (5) ───
  { cat: 'services', img: 'airconditioner,technician,repair', title: 'فني تكييف وتبريد', desc: 'صيانة وتركيب جميع أنواع المكيفات، سبليت ومركزي، خبرة 10 سنوات.', price: 100000 },
  { cat: 'services', img: 'graphicdesign,designer,laptop', title: 'مصمم جرافيك محترف', desc: 'تصميم شعارات، هوية بصرية، بوستات سوشيال ميديا، أسعار مناسبة.', price: 300000 },
  { cat: 'services', img: 'construction,builder,worker', title: 'معلم بناء وتشطيبات', desc: 'بناء وتشطيب منازل، دهانات، سيراميك، جبس بورد.', price: 200000 },
  { cat: 'services', img: 'driver,car,chauffeur', title: 'سائق خاص بسيارة', desc: 'سيارة حديثة مكيفة، خدمة توصيل داخل الخرطوم، أسعار معقولة.', price: 70000 },
  { cat: 'services', img: 'teacher,study,mathematics', title: 'مدرس خصوصي رياضيات', desc: 'خبرة 15 سنة في تدريس الرياضيات، جميع المراحل، نتائج مضمونة.', price: 100000 },

  // ─── FASHION (5) ───
  { cat: 'fashion', img: 'kandura,thobe,traditional', title: 'جلابية سودانية فاخرة', desc: 'قماش تترون سويسري، تطريز يدوي راقي، متوفرة بعدة ألوان.', price: 300000 },
  { cat: 'fashion', img: 'dress,fabric,traditional', title: 'ثوب سوداني أصلي', desc: 'ثوب شفاف فاخر، ألوان مميزة، مناسب للمناسبات والأفراح.', price: 500000 },
  { cat: 'fashion', img: 'handbag,leather,bag', title: 'حقيبة يد جلد طبيعي', desc: 'صناعة يدوية، جلد بقري أصلي، تصميم عصري أنيق.', price: 300000 },
  { cat: 'fashion', img: 'watch,wristwatch,casio', title: 'ساعة يد كاسيو أصلية', desc: 'ساعة كاسيو كلاسيكية، مقاومة للماء، ضمان سنة.', price: 200000 },
  { cat: 'fashion', img: 'sunglasses,rayban,eyewear', title: 'نظارة شمسية Ray-Ban', desc: 'أصلية مع الكرتونة والشهادة، عدسات بولارايزد.', price: 350000 },

  // ─── ANIMALS (5) ───
  { cat: 'animals', img: 'persiancat,cat,kitten', title: 'قطة شيرازية بيور', desc: 'أنثى عمر 4 أشهر، محصنة، لون أبيض مع عيون زرقاء.', price: 500000 },
  { cat: 'animals', img: 'germanshepherd,dog,puppy', title: 'كلب جيرمن شيبرد', desc: 'ذكر عمر 6 أشهر، أصل ألماني، محصن ومطعّم بالكامل.', price: 1000000 },
  { cat: 'animals', img: 'parrot,bird,grey', title: 'ببغاء أفريقي رمادي', desc: 'يتكلم كلمات عربية، عمر سنتين، مع القفص والطعام.', price: 2000000 },
  { cat: 'animals', img: 'sheep,livestock,ram', title: 'خروف بلدي سمين', desc: 'خروف بلدي جاهز للذبح، وزن تقريبي 45 كيلو.', price: 350000 },
  { cat: 'animals', img: 'aquarium,fish,tank', title: 'أسماك زينة مع حوض', desc: 'حوض 60 سم مع فلتر وإضاءة LED و 10 أسماك ملونة.', price: 200000 },

  // ─── FOOD (5) ───
  { cat: 'food', img: 'honey,jar,natural', title: 'عسل سدر طبيعي - كيلو', desc: 'عسل سدر بلدي 100% طبيعي، من مناطق كردفان، بدون إضافات.', price: 100000 },
  { cat: 'food', img: 'dates,fruit,arabic', title: 'تمر سوداني فاخر - 5 كيلو', desc: 'تمر مشكل (قنديلة + مدينة)، تعبئة فاخرة، مناسب للهدايا.', price: 55000 },
  { cat: 'food', img: 'spices,seasoning,market', title: 'بهارات سودانية مشكلة', desc: 'خلطة شطة + كمون + كزبرة + قرنفل، مطحونة طازجة.', price: 20000 },
  { cat: 'food', img: 'beans,canned,food', title: 'فول مصري معلّب - كرتون 24', desc: 'فول حب كامل، جاهز للأكل، إنتاج حديث.', price: 45000 },
  { cat: 'food', img: 'flatbread,bread,food', title: 'كسرة سودانية جاهزة - 10 قطع', desc: 'كسرة ذرة طازجة، محضرة يومياً، توصيل داخل الخرطوم.', price: 10000 },
];

// ── Demo seller ──
const demoUserId = 'demo_seller_001';

async function ensureDemoUser() {
  const ref = db.collection('users').doc(demoUserId);
  await ref.set({
    name: 'أحمد محمد',
    phone: '+249912345678',
    profileImage: 'https://i.pravatar.cc/200?img=12',
    isVerified: true,
    verifiedStatus: 'verified',
    rating: 4.5,
    ratingCount: 24,
    profileVisits: 156,
    role: 'user',
    isBanned: false,
    createdAt: Timestamp.now(),
    lastActiveAt: Timestamp.now(),
  }, { merge: true });
  console.log('Demo user created/updated');
}

async function seedAds() {
  console.log(`Seeding ${adTemplates.length} ads...`);
  const batch = db.batch();
  const now = Date.now();

  for (let i = 0; i < adTemplates.length; i++) {
    const t = adTemplates[i];
    const city = pick(cities);
    const state = pick(states);
    const price = t.price;
    const imgCount = randInt(1, 3);
    const images = [];
    for (let j = 0; j < imgCount; j++) {
      images.push(imageUrl(t.img, i * 10 + j));
    }

    const createdMs = now - randInt(0, 30 * 24 * 60 * 60 * 1000);
    const createdAt = Timestamp.fromMillis(createdMs);

    const ref = db.collection('ads').doc();
    const keywords = (t.title + ' ' + t.desc)
      .replace(/[^\u0600-\u06FF\u0750-\u077F\sa-zA-Z0-9]/g, ' ')
      .split(/\s+/)
      .filter(w => w.length > 1)
      .map(w => w.toLowerCase());
    const uniqueKeywords = [...new Set(keywords)].slice(0, 30);

    batch.set(ref, {
      title: t.title,
      description: t.desc,
      price,
      category: t.cat,
      images,
      location: `${city}، ${state}`,
      city,
      ownerType: pick(['owner', 'owner', 'owner', 'broker', 'company']),
      userId: demoUserId,
      userName: 'أحمد محمد',
      userPhone: '+249912345678',
      status: 'active',
      isFeatured: i < 5,
      viewCount: randInt(10, 500),
      favoriteCount: randInt(0, 50),
      contactCount: randInt(0, 30),
      searchKeywords: uniqueKeywords,
      storeId: null,
      createdAt,
      updatedAt: createdAt,
    });
  }

  await batch.commit();
  console.log(`${adTemplates.length} ads seeded successfully!`);
}

async function deleteExistingAds() {
  console.log('Deleting existing ads...');
  const snap = await db.collection('ads').get();
  if (snap.empty) { console.log('No existing ads.'); return; }
  let batch = db.batch();
  let count = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    count++;
    if (count % 450 === 0) { await batch.commit(); batch = db.batch(); }
  }
  await batch.commit();
  console.log(`Deleted ${count} existing ads.`);
}

async function main() {
  try {
    await ensureDemoUser();
    await deleteExistingAds();
    await seedAds();
    console.log('\nDone! 100 ads with real images added to Firestore.');
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message || err);
    process.exit(1);
  }
}

main();
