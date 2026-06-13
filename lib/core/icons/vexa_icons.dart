import 'package:flutter/material.dart';

/// Sistema avanzado de iconos de Vexa.
///
/// Decisión técnica: se usa la fuente Material Icons que ya viene empaquetada
/// con la app (uses-material-design) en lugar de soluciones tipo Iconify:
/// - 0 bytes extra de APK (la fuente ya está incluida).
/// - Render por glifos de fuente: más rápido que SVG parseado en runtime.
/// - Funciona 100% offline.
/// - Al referenciar cada icono como `const IconData`, el tree-shaking de
///   iconos los conserva aunque luego se reconstruyan por codePoint desde Isar.
///
/// Cada entrada lleva keywords en español e inglés para búsqueda instantánea
/// y sugerencias automáticas al crear categorías/subcategorías.
class VexaIcon {
  const VexaIcon(this.icon, this.name, this.keywords);

  final IconData icon;
  final String name;

  /// Keywords ya normalizadas (minúsculas, sin acentos).
  final List<String> keywords;
}

/// Categoría visual del catálogo de iconos.
class VexaIconCategory {
  const VexaIconCategory(this.id, this.label, this.icon, this.icons);

  final String id;
  final String label;
  final IconData icon;
  final List<VexaIcon> icons;
}

/// Normaliza texto para búsqueda: minúsculas y sin acentos.
String normalizeIconQuery(String input) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final lower = input.toLowerCase().trim();
  final buf = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final idx = from.indexOf(ch);
    buf.write(idx >= 0 ? to[idx] : ch);
  }
  return buf.toString();
}

// ── Catálogo ──────────────────────────────────────────────────────────────────

const _comida = [
  VexaIcon(Icons.restaurant_rounded, 'Restaurante', [
    'restaurante',
    'comida',
    'comer',
    'food',
    'restaurant',
    'cena',
    'almuerzo',
  ]),
  VexaIcon(Icons.fastfood_rounded, 'Fast Food', [
    'fast food',
    'hamburguesa',
    'burger',
    'rapida',
    'mcdonalds',
    'kfc',
  ]),
  VexaIcon(Icons.lunch_dining_rounded, 'Hamburguesa', [
    'hamburguesa',
    'burger',
    'lunch',
    'almuerzo',
  ]),
  VexaIcon(Icons.local_pizza_rounded, 'Pizza', [
    'pizza',
    'italiana',
    'dominos',
  ]),
  VexaIcon(Icons.local_cafe_rounded, 'Café', [
    'cafe',
    'coffee',
    'starbucks',
    'cafeteria',
    'te',
    'tea',
  ]),
  VexaIcon(Icons.coffee_rounded, 'Café para llevar', [
    'cafe',
    'coffee',
    'espresso',
    'latte',
  ]),
  VexaIcon(Icons.emoji_food_beverage_rounded, 'Té', [
    'te',
    'tea',
    'infusion',
    'bebida caliente',
  ]),
  VexaIcon(Icons.local_bar_rounded, 'Bar', [
    'bar',
    'copas',
    'alcohol',
    'cocktail',
    'fiesta',
    'antro',
  ]),
  VexaIcon(Icons.sports_bar_rounded, 'Cerveza', [
    'cerveza',
    'beer',
    'chela',
    'bar',
  ]),
  VexaIcon(Icons.wine_bar_rounded, 'Vino', ['vino', 'wine', 'copa']),
  VexaIcon(Icons.local_drink_rounded, 'Refresco', [
    'refresco',
    'soda',
    'bebida',
    'drink',
    'coca',
    'agua',
  ]),
  VexaIcon(Icons.water_drop_rounded, 'Agua', ['agua', 'water', 'garrafon']),
  VexaIcon(Icons.icecream_rounded, 'Helado', [
    'helado',
    'ice cream',
    'nieve',
    'postre',
  ]),
  VexaIcon(Icons.cake_rounded, 'Pastel', [
    'pastel',
    'cake',
    'cumpleanos',
    'postre',
    'reposteria',
  ]),
  VexaIcon(Icons.bakery_dining_rounded, 'Panadería', [
    'pan',
    'panaderia',
    'bakery',
    'croissant',
    'desayuno',
  ]),
  VexaIcon(Icons.breakfast_dining_rounded, 'Desayuno', [
    'desayuno',
    'breakfast',
    'pan tostado',
  ]),
  VexaIcon(Icons.dinner_dining_rounded, 'Cena', [
    'cena',
    'dinner',
    'pasta',
    'spaghetti',
  ]),
  VexaIcon(Icons.ramen_dining_rounded, 'Ramen', [
    'ramen',
    'sopa',
    'asiatica',
    'noodles',
    'japonesa',
  ]),
  VexaIcon(Icons.rice_bowl_rounded, 'Arroz', [
    'arroz',
    'rice',
    'bowl',
    'china',
  ]),
  VexaIcon(Icons.set_meal_rounded, 'Sushi', [
    'sushi',
    'japonesa',
    'pescado',
    'mariscos',
  ]),
  VexaIcon(Icons.kebab_dining_rounded, 'Kebab', ['kebab', 'shawarma', 'arabe']),
  VexaIcon(Icons.tapas_rounded, 'Antojitos', [
    'antojitos',
    'tapas',
    'snack',
    'botana',
    'tacos',
  ]),
  VexaIcon(Icons.egg_rounded, 'Huevos', ['huevo', 'egg', 'desayuno']),
  VexaIcon(Icons.local_grocery_store_rounded, 'Súper', [
    'super',
    'supermercado',
    'despensa',
    'grocery',
    'mercado',
    'walmart',
  ]),
  VexaIcon(Icons.shopping_basket_rounded, 'Despensa', [
    'despensa',
    'canasta',
    'basket',
    'mandado',
  ]),
  VexaIcon(Icons.delivery_dining_rounded, 'Delivery', [
    'delivery',
    'a domicilio',
    'rappi',
    'uber eats',
    'didi food',
    'envio comida',
  ]),
  VexaIcon(Icons.takeout_dining_rounded, 'Para llevar', [
    'para llevar',
    'takeout',
    'caja',
  ]),
  VexaIcon(Icons.outdoor_grill_rounded, 'Parrilla', [
    'parrilla',
    'asado',
    'bbq',
    'carne',
    'grill',
  ]),
  VexaIcon(Icons.fork_right_rounded, 'Cubiertos', [
    'cubiertos',
    'tenedor',
    'comida',
  ]),
];

const _transporte = [
  VexaIcon(Icons.directions_car_rounded, 'Auto', [
    'auto',
    'coche',
    'carro',
    'car',
    'vehiculo',
  ]),
  VexaIcon(Icons.local_gas_station_rounded, 'Gasolina', [
    'gasolina',
    'gas',
    'combustible',
    'fuel',
    'pemex',
  ]),
  VexaIcon(Icons.local_taxi_rounded, 'Taxi', [
    'taxi',
    'uber',
    'didi',
    'cabify',
    'lyft',
    'viaje',
  ]),
  VexaIcon(Icons.directions_bus_rounded, 'Autobús', [
    'autobus',
    'bus',
    'camion',
    'transporte publico',
  ]),
  VexaIcon(Icons.subway_rounded, 'Metro', ['metro', 'subway', 'tren ligero']),
  VexaIcon(Icons.train_rounded, 'Tren', ['tren', 'train', 'ferrocarril']),
  VexaIcon(Icons.tram_rounded, 'Tranvía', ['tranvia', 'tram', 'trolebus']),
  VexaIcon(Icons.two_wheeler_rounded, 'Moto', [
    'moto',
    'motocicleta',
    'scooter',
    'motorcycle',
  ]),
  VexaIcon(Icons.pedal_bike_rounded, 'Bicicleta', [
    'bicicleta',
    'bici',
    'bike',
    'ciclismo',
  ]),
  VexaIcon(Icons.electric_scooter_rounded, 'Scooter', [
    'scooter',
    'patin',
    'electrico',
  ]),
  VexaIcon(Icons.local_parking_rounded, 'Estacionamiento', [
    'estacionamiento',
    'parking',
    'parquimetro',
    'pension',
  ]),
  VexaIcon(Icons.toll_rounded, 'Casetas', [
    'caseta',
    'peaje',
    'toll',
    'autopista',
    'cuota',
  ]),
  VexaIcon(Icons.car_repair_rounded, 'Taller', [
    'taller',
    'mecanico',
    'reparacion auto',
    'servicio',
  ]),
  VexaIcon(Icons.local_car_wash_rounded, 'Autolavado', [
    'autolavado',
    'lavado',
    'car wash',
  ]),
  VexaIcon(Icons.tire_repair_rounded, 'Llantas', [
    'llantas',
    'neumaticos',
    'tire',
    'vulcanizadora',
  ]),
  VexaIcon(Icons.ev_station_rounded, 'Carga eléctrica', [
    'carga',
    'electrico',
    'ev',
    'tesla',
  ]),
  VexaIcon(Icons.flight_rounded, 'Vuelo', [
    'vuelo',
    'avion',
    'flight',
    'aeropuerto',
    'viaje',
  ]),
  VexaIcon(Icons.directions_boat_rounded, 'Barco', [
    'barco',
    'ferry',
    'boat',
    'lancha',
  ]),
  VexaIcon(Icons.local_shipping_rounded, 'Envíos', [
    'envio',
    'paqueteria',
    'shipping',
    'flete',
    'mudanza',
  ]),
  VexaIcon(Icons.commute_rounded, 'Traslados', [
    'traslado',
    'commute',
    'transporte',
    'viaje diario',
  ]),
];

const _finanzas = [
  VexaIcon(Icons.attach_money_rounded, 'Dinero', [
    'dinero',
    'money',
    'efectivo',
    'peso',
    'dolar',
  ]),
  VexaIcon(Icons.payments_rounded, 'Pagos', [
    'pago',
    'payments',
    'billetes',
    'efectivo',
  ]),
  VexaIcon(Icons.account_balance_rounded, 'Banco', [
    'banco',
    'bank',
    'bbva',
    'santander',
    'banorte',
  ]),
  VexaIcon(Icons.account_balance_wallet_rounded, 'Cartera', [
    'cartera',
    'wallet',
    'billetera',
  ]),
  VexaIcon(Icons.savings_rounded, 'Ahorro', [
    'ahorro',
    'savings',
    'alcancia',
    'cochinito',
  ]),
  VexaIcon(Icons.credit_card_rounded, 'Tarjeta', [
    'tarjeta',
    'credito',
    'debito',
    'credit card',
    'nu',
  ]),
  VexaIcon(Icons.currency_exchange_rounded, 'Cambio', [
    'cambio',
    'divisas',
    'exchange',
    'dolares',
  ]),
  VexaIcon(Icons.trending_up_rounded, 'Inversión', [
    'inversion',
    'invest',
    'bolsa',
    'acciones',
    'rendimiento',
  ]),
  VexaIcon(Icons.show_chart_rounded, 'Trading', [
    'trading',
    'acciones',
    'bolsa',
    'chart',
    'gbm',
  ]),
  VexaIcon(Icons.currency_bitcoin_rounded, 'Cripto', [
    'cripto',
    'bitcoin',
    'crypto',
    'ethereum',
    'binance',
  ]),
  VexaIcon(Icons.request_quote_rounded, 'Facturas', [
    'factura',
    'recibo',
    'invoice',
    'cobro',
  ]),
  VexaIcon(Icons.receipt_long_rounded, 'Recibos', [
    'recibo',
    'ticket',
    'receipt',
    'comprobante',
  ]),
  VexaIcon(Icons.price_check_rounded, 'Impuestos', [
    'impuestos',
    'tax',
    'sat',
    'declaracion',
  ]),
  VexaIcon(Icons.handshake_rounded, 'Préstamo', [
    'prestamo',
    'loan',
    'deuda',
    'credito personal',
  ]),
  VexaIcon(Icons.volunteer_activism_rounded, 'Donación', [
    'donacion',
    'donativo',
    'caridad',
    'donation',
    'apoyo',
  ]),
  VexaIcon(Icons.redeem_rounded, 'Regalo', [
    'regalo',
    'gift',
    'premio',
    'recompensa',
  ]),
  VexaIcon(Icons.paid_rounded, 'Cobro', [
    'cobro',
    'pago recibido',
    'paid',
    'ingreso',
  ]),
  VexaIcon(Icons.work_rounded, 'Trabajo', [
    'trabajo',
    'work',
    'empleo',
    'salario',
    'nomina',
    'sueldo',
  ]),
  VexaIcon(Icons.business_center_rounded, 'Negocios', [
    'negocio',
    'business',
    'maletin',
    'empresa',
  ]),
  VexaIcon(Icons.laptop_rounded, 'Freelance', [
    'freelance',
    'laptop',
    'remoto',
    'proyecto',
  ]),
];

const _hogar = [
  VexaIcon(Icons.home_rounded, 'Casa', ['casa', 'hogar', 'home', 'vivienda']),
  VexaIcon(Icons.apartment_rounded, 'Departamento', [
    'departamento',
    'depa',
    'apartment',
    'edificio',
  ]),
  VexaIcon(Icons.key_rounded, 'Renta', [
    'renta',
    'alquiler',
    'rent',
    'llaves',
    'arrendamiento',
  ]),
  VexaIcon(Icons.chair_rounded, 'Muebles', [
    'muebles',
    'sillon',
    'furniture',
    'ikea',
    'decoracion',
  ]),
  VexaIcon(Icons.bed_rounded, 'Recámara', [
    'recamara',
    'cama',
    'bed',
    'colchon',
    'dormitorio',
  ]),
  VexaIcon(Icons.kitchen_rounded, 'Cocina', [
    'cocina',
    'kitchen',
    'refrigerador',
    'electrodomestico',
  ]),
  VexaIcon(Icons.microwave_rounded, 'Electrodomésticos', [
    'electrodomestico',
    'microondas',
    'appliance',
  ]),
  VexaIcon(Icons.local_laundry_service_rounded, 'Lavandería', [
    'lavanderia',
    'laundry',
    'lavadora',
    'tintoreria',
  ]),
  VexaIcon(Icons.cleaning_services_rounded, 'Limpieza', [
    'limpieza',
    'cleaning',
    'aseo',
    'detergente',
  ]),
  VexaIcon(Icons.yard_rounded, 'Jardín', [
    'jardin',
    'plantas',
    'garden',
    'pasto',
    'jardineria',
  ]),
  VexaIcon(Icons.handyman_rounded, 'Reparaciones', [
    'reparacion',
    'mantenimiento',
    'handyman',
    'plomero',
    'herramienta',
  ]),
  VexaIcon(Icons.construction_rounded, 'Remodelación', [
    'remodelacion',
    'construccion',
    'obra',
    'albanil',
  ]),
  VexaIcon(Icons.format_paint_rounded, 'Pintura', [
    'pintura',
    'paint',
    'pintar',
    'brocha',
  ]),
  VexaIcon(Icons.light_rounded, 'Iluminación', [
    'iluminacion',
    'lampara',
    'foco',
    'luz decorativa',
  ]),
  VexaIcon(Icons.blender_rounded, 'Cocina menor', [
    'licuadora',
    'blender',
    'utensilios',
  ]),
  VexaIcon(Icons.checkroom_rounded, 'Clóset', [
    'closet',
    'guardarropa',
    'armario',
  ]),
];

const _tecnologia = [
  VexaIcon(Icons.devices_rounded, 'Dispositivos', [
    'dispositivos',
    'devices',
    'gadgets',
    'tecnologia',
    'tech',
  ]),
  VexaIcon(Icons.smartphone_rounded, 'Celular', [
    'celular',
    'telefono',
    'smartphone',
    'iphone',
    'movil',
  ]),
  VexaIcon(Icons.laptop_mac_rounded, 'Laptop', [
    'laptop',
    'computadora',
    'mac',
    'notebook',
    'pc',
  ]),
  VexaIcon(Icons.desktop_windows_rounded, 'PC', [
    'pc',
    'computadora',
    'desktop',
    'escritorio',
    'monitor',
  ]),
  VexaIcon(Icons.tablet_mac_rounded, 'Tablet', ['tablet', 'ipad']),
  VexaIcon(Icons.watch_rounded, 'Smartwatch', [
    'reloj',
    'smartwatch',
    'watch',
    'apple watch',
  ]),
  VexaIcon(Icons.headphones_rounded, 'Audífonos', [
    'audifonos',
    'headphones',
    'airpods',
    'auriculares',
  ]),
  VexaIcon(Icons.speaker_rounded, 'Bocinas', [
    'bocina',
    'speaker',
    'altavoz',
    'alexa',
  ]),
  VexaIcon(Icons.camera_alt_rounded, 'Cámara', [
    'camara',
    'camera',
    'fotografia',
    'gopro',
  ]),
  VexaIcon(Icons.videogame_asset_rounded, 'Consola', [
    'consola',
    'videojuegos',
    'playstation',
    'xbox',
    'nintendo',
  ]),
  VexaIcon(Icons.keyboard_rounded, 'Periféricos', [
    'teclado',
    'mouse',
    'keyboard',
    'perifericos',
  ]),
  VexaIcon(Icons.memory_rounded, 'Componentes', [
    'componentes',
    'chip',
    'memoria',
    'hardware',
    'procesador',
  ]),
  VexaIcon(Icons.cable_rounded, 'Cables', [
    'cable',
    'cargador',
    'usb',
    'adaptador',
  ]),
  VexaIcon(Icons.print_rounded, 'Impresora', [
    'impresora',
    'printer',
    'tinta',
    'impresion',
  ]),
  VexaIcon(Icons.router_rounded, 'Internet', [
    'internet',
    'wifi',
    'modem',
    'router',
    'telmex',
    'izzi',
  ]),
  VexaIcon(Icons.cloud_rounded, 'Nube', [
    'nube',
    'cloud',
    'icloud',
    'almacenamiento',
    'drive',
  ]),
  VexaIcon(Icons.code_rounded, 'Software', [
    'software',
    'codigo',
    'apps',
    'licencia',
    'programa',
  ]),
];

const _salud = [
  VexaIcon(Icons.favorite_rounded, 'Salud', [
    'salud',
    'corazon',
    'health',
    'amor',
  ]),
  VexaIcon(Icons.medical_services_rounded, 'Médico', [
    'medico',
    'doctor',
    'consulta',
    'medical',
    'clinica',
  ]),
  VexaIcon(Icons.local_hospital_rounded, 'Hospital', [
    'hospital',
    'emergencia',
    'urgencias',
  ]),
  VexaIcon(Icons.local_pharmacy_rounded, 'Farmacia', [
    'farmacia',
    'medicina',
    'pharmacy',
    'medicamentos',
    'similares',
  ]),
  VexaIcon(Icons.medication_rounded, 'Medicinas', [
    'medicina',
    'pastillas',
    'medicamento',
    'vitaminas',
  ]),
  VexaIcon(Icons.vaccines_rounded, 'Vacunas', [
    'vacuna',
    'inyeccion',
    'vaccine',
  ]),
  VexaIcon(Icons.bloodtype_rounded, 'Laboratorio', [
    'laboratorio',
    'analisis',
    'sangre',
    'estudios',
  ]),
  VexaIcon(Icons.visibility_rounded, 'Óptica', [
    'optica',
    'lentes',
    'ojos',
    'vision',
    'oftalmologo',
  ]),
  VexaIcon(Icons.medical_information_rounded, 'Dentista', [
    'dentista',
    'dental',
    'ortodoncia',
    'muela',
  ]),
  VexaIcon(Icons.psychology_rounded, 'Terapia', [
    'terapia',
    'psicologo',
    'mental',
    'psiquiatra',
  ]),
  VexaIcon(Icons.health_and_safety_rounded, 'Seguro médico', [
    'seguro',
    'gastos medicos',
    'insurance',
    'poliza',
  ]),
  VexaIcon(Icons.fitness_center_rounded, 'Gimnasio', [
    'gimnasio',
    'gym',
    'pesas',
    'ejercicio',
    'fitness',
    'smartfit',
  ]),
  VexaIcon(Icons.self_improvement_rounded, 'Yoga', [
    'yoga',
    'meditacion',
    'bienestar',
    'wellness',
  ]),
  VexaIcon(Icons.spa_rounded, 'Spa', [
    'spa',
    'masaje',
    'relajacion',
    'belleza',
  ]),
  VexaIcon(Icons.face_retouching_natural_rounded, 'Cuidado personal', [
    'cuidado',
    'belleza',
    'skincare',
    'cosmeticos',
    'maquillaje',
  ]),
  VexaIcon(Icons.content_cut_rounded, 'Peluquería', [
    'peluqueria',
    'corte',
    'barberia',
    'estetica',
    'salon',
  ]),
];

const _educacion = [
  VexaIcon(Icons.school_rounded, 'Escuela', [
    'escuela',
    'school',
    'colegiatura',
    'universidad',
    'educacion',
  ]),
  VexaIcon(Icons.menu_book_rounded, 'Libros', [
    'libros',
    'book',
    'lectura',
    'libreria',
  ]),
  VexaIcon(Icons.auto_stories_rounded, 'Lectura', [
    'lectura',
    'leer',
    'revista',
    'ebook',
    'kindle',
  ]),
  VexaIcon(Icons.edit_rounded, 'Papelería', [
    'papeleria',
    'utiles',
    'lapiz',
    'cuaderno',
  ]),
  VexaIcon(Icons.calculate_rounded, 'Matemáticas', [
    'matematicas',
    'calculadora',
    'math',
  ]),
  VexaIcon(Icons.science_rounded, 'Ciencia', [
    'ciencia',
    'science',
    'quimica',
    'laboratorio escolar',
  ]),
  VexaIcon(Icons.language_rounded, 'Idiomas', [
    'idiomas',
    'ingles',
    'language',
    'duolingo',
    'frances',
  ]),
  VexaIcon(Icons.cast_for_education_rounded, 'Cursos', [
    'curso',
    'online',
    'udemy',
    'platzi',
    'capacitacion',
    'diplomado',
  ]),
  VexaIcon(Icons.history_edu_rounded, 'Certificación', [
    'certificacion',
    'titulo',
    'diploma',
    'examen',
  ]),
  VexaIcon(Icons.music_note_rounded, 'Música', [
    'musica',
    'music',
    'clases de musica',
    'instrumento',
  ]),
  VexaIcon(Icons.piano_rounded, 'Piano', ['piano', 'teclado musical']),
  VexaIcon(Icons.palette_rounded, 'Arte', [
    'arte',
    'pintura clases',
    'art',
    'dibujo',
    'creatividad',
  ]),
];

const _entretenimiento = [
  VexaIcon(Icons.movie_rounded, 'Cine', [
    'cine',
    'pelicula',
    'movie',
    'cinepolis',
    'cinemex',
  ]),
  VexaIcon(Icons.theaters_rounded, 'Teatro', [
    'teatro',
    'obra',
    'funcion',
    'theater',
  ]),
  VexaIcon(Icons.live_tv_rounded, 'Streaming', [
    'streaming',
    'netflix',
    'hbo',
    'disney',
    'prime',
    'tv',
  ]),
  VexaIcon(Icons.tv_rounded, 'Televisión', [
    'television',
    'tv',
    'cable',
    'sky',
  ]),
  VexaIcon(Icons.sports_esports_rounded, 'Videojuegos', [
    'videojuegos',
    'gaming',
    'games',
    'steam',
    'play',
  ]),
  VexaIcon(Icons.headset_mic_rounded, 'Gaming', [
    'gaming',
    'gamer',
    'discord',
    'twitch',
  ]),
  VexaIcon(Icons.music_video_rounded, 'Conciertos', [
    'concierto',
    'festival',
    'show',
    'boletos',
    'ticketmaster',
  ]),
  VexaIcon(Icons.library_music_rounded, 'Música streaming', [
    'musica',
    'spotify',
    'apple music',
    'playlist',
  ]),
  VexaIcon(Icons.podcasts_rounded, 'Podcast', ['podcast', 'audio', 'audible']),
  VexaIcon(Icons.celebration_rounded, 'Fiestas', [
    'fiesta',
    'celebracion',
    'party',
    'evento',
    'cumpleanos',
  ]),
  VexaIcon(Icons.nightlife_rounded, 'Vida nocturna', [
    'antro',
    'club',
    'nightlife',
    'bar nocturno',
  ]),
  VexaIcon(Icons.casino_rounded, 'Casino', [
    'casino',
    'apuestas',
    'loteria',
    'juego',
  ]),
  VexaIcon(Icons.attractions_rounded, 'Parque diversiones', [
    'parque',
    'feria',
    'six flags',
    'atracciones',
    'kataplum',
  ]),
  VexaIcon(Icons.toys_rounded, 'Juguetes', [
    'juguetes',
    'toys',
    'lego',
    'coleccionables',
  ]),
  VexaIcon(Icons.smart_toy_rounded, 'Hobbies', [
    'hobby',
    'pasatiempo',
    'coleccion',
    'robot',
  ]),
  VexaIcon(Icons.photo_camera_rounded, 'Fotografía', [
    'fotografia',
    'fotos',
    'revelado',
  ]),
];

const _viajes = [
  VexaIcon(Icons.flight_takeoff_rounded, 'Viajes', [
    'viaje',
    'travel',
    'vuelo',
    'despegue',
    'vacaciones',
  ]),
  VexaIcon(Icons.luggage_rounded, 'Equipaje', [
    'equipaje',
    'maleta',
    'luggage',
  ]),
  VexaIcon(Icons.hotel_rounded, 'Hotel', [
    'hotel',
    'hospedaje',
    'airbnb',
    'alojamiento',
    'booking',
  ]),
  VexaIcon(Icons.beach_access_rounded, 'Playa', [
    'playa',
    'beach',
    'vacaciones',
    'cancun',
  ]),
  VexaIcon(Icons.landscape_rounded, 'Montaña', [
    'montana',
    'naturaleza',
    'senderismo',
    'hike',
  ]),
  VexaIcon(Icons.forest_rounded, 'Camping', [
    'camping',
    'bosque',
    'acampar',
    'tienda',
  ]),
  VexaIcon(Icons.map_rounded, 'Tours', ['tour', 'mapa', 'excursion', 'guia']),
  VexaIcon(Icons.museum_rounded, 'Museos', [
    'museo',
    'cultura',
    'museum',
    'exposicion',
  ]),
  VexaIcon(Icons.local_activity_rounded, 'Actividades', [
    'actividad',
    'boletos',
    'entradas',
    'experiencia',
  ]),
  VexaIcon(Icons.translate_rounded, 'Extranjero', [
    'extranjero',
    'internacional',
    'pasaporte',
  ]),
  VexaIcon(Icons.directions_walk_rounded, 'Paseos', [
    'paseo',
    'caminata',
    'walk',
  ]),
];

const _compras = [
  VexaIcon(Icons.shopping_bag_rounded, 'Compras', [
    'compras',
    'shopping',
    'bolsa',
    'tienda',
  ]),
  VexaIcon(Icons.shopping_cart_rounded, 'Carrito', [
    'carrito',
    'cart',
    'amazon',
    'mercado libre',
    'online',
  ]),
  VexaIcon(Icons.storefront_rounded, 'Tienda', [
    'tienda',
    'store',
    'local',
    'comercio',
    'oxxo',
  ]),
  VexaIcon(Icons.local_mall_rounded, 'Centro comercial', [
    'centro comercial',
    'mall',
    'plaza',
    'liverpool',
  ]),
  VexaIcon(Icons.checkroom_rounded, 'Ropa', [
    'ropa',
    'clothes',
    'zara',
    'moda',
    'vestimenta',
  ]),
  VexaIcon(Icons.dry_cleaning_rounded, 'Vestidos', [
    'vestido',
    'formal',
    'gala',
  ]),
  VexaIcon(Icons.snowshoeing_rounded, 'Calzado deportivo', [
    'tenis deportivos',
    'sneakers',
  ]),
  VexaIcon(Icons.roller_skating_rounded, 'Zapatos', [
    'zapatos',
    'calzado',
    'tenis',
    'shoes',
    'botas',
  ]),
  VexaIcon(Icons.diamond_rounded, 'Joyería', [
    'joyeria',
    'anillo',
    'diamante',
    'jewelry',
    'accesorios',
  ]),
  VexaIcon(Icons.watch_later_rounded, 'Relojes', ['reloj', 'watch']),
  VexaIcon(Icons.card_giftcard_rounded, 'Regalos', [
    'regalo',
    'gift',
    'tarjeta regalo',
    'detalle',
  ]),
  VexaIcon(Icons.local_florist_rounded, 'Flores', [
    'flores',
    'flower',
    'ramo',
    'floreria',
  ]),
  VexaIcon(Icons.auto_awesome_rounded, 'Lujo', [
    'lujo',
    'premium',
    'luxury',
    'capricho',
  ]),
];

const _deportes = [
  VexaIcon(Icons.sports_soccer_rounded, 'Fútbol', [
    'futbol',
    'soccer',
    'balon',
    'partido',
  ]),
  VexaIcon(Icons.sports_basketball_rounded, 'Básquet', [
    'basquet',
    'basketball',
    'nba',
  ]),
  VexaIcon(Icons.sports_tennis_rounded, 'Tenis', [
    'tenis',
    'tennis',
    'padel',
    'raqueta',
  ]),
  VexaIcon(Icons.sports_baseball_rounded, 'Béisbol', [
    'beisbol',
    'baseball',
    'mlb',
  ]),
  VexaIcon(Icons.sports_volleyball_rounded, 'Vóley', [
    'voleibol',
    'volleyball',
  ]),
  VexaIcon(Icons.sports_football_rounded, 'Fút. americano', [
    'americano',
    'nfl',
    'football',
  ]),
  VexaIcon(Icons.sports_golf_rounded, 'Golf', ['golf']),
  VexaIcon(Icons.sports_mma_rounded, 'Box', ['box', 'mma', 'ufc', 'lucha']),
  VexaIcon(Icons.pool_rounded, 'Natación', [
    'natacion',
    'alberca',
    'piscina',
    'swim',
  ]),
  VexaIcon(Icons.surfing_rounded, 'Surf', ['surf', 'tabla']),
  VexaIcon(Icons.downhill_skiing_rounded, 'Ski', ['ski', 'nieve', 'snowboard']),
  VexaIcon(Icons.hiking_rounded, 'Senderismo', [
    'senderismo',
    'hiking',
    'trekking',
  ]),
  VexaIcon(Icons.directions_run_rounded, 'Running', [
    'correr',
    'running',
    'maraton',
    'carrera',
  ]),
  VexaIcon(Icons.skateboarding_rounded, 'Skate', ['skate', 'patineta']),
  VexaIcon(Icons.sports_rounded, 'Deportes', [
    'deportes',
    'sports',
    'silbato',
    'entrenador',
  ]),
];

const _mascotas = [
  VexaIcon(Icons.pets_rounded, 'Mascotas', [
    'mascota',
    'pets',
    'huella',
    'perro',
    'gato',
    'animal',
  ]),
  VexaIcon(Icons.cruelty_free_rounded, 'Conejo', [
    'conejo',
    'roedor',
    'hamster',
  ]),
  VexaIcon(Icons.flutter_dash_rounded, 'Aves', [
    'ave',
    'pajaro',
    'perico',
    'bird',
  ]),
  VexaIcon(Icons.set_meal_outlined, 'Peces', ['pez', 'acuario', 'fish']),
  VexaIcon(Icons.medical_services_outlined, 'Veterinario', [
    'veterinario',
    'vet',
    'consulta mascota',
  ]),
  VexaIcon(Icons.shower_rounded, 'Estética canina', [
    'estetica',
    'bano perro',
    'grooming',
  ]),
  VexaIcon(Icons.food_bank_rounded, 'Croquetas', [
    'croquetas',
    'alimento mascota',
    'comida perro',
    'comida gato',
  ]),
];

const _negocios = [
  VexaIcon(Icons.apartment_rounded, 'Oficina', [
    'oficina',
    'office',
    'corporativo',
    'coworking',
  ]),
  VexaIcon(Icons.badge_rounded, 'Nómina', [
    'nomina',
    'empleados',
    'payroll',
    'salarios',
  ]),
  VexaIcon(Icons.groups_rounded, 'Equipo', [
    'equipo',
    'team',
    'personal',
    'socios',
  ]),
  VexaIcon(Icons.campaign_rounded, 'Publicidad', [
    'publicidad',
    'marketing',
    'ads',
    'anuncios',
    'facebook ads',
  ]),
  VexaIcon(Icons.inventory_2_rounded, 'Inventario', [
    'inventario',
    'stock',
    'mercancia',
    'producto',
  ]),
  VexaIcon(Icons.point_of_sale_rounded, 'Ventas', [
    'ventas',
    'caja',
    'pos',
    'cobros',
  ]),
  VexaIcon(Icons.precision_manufacturing_rounded, 'Producción', [
    'produccion',
    'fabrica',
    'maquinaria',
  ]),
  VexaIcon(Icons.gavel_rounded, 'Legal', [
    'legal',
    'abogado',
    'notario',
    'tramite legal',
  ]),
  VexaIcon(Icons.support_agent_rounded, 'Servicios prof.', [
    'consultoria',
    'asesoria',
    'contador',
    'profesional',
  ]),
  VexaIcon(Icons.rocket_launch_rounded, 'Startup', [
    'startup',
    'emprendimiento',
    'proyecto',
    'lanzamiento',
  ]),
];

const _servicios = [
  VexaIcon(Icons.bolt_rounded, 'Luz', [
    'luz',
    'electricidad',
    'cfe',
    'electric',
    'recibo de luz',
  ]),
  VexaIcon(Icons.water_damage_rounded, 'Agua servicio', [
    'agua',
    'recibo de agua',
    'sapal',
    'water bill',
  ]),
  VexaIcon(Icons.local_fire_department_rounded, 'Gas', [
    'gas',
    'gas natural',
    'tanque',
    'estacionario',
  ]),
  VexaIcon(Icons.wifi_rounded, 'Internet servicio', [
    'internet',
    'wifi',
    'fibra',
    'megacable',
    'totalplay',
  ]),
  VexaIcon(Icons.phone_iphone_rounded, 'Telefonía', [
    'telefono',
    'plan',
    'telcel',
    'att',
    'movistar',
    'recarga',
  ]),
  VexaIcon(Icons.subscriptions_rounded, 'Suscripciones', [
    'suscripcion',
    'subscription',
    'membresia',
    'mensualidad',
  ]),
  VexaIcon(Icons.shield_rounded, 'Seguros', [
    'seguro',
    'insurance',
    'poliza',
    'proteccion',
  ]),
  VexaIcon(Icons.account_balance_outlined, 'Gobierno', [
    'gobierno',
    'tramite',
    'predial',
    'tenencia',
    'multa',
  ]),
  VexaIcon(Icons.delete_rounded, 'Basura', ['basura', 'recoleccion', 'limpia']),
  VexaIcon(Icons.engineering_rounded, 'Mantenimiento', [
    'mantenimiento',
    'cuota',
    'condominio',
    'vigilancia',
  ]),
  VexaIcon(Icons.child_care_rounded, 'Niñera', [
    'ninera',
    'guarderia',
    'cuidado ninos',
    'babysitter',
  ]),
  VexaIcon(Icons.elderly_rounded, 'Cuidados', [
    'cuidados',
    'enfermera',
    'adulto mayor',
  ]),
];

const _otros = [
  VexaIcon(Icons.category_rounded, 'Categoría', [
    'categoria',
    'otro',
    'general',
    'category',
    'varios',
  ]),
  VexaIcon(Icons.star_rounded, 'Estrella', [
    'estrella',
    'star',
    'favorito',
    'destacado',
  ]),
  VexaIcon(Icons.bookmark_rounded, 'Marcador', [
    'marcador',
    'bookmark',
    'guardado',
  ]),
  VexaIcon(Icons.label_rounded, 'Etiqueta', ['etiqueta', 'label', 'tag']),
  VexaIcon(Icons.extension_rounded, 'Extra', [
    'extra',
    'extension',
    'puzzle',
    'misc',
  ]),
  VexaIcon(Icons.all_inclusive_rounded, 'Infinito', [
    'infinito',
    'todo incluido',
    'infinity',
  ]),
  VexaIcon(Icons.emoji_events_rounded, 'Logros', [
    'logro',
    'trofeo',
    'premio',
    'trophy',
    'meta',
  ]),
  VexaIcon(Icons.flag_rounded, 'Meta', ['meta', 'objetivo', 'flag', 'goal']),
  VexaIcon(Icons.lightbulb_rounded, 'Idea', [
    'idea',
    'lightbulb',
    'inspiracion',
  ]),
  VexaIcon(Icons.eco_rounded, 'Ecología', [
    'ecologia',
    'verde',
    'eco',
    'sustentable',
    'planta',
  ]),
  VexaIcon(Icons.wb_sunny_rounded, 'Sol', ['sol', 'clima', 'sunny', 'verano']),
  VexaIcon(Icons.nightlight_rounded, 'Noche', ['noche', 'luna', 'night']),
  VexaIcon(Icons.favorite_border_rounded, 'Corazón', [
    'corazon',
    'amor',
    'heart',
    'pareja',
    'cita',
  ]),
  VexaIcon(Icons.church_rounded, 'Religión', [
    'religion',
    'iglesia',
    'diezmo',
    'church',
  ]),
  VexaIcon(Icons.escalator_warning_rounded, 'Familia', [
    'familia',
    'hijos',
    'family',
    'ninos',
  ]),
  VexaIcon(Icons.child_friendly_rounded, 'Bebé', [
    'bebe',
    'baby',
    'panales',
    'carriola',
  ]),
  VexaIcon(Icons.smoking_rooms_rounded, 'Tabaco', [
    'tabaco',
    'cigarros',
    'vape',
    'smoking',
  ]),
  VexaIcon(Icons.question_mark_rounded, 'Desconocido', [
    'desconocido',
    'pregunta',
    'unknown',
    'sin clasificar',
  ]),
];

/// Catálogo completo organizado por categorías (orden de presentación).
const kVexaIconCategories = [
  VexaIconCategory('comida', 'Comida', Icons.restaurant_rounded, _comida),
  VexaIconCategory(
    'transporte',
    'Transporte',
    Icons.directions_car_rounded,
    _transporte,
  ),
  VexaIconCategory(
    'finanzas',
    'Finanzas',
    Icons.attach_money_rounded,
    _finanzas,
  ),
  VexaIconCategory('hogar', 'Hogar', Icons.home_rounded, _hogar),
  VexaIconCategory(
    'tecnologia',
    'Tecnología',
    Icons.devices_rounded,
    _tecnologia,
  ),
  VexaIconCategory('salud', 'Salud', Icons.favorite_rounded, _salud),
  VexaIconCategory('educacion', 'Educación', Icons.school_rounded, _educacion),
  VexaIconCategory(
    'entretenimiento',
    'Entretenimiento',
    Icons.movie_rounded,
    _entretenimiento,
  ),
  VexaIconCategory('viajes', 'Viajes', Icons.flight_takeoff_rounded, _viajes),
  VexaIconCategory('compras', 'Compras', Icons.shopping_bag_rounded, _compras),
  VexaIconCategory(
    'deportes',
    'Deportes',
    Icons.sports_soccer_rounded,
    _deportes,
  ),
  VexaIconCategory('mascotas', 'Mascotas', Icons.pets_rounded, _mascotas),
  VexaIconCategory(
    'negocios',
    'Negocios',
    Icons.business_center_rounded,
    _negocios,
  ),
  VexaIconCategory('servicios', 'Servicios', Icons.bolt_rounded, _servicios),
  VexaIconCategory('otros', 'Otros', Icons.category_rounded, _otros),
];

/// Lista plana de todos los iconos (computada una sola vez, en orden).
final List<VexaIcon> kAllVexaIcons = List.unmodifiable(
  kVexaIconCategories.expand((c) => c.icons),
);

/// Marcas y servicios conocidos → keyword del icono a sugerir.
/// Funciona offline y es O(1) por palabra gracias al mapa.
const _kBrandSuggestions = <String, IconData>{
  'netflix': Icons.live_tv_rounded,
  'hbo': Icons.live_tv_rounded,
  'disney': Icons.live_tv_rounded,
  'prime': Icons.live_tv_rounded,
  'spotify': Icons.library_music_rounded,
  'youtube': Icons.live_tv_rounded,
  'starbucks': Icons.local_cafe_rounded,
  'uber': Icons.local_taxi_rounded,
  'didi': Icons.local_taxi_rounded,
  'cabify': Icons.local_taxi_rounded,
  'rappi': Icons.delivery_dining_rounded,
  'amazon': Icons.shopping_cart_rounded,
  'mercadolibre': Icons.shopping_cart_rounded,
  'oxxo': Icons.storefront_rounded,
  'walmart': Icons.local_grocery_store_rounded,
  'costco': Icons.local_grocery_store_rounded,
  'mcdonalds': Icons.fastfood_rounded,
  'kfc': Icons.fastfood_rounded,
  'dominos': Icons.local_pizza_rounded,
  'cinepolis': Icons.movie_rounded,
  'cinemex': Icons.movie_rounded,
  'steam': Icons.sports_esports_rounded,
  'xbox': Icons.sports_esports_rounded,
  'playstation': Icons.sports_esports_rounded,
  'nintendo': Icons.sports_esports_rounded,
  'telcel': Icons.phone_iphone_rounded,
  'telmex': Icons.router_rounded,
  'izzi': Icons.router_rounded,
  'totalplay': Icons.router_rounded,
  'megacable': Icons.router_rounded,
  'cfe': Icons.bolt_rounded,
  'pemex': Icons.local_gas_station_rounded,
  'airbnb': Icons.hotel_rounded,
  'smartfit': Icons.fitness_center_rounded,
  'duolingo': Icons.language_rounded,
  'udemy': Icons.cast_for_education_rounded,
  'platzi': Icons.cast_for_education_rounded,
  'apple': Icons.smartphone_rounded,
  'google': Icons.cloud_rounded,
  'gasolina': Icons.local_gas_station_rounded,
};

/// Índice keyword → icono construido una sola vez (lazy) para sugerencias.
final Map<String, VexaIcon> _keywordIndex = () {
  final map = <String, VexaIcon>{};
  // Recorrido inverso: los primeros del catálogo ganan en caso de colisión.
  for (final icon in kAllVexaIcons.reversed) {
    for (final kw in icon.keywords) {
      map[kw] = icon;
      // También indexar palabras individuales de keywords compuestas.
      for (final word in kw.split(' ')) {
        if (word.length > 2) map.putIfAbsent(word, () => icon);
      }
    }
  }
  return map;
}();

/// Sugiere un icono para un nombre de categoría/subcategoría escrito por el
/// usuario. 100% offline y O(palabras). Devuelve null si no hay coincidencia.
IconData? suggestIconFor(String name) {
  final normalized = normalizeIconQuery(name);
  if (normalized.isEmpty) return null;

  // 1. Marcas conocidas (coincidencia por palabra contenida).
  final compact = normalized.replaceAll(' ', '');
  for (final entry in _kBrandSuggestions.entries) {
    if (compact.contains(entry.key)) return entry.value;
  }

  // 2. Frase completa como keyword exacta.
  final exact = _keywordIndex[normalized];
  if (exact != null) return exact.icon;

  // 3. Por palabra individual.
  for (final word in normalized.split(' ')) {
    final hit = _keywordIndex[word];
    if (hit != null) return hit.icon;
  }

  // 4. Prefijo: "gasolin" encuentra "gasolina" (sin plurales triviales).
  if (normalized.length >= 4) {
    for (final entry in _keywordIndex.entries) {
      if (entry.key.startsWith(normalized) ||
          normalized.startsWith(entry.key)) {
        return entry.value.icon;
      }
    }
  }
  return null;
}

/// Búsqueda instantánea sobre el catálogo. Coincide por nombre y keywords.
List<VexaIcon> searchVexaIcons(String query) {
  final q = normalizeIconQuery(query);
  if (q.isEmpty) return kAllVexaIcons;
  final results = <VexaIcon>[];
  for (final icon in kAllVexaIcons) {
    if (normalizeIconQuery(icon.name).contains(q) ||
        icon.keywords.any((k) => k.contains(q))) {
      results.add(icon);
    }
  }
  return results;
}
