import 'package:flutter/material.dart';

enum TipCategory { saving, budgeting, investing, debt, habits, mindset }

extension TipCategoryX on TipCategory {
  String get label => switch (this) {
        TipCategory.saving => 'Ahorro',
        TipCategory.budgeting => 'Presupuesto',
        TipCategory.investing => 'Inversión',
        TipCategory.debt => 'Deudas',
        TipCategory.habits => 'Hábitos',
        TipCategory.mindset => 'Mentalidad',
      };

  IconData get icon => switch (this) {
        TipCategory.saving => Icons.savings_rounded,
        TipCategory.budgeting => Icons.account_balance_wallet_rounded,
        TipCategory.investing => Icons.trending_up_rounded,
        TipCategory.debt => Icons.credit_card_off_rounded,
        TipCategory.habits => Icons.repeat_rounded,
        TipCategory.mindset => Icons.psychology_rounded,
      };

  Color get color => switch (this) {
        TipCategory.saving => const Color(0xFF00D68F),
        TipCategory.budgeting => const Color(0xFF1A7A9A),
        TipCategory.investing => const Color(0xFFFFD54F),
        TipCategory.debt => const Color(0xFFFF5F82),
        TipCategory.habits => const Color(0xFFCE93D8),
        TipCategory.mindset => const Color(0xFF64B5F6),
      };
}

class FinancialTip {
  const FinancialTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.steps = const [],
  });

  final String id;
  final String title;
  final String content;
  final TipCategory category;
  final List<String> steps;
}

abstract final class FinancialTips {
  static const List<FinancialTip> all = [
    FinancialTip(
      id: 't1',
      title: 'La regla 50/30/20',
      content:
          'Destina el 50% de tus ingresos a necesidades, el 30% a deseos y el 20% al ahorro. Es la base de una buena salud financiera.',
      category: TipCategory.budgeting,
      steps: [
        'Calcula tu ingreso neto mensual: lo que recibes en mano después de impuestos y deducciones.',
        'El día de cobro transfiere inmediatamente el 20% a una cuenta de ahorro separada — hazlo antes de gastar cualquier cosa.',
        'Asigna el 50% a necesidades fijas: renta, servicios, comida, transporte, seguro médico.',
        'El 30% restante es para deseos: salidas, ropa, entretenimiento, suscripciones opcionales.',
        'Usa Vexa para categorizar tus gastos y ver en qué porcentaje real estás cada mes; ajusta si alguna categoría se sale del límite.',
      ],
    ),
    FinancialTip(
      id: 't2',
      title: 'Fondo de emergencia',
      content:
          'Antes de invertir, asegúrate de tener entre 3 y 6 meses de gastos en una cuenta de ahorro fácilmente accesible.',
      category: TipCategory.saving,
      steps: [
        'Suma tus gastos fijos mensuales: renta + servicios + comida + transporte + seguros.',
        'Multiplica ese total por 3 para el mínimo aceptable, o por 6 para mayor seguridad.',
        'Abre una cuenta de ahorro separada exclusivamente para esta reserva — no la mezcles con gastos diarios.',
        'Bancos digitales como Nubank, Hey Banco o BBVA Digital ofrecen rendimientos del 8–15% anual sin comisiones ni saldo mínimo.',
        'Automatiza una transferencia mensual fija hasta alcanzar el objetivo; después solo mantén el saldo.',
      ],
    ),
    FinancialTip(
      id: 't3',
      title: 'El poder del interés compuesto',
      content:
          'Invertir \$100 al mes durante 30 años al 8% anual te da más de \$150,000. Empieza hoy, aunque sea poco.',
      category: TipCategory.investing,
      steps: [
        'Abre una cuenta de inversión accesible desde \$100: GBM+, CETES Directo (cetesdirecto.com) o Fintual son opciones gratuitas.',
        'Define un monto fijo mensual que puedas sostener aunque sea pequeño — la constancia importa más que el monto.',
        'Elige fondos diversificados con comisión baja (menos del 1% anual); en GBM+ busca el fondo "Smart Cash" o ETFs globales.',
        'No retires el dinero ante caídas del mercado — cada retiro interrumpe el efecto compuesto acumulado.',
        'Visualiza tu proyección en calculatoras como investor.gov/financial-tools-calculators para mantenerte motivado.',
      ],
    ),
    FinancialTip(
      id: 't4',
      title: 'Elimina deuda de alto interés',
      content:
          'Pagar una tarjeta con 20% de interés es equivalente a una inversión garantizada del 20%. Prioriza liquidarla.',
      category: TipCategory.debt,
      steps: [
        'Lista todas tus deudas activas con su tasa de interés anual, saldo actual y pago mínimo mensual.',
        'Enfoca todo el dinero extra en la deuda con mayor tasa — cada peso extra ahí genera más ahorro que cualquier inversión.',
        'Llama a tu banco y negocia una tasa menor; menciona que llevas X años como cliente. Funciona especialmente con buen historial.',
        'Evalúa consolidar deudas de tarjeta en un crédito personal con tasa menor — compara en comparacrédito.com.mx.',
        'Mientras no liquides la deuda cara, evita abrir nuevas tarjetas o créditos que aumenten tu nivel de endeudamiento.',
      ],
    ),
    FinancialTip(
      id: 't5',
      title: 'Automatiza tu ahorro',
      content:
          'Configura una transferencia automática el día de cobro. Lo que no ves, no lo gastas.',
      category: TipCategory.habits,
      steps: [
        'Entra a tu banca en línea y programa una transferencia automática para el mismo día en que recibes tu sueldo.',
        'Empieza con el 5% si es lo máximo que puedes ahora — el hábito tiene más valor que el monto inicial.',
        'Dirige la transferencia a una cuenta diferente a la de gastos diarios; idealmente en otro banco para que sea menos accesible.',
        'Nubank, Mercado Pago y Hey Banco permiten configurar depósitos automáticos y "bóvedas" por meta desde la app.',
        'Incrementa el porcentaje un 1% cada 3 meses hasta llegar al 20% de tu ingreso neto.',
      ],
    ),
    FinancialTip(
      id: 't6',
      title: 'Presupuesto de gastos hormiga',
      content:
          'Un café de \$5 diario son \$1,825 al año. Identifica tus gastos pequeños recurrentes y evalúa cuáles valen la pena.',
      category: TipCategory.budgeting,
      steps: [
        'Durante 7 días consecutivos anota cada gasto menor a \$100: café, agua, snacks, propinas, apps.',
        'Al final de la semana súmalos y multiplica por 4 para ver el impacto mensual — la cifra suele sorprender.',
        'Clasifica cada gasto: ¿es placer real o solo un hábito automático? Conserva los primeros, elimina los segundos.',
        'Preparar café en casa 4 de 5 días puede ahorrarte más de \$800–1,200 al mes dependiendo de tu consumo actual.',
        'Lleva una botella de agua y snacks desde casa para eliminar compras de impulso durante el día.',
      ],
    ),
    FinancialTip(
      id: 't7',
      title: 'Invierte en ti mismo',
      content:
          'Aprender una nueva habilidad puede multiplicar tus ingresos más que cualquier inversión financiera. Tu mayor activo eres tú.',
      category: TipCategory.mindset,
      steps: [
        'Identifica una habilidad con alta demanda: programación, diseño UX, marketing digital, ventas, inglés avanzado, análisis de datos.',
        'Plataformas gratuitas o con auditoría gratis: Coursera (coursera.org), edX (edx.org), Khan Academy, YouTube con canales especializados.',
        'Plataformas de pago asequibles: Udemy (cursos desde \$9 en ofertas frecuentes), Platzi (plan mensual), LinkedIn Learning (primer mes gratis).',
        'Dedica 30 minutos diarios — son más de 180 horas al año, suficiente para dominar una habilidad básica.',
        'Documenta lo aprendido en LinkedIn o un portafolio público (GitHub, Behance) para monetizarlo con empleadores o clientes.',
      ],
    ),
    FinancialTip(
      id: 't8',
      title: 'Diversificación',
      content:
          'No pongas todos los huevos en una sola canasta. Diversifica entre diferentes tipos de activos para reducir riesgo.',
      category: TipCategory.investing,
      steps: [
        'Nunca concentres más del 20–25% de tu portafolio en un solo activo, empresa o instrumento.',
        'Estructura básica: 40% liquidez/ahorro, 40% renta fija (CETES, bonos) y 20% renta variable (ETFs de índices globales).',
        'En México puedes comprar ETFs del S&P 500 y mercados globales desde GBM+ o Bursanet desde \$500.',
        'Revisa y rebalancea tu portafolio cada 6 meses: si un activo creció demasiado, vende parte y redistribuye.',
        'A mayor plazo de inversión, mayor porcentaje puedes tener en renta variable; a menor plazo, prioriza instrumentos de bajo riesgo.',
      ],
    ),
    FinancialTip(
      id: 't9',
      title: 'Revisa tus suscripciones',
      content:
          'Una vez al mes revisa qué suscripciones tienes activas. Es común pagar por servicios que ya no usas.',
      category: TipCategory.habits,
      steps: [
        'Abre tu estado de cuenta bancario del último mes y marca cada cobro recurrente — incluyendo los anuales.',
        'Crea una lista con nombre del servicio, costo mensual y última vez que lo usaste activamente.',
        'Cancela de inmediato cualquier servicio que no hayas usado en los últimos 30 días.',
        'Para servicios de streaming que usas poco, alterna: suscríbete un mes, cancela, toma un descanso de 2–3 meses.',
        'Comparte cuentas familiares o de amigos donde sea posible: Spotify Familia, Netflix, Apple One y YouTube Premium tienen planes compartidos.',
      ],
    ),
    FinancialTip(
      id: 't10',
      title: 'Espera 24 horas',
      content:
          'Antes de una compra impulsiva, espera 24 horas. El 80% de las veces ya no querrás comprarlo.',
      category: TipCategory.mindset,
      steps: [
        'Cuando quieras comprar algo no planeado, agrégalo al carrito o lista de deseos pero no compres todavía.',
        'Escribe en papel o en notas: "quiero comprar X porque Y". Ver la razón escrita ayuda a evaluarla objetivamente.',
        'Para compras menores a \$500, espera 24 horas. Para compras mayores, aplica la regla de 72 horas mínimo.',
        'Si al día siguiente ya no recuerdas el artículo sin revisar la lista, no era una necesidad real.',
        'Desactiva las notificaciones push de tiendas, apps de compras y correos de oferta — el 90% son estímulos de compra artificial.',
      ],
    ),
    FinancialTip(
      id: 't11',
      title: 'Negocia tus tarifas',
      content:
          'Llama a tus proveedores (internet, seguro, celular) y pide una tarifa mejor. Funciona más del 50% de las veces.',
      category: TipCategory.saving,
      steps: [
        'Investiga las ofertas actuales de la competencia antes de llamar — esa información es tu palanca de negociación.',
        'Llama específicamente al área de "retención" o "cancelaciones", no al soporte general — tienen más autoridad para dar descuentos.',
        'Menciona que llevas X años como cliente leal y que encontraste una oferta mejor en otro proveedor.',
        'Pide concretamente: descuento en la mensualidad, meses gratis, mejora de plan sin costo adicional o cancelación de cargos.',
        'Servicios más negociables: internet, seguro de auto, plan celular, streaming y servicios médicos privados.',
      ],
    ),
    FinancialTip(
      id: 't12',
      title: 'El método avalancha',
      content:
          'Para pagar deudas, ordénalas de mayor a menor interés y ataca la más costosa primero. Ahorras más en intereses.',
      category: TipCategory.debt,
      steps: [
        'Lista todas tus deudas con: nombre del acreedor, saldo actual, tasa de interés anual y pago mínimo mensual.',
        'Paga el mínimo en todas las deudas sin excepción para evitar cargos por mora.',
        'Canaliza todo el dinero extra disponible a la deuda con mayor tasa de interés, sin importar el saldo.',
        'Cuando esa deuda se liquida, suma su pago mensual al de la siguiente deuda más cara — el "alud" crece cada vez.',
        'Usa Debt Payoff Planner (app gratuita) o una hoja de cálculo para visualizar cuánto ahorras en intereses vs. pagar mínimos.',
      ],
    ),
    FinancialTip(
      id: 't13',
      title: 'Esconde dinero de ti mismo',
      content:
          'Si eres olvidadizo, deja pequeñas cantidades en lugares inusuales del hogar — el cajón del fondo, dentro de un libro, en un bolsillo viejo. Cuando el dinero apriete, esos "descubrimientos" pueden salvarte el día.',
      category: TipCategory.saving,
      steps: [
        'Abre una segunda cuenta de ahorro que no esté en tu app principal del día a día — en otro banco si es posible.',
        'Transfiere ahí una cantidad fija cada quincena y no instales la app de esa cuenta en tu celular.',
        'Las "cuentas objetivo" o "bóvedas" de Nubank, BBVA y Mercado Pago permiten ocultar el saldo de la vista principal.',
        'En efectivo: dobla un billete dentro de la cubierta de tu teléfono o en el bolsillo de una chamarra de temporada.',
        'El mecanismo funciona porque agrega fricción al gasto — necesitar un paso extra te hace pensarlo dos veces.',
      ],
    ),
    FinancialTip(
      id: 't14',
      title: 'Cuentas con rendimiento',
      content:
          'Muchos bancos digitales (Nubank, Mercado Pago, BBVA) ofrecen rendimientos del 8–15% anual sobre tu saldo diario. Abrir una de estas cuentas es gratuito y tu dinero trabaja mientras duermes.',
      category: TipCategory.investing,
      steps: [
        'Abre una cuenta en Nubank, Mercado Pago, Hey Banco o BBVA Digital — todas son gratuitas y se abren en minutos desde el celular.',
        'Mueve ahí tu fondo de emergencia y el ahorro que no necesites de inmediato para que genere rendimiento.',
        'Compara tasas actuales en comparatibanco.com.mx o condusef.gob.mx antes de decidir cuál usar.',
        'No uses estas cuentas para gastos diarios — dejar el saldo intocado maximiza el rendimiento compuesto.',
        'Revisa la tasa cada 3–6 meses; el mercado cambia y puede aparecer una opción más competitiva.',
      ],
    ),
    FinancialTip(
      id: 't15',
      title: 'Paga primero, gasta después',
      content:
          'Antes de gastar un solo peso del sueldo, transfiere tu ahorro meta. No es lo que queda al final; es lo primero que sale. Así el ahorro deja de ser opcional.',
      category: TipCategory.habits,
      steps: [
        'Define tu porcentaje de ahorro antes del próximo cobro: mínimo 10%, objetivo ideal 20%.',
        'El día que recibas tu sueldo, transfiere ese monto a tu cuenta de ahorro antes de hacer cualquier otro pago o gasto.',
        'Usa el saldo restante como tu "ingreso disponible real" para todo lo demás — renta, comida, entretenimiento.',
        'Si el dinero no alcanza para los gastos necesarios, reduce gastos variables (salidas, ropa) — el ahorro es intocable.',
        'Configura la transferencia como automática para que el banco lo haga sin que necesites decidirlo cada quincena.',
      ],
    ),
    FinancialTip(
      id: 't16',
      title: 'La trampa de las "pequeñas deudas"',
      content:
          'Una deuda de \$200 al 40% anual se convierte en \$280 en un año sin pagarla. Las deudas pequeñas con alto interés crecen rápido. Liquídalas antes que las grandes con interés bajo.',
      category: TipCategory.debt,
      steps: [
        'Identifica todas las deudas pequeñas activas: préstamos a amigos/familia, cuotas pendientes, compras a plazos olvidadas.',
        'Calcula el interés mensual que estás pagando en cada una — aunque parezca poco, en tasa anual suele ser muy alto.',
        'Liquida primero las de mayor tasa aunque el saldo sea pequeño; el alivio de eliminar una deuda también tiene valor psicológico.',
        'Evita los servicios de "compra ahora, paga después" (Klarna, Kueski, Aplazo) mientras tengas deudas activas.',
        'Cada deuda liquidada libera flujo mensual real — redirige ese monto directamente al siguiente objetivo financiero.',
      ],
    ),
    FinancialTip(
      id: 't17',
      title: 'Compara antes de renovar',
      content:
          'Cuando venza tu seguro, internet o plan celular, busca 3 cotizaciones antes de renovar. La lealtad raramente es recompensada; el mejor precio casi siempre se consigue cambiando o amenazando con hacerlo.',
      category: TipCategory.saving,
      steps: [
        'Agenda un recordatorio 30 días antes de que venza cualquier contrato de servicio (seguro, internet, celular).',
        'Busca y documenta al menos 3 cotizaciones de competidores antes de llamar a renovar.',
        'Llama al área de retención de tu proveedor actual con las cotizaciones en mano y pide que igualen o mejoren la oferta.',
        'Frase efectiva: "He sido cliente X años, pero encontré [oferta concreta] en [competidor]. ¿Qué pueden ofrecerme?".',
        'Si no consigues descuento significativo, cambia de proveedor — los nuevos clientes siempre reciben mejores condiciones.',
      ],
    ),
    FinancialTip(
      id: 't18',
      title: 'El precio por uso',
      content:
          'Antes de comprar algo costoso, divide el precio entre las veces que lo usarás. Una chaqueta de \$300 que usas 100 veces cuesta \$3 por uso; una de \$80 que usas 5 veces, \$16. El costo real no es el precio de etiqueta.',
      category: TipCategory.mindset,
      steps: [
        'Antes de cualquier compra mayor a \$500, estima cuántas veces realmente lo usarás en el próximo año.',
        'Divide el precio entre esas veces — si el costo por uso supera los \$50–100, reconsidera si vale la pena.',
        'Para artículos de uso esporádico (herramientas, equipamiento deportivo, trajes), evalúa rentar o pedir prestado.',
        'En ropa y calzado: invierte en menos prendas pero de mayor durabilidad — el costo por uso de calidad es siempre menor.',
        'Aplica el mismo criterio a gadgets y electrodomésticos: ¿lo usarás lo suficiente para justificar el precio?',
      ],
    ),
    FinancialTip(
      id: 't19',
      title: 'El sobre de los sobres',
      content:
          'Divide tu efectivo en sobres etiquetados: "Mercado", "Transporte", "Salidas", "Imprevistos". Cuando un sobre se vacía, ese gasto se acabó por el mes. Es el sistema más concreto para no pasarte del presupuesto sin usar ninguna app.',
      category: TipCategory.budgeting,
      steps: [
        'Retira en efectivo el dinero para gastos variables al inicio de cada quincena o mes.',
        'Prepara sobres etiquetados con categorías y montos específicos: Mercado \$X, Transporte \$X, Salidas \$X, Imprevistos \$X.',
        'Cuando un sobre se vacía, ese presupuesto se acabó — regla estricta: no se transfiere dinero de un sobre a otro.',
        'Si eres digital, usa las "categorías de presupuesto" o "bóvedas" de tu app bancaria con el mismo principio.',
        'El truco clave: el dolor psicológico de entregar efectivo físico reduce el gasto impulsivo entre 15–30% vs. pagar con tarjeta.',
      ],
    ),
    FinancialTip(
      id: 't20',
      title: 'La caja de los imprevistos',
      content:
          'Pon una caja o lata en casa y cada semana deposita una cantidad fija —aunque sea pequeña—. No la toques salvo emergencias reales: arreglos del hogar, gastos médicos, problemas con el auto. Tener este colchón evita que los imprevistos arruinen tu presupuesto mensual.',
      category: TipCategory.saving,
      steps: [
        'Consigue una caja, lata o alcancía física — que sea visible en tu hogar para recordarte depositar.',
        'Define una cantidad fija semanal aunque sea pequeña: \$50–200 según tu capacidad actual.',
        'Deposita cada domingo sin excepción — el hábito constante importa más que el monto.',
        'Establece una regla clara sobre cuándo se puede usar: solo imprevistos no planeados reales (médico, arreglo del coche, urgencia del hogar).',
        'Cuando la caja llegue a \$3,000–5,000, transfiere el excedente a una cuenta de ahorro con rendimiento y vuelve a empezar.',
      ],
    ),
    FinancialTip(
      id: 't21',
      title: 'Lista antes de ir al super',
      content:
          'Escribe exactamente lo que necesitas antes de ir al supermercado y comprométete a no comprar nada fuera de la lista. Estudios muestran que ir sin lista aumenta el gasto entre 20 y 40%. También ayuda: no ir con hambre y evitar los pasillos centrales donde están los productos más caros.',
      category: TipCategory.habits,
      steps: [
        'Planifica los menús de la semana antes de ir al super — así sabes exactamente qué ingredientes necesitas.',
        'Escribe la lista organizada por sección del supermercado (frutas, lácteos, carnes, limpieza) para no vagar entre pasillos.',
        'Revisa el refrigerador y la despensa antes de salir para no comprar duplicados de lo que ya tienes.',
        'Come algo antes de ir — el hambre puede aumentar el gasto hasta un 30% por compras impulsivas.',
        'Compara precio por gramo o por mililitro entre marcas y tamaños; el empaque grande no siempre es más económico por unidad.',
      ],
    ),
    FinancialTip(
      id: 't22',
      title: 'Cocina en lotes los domingos',
      content:
          'Dedica 2 horas el domingo a preparar comidas para varios días. Cocinar en lotes reduce el gasto en comida a domicilio y restaurantes, que suele ser el segundo mayor rubro de gastos innecesarios. Una semana de almuerzos preparados en casa puede ahorrarte el equivalente a un día de sueldo.',
      category: TipCategory.saving,
      steps: [
        'Elige 2–3 recetas sencillas y económicas que aguanten varios días: arroz con pollo, pasta, guisos, sopas.',
        'Compra los ingredientes al inicio de la semana — los mercados locales y tiendas mayoristas son significativamente más baratos que el súper.',
        'Dedica 2 horas el domingo: cocina, porciona en contenedores individuales y etiqueta con el día que se consumirá.',
        'Un almuerzo en restaurante o a domicilio cuesta \$120–250; preparado en casa cuesta \$25–50 por porción.',
        'Congela las porciones de miércoles en adelante para mantener frescura y evitar desperdicio de alimentos.',
      ],
    ),
    FinancialTip(
      id: 't23',
      title: 'Revisa el estado de cuenta en voz alta',
      content:
          'Una vez al mes, abre tu estado de cuenta bancario y lee cada cargo en voz alta. La oralidad activa una parte del cerebro distinta a la visual y te hace notar cobros duplicados, suscripciones olvidadas y cargos incorrectos que por escrito pasarían desapercibidos.',
      category: TipCategory.habits,
      steps: [
        'Descarga el PDF completo del estado de cuenta desde tu banca en línea — no solo revises la app, que a veces agrupa cargos.',
        'Lee cada cargo en voz alta y pregúntate: "¿recuerdo haber hecho esto y por este monto?".',
        'Marca todos los cargos que no reconoces o que te parecen incorrectos y llama a tu banco para disputarlos.',
        'Busca cargos con nombres similares a servicios legítimos pero no idénticos — es una táctica común de fraude.',
        'Crea en Vexa una categoría "cobros no reconocidos" para darles seguimiento hasta resolverlos.',
      ],
    ),
    FinancialTip(
      id: 't24',
      title: 'La regla de las 72 horas para compras grandes',
      content:
          'Cualquier compra mayor a tu "umbral personal" (define el tuyo: puede ser \$500 o \$2,000) debe esperar 72 horas. Escribe en un papel qué quieres comprar y por qué. Si al tercer día todavía lo quieres y puedes pagarlo sin sacrificar ahorro, adelante. La mayoría de las veces el impulso se disipa.',
      category: TipCategory.mindset,
      steps: [
        'Define ahora tu "umbral personal": la cantidad a partir de la cual una compra no planeada debe esperar 72 horas.',
        'Cuando quieras comprar algo por encima de ese umbral, escríbelo con fecha en una lista de deseos física o digital.',
        'Espera exactamente 72 horas sin revisar ni pensar activamente en el artículo.',
        'Al tercer día revisa la lista: ¿sigues queriendo el artículo con la misma intensidad? ¿Puedes comprarlo sin afectar el ahorro?',
        'Si la respuesta a ambas preguntas es sí, es una compra justificada. En la mayoría de los casos, el impulso ya habrá disminuido.',
      ],
    ),
    FinancialTip(
      id: 't25',
      title: 'Negocia tus servicios cada año',
      content:
          'Internet, seguro de auto, telefonía y servicios de streaming suelen tener tarifas negociables. Llama una vez al año, menciona que estás considerando cambiar de proveedor y pide su "mejor oferta de retención". Funciona en más del 60% de los casos y puede ahorrarte varios cientos al año con 15 minutos de llamada.',
      category: TipCategory.saving,
      steps: [
        'Crea recordatorios anuales para cada servicio: internet, celular, seguro de auto, servicios de salud privados.',
        'Un mes antes del vencimiento, investiga planes actuales de la competencia y documenta las mejores ofertas.',
        'Llama al área de "cancelaciones" o "retención" — no al soporte general — y presenta las ofertas que encontraste.',
        'Usa esta frase: "Llevo X años con ustedes y encontré [oferta específica] en [competidor]. ¿Qué pueden hacer para retenerme?".',
        'Si no ofrecen nada competitivo, cancela y migra — los nuevos clientes reciben siempre mejores condiciones.',
      ],
    ),
    FinancialTip(
      id: 't26',
      title: 'El frasco de metas visibles',
      content:
          'Coloca un frasco o recipiente transparente en un lugar visible de tu hogar para cada meta de ahorro importante. Deposita dinero físicamente cuando puedas y observa cómo crece. Ver el progreso de forma tangible es uno de los motivadores más efectivos para mantener el hábito de ahorro.',
      category: TipCategory.saving,
      steps: [
        'Identifica tu meta de ahorro más importante: vacaciones, fondo de emergencia, gadget, curso o entrada de un coche.',
        'Coloca un frasco o contenedor transparente etiquetado con el nombre de la meta en un lugar muy visible de tu hogar.',
        'Pega en el frasco un papel con el monto total que necesitas y la fecha objetivo.',
        'Deposita dinero físico regularmente — aunque sean monedas; el ritual de depositar refuerza el hábito.',
        'Para el grueso del ahorro, usa una bóveda digital en tu banco; el frasco es el recordatorio visual diario que te mantiene motivado.',
      ],
    ),
    FinancialTip(
      id: 't27',
      title: 'Apaga lo que no usas: la factura eléctrica',
      content:
          'Revisa qué aparatos quedan en standby en tu casa (televisores, cargadores, routers de habitaciones sin uso). Desconectarlos puede reducir entre 5 y 15% tu factura eléctrica mensual. Pequeño esfuerzo, ahorro constante que se acumula todo el año.',
      category: TipCategory.habits,
      steps: [
        'Recorre tu casa e identifica todos los aparatos en standby: televisores, consolas, cargadores, routers secundarios, microondas.',
        'Conecta el entretenimiento (TV, consola, bocina) a una regleta con interruptor — apágala toda de un solo switch al salir.',
        'Desconecta los cargadores de celular y laptop cuando no estén en uso activo — en standby consumen energía constantemente.',
        'Reemplaza focos incandescentes o de halógeno por LEDs — consumen hasta 80% menos energía con la misma iluminación.',
        'Reporta fugas de agua inmediatamente — un grifo goteando desperdicia hasta 30 litros diarios y puede subir tu factura de agua.',
      ],
    ),
    FinancialTip(
      id: 't28',
      title: 'Compra genérico donde importa poco',
      content:
          'En medicamentos de venta libre, limpieza del hogar y muchos alimentos básicos, la versión genérica o de marca blanca tiene la misma fórmula que la de marca. Sustituirlos puede reducir tu gasto en supermercado entre un 15 y 25% sin ninguna pérdida real de calidad.',
      category: TipCategory.budgeting,
      steps: [
        'Medicamentos donde el genérico es idéntico: paracetamol, ibuprofeno, loratadina, sales de rehidratación, vitamina C básica.',
        'Limpieza del hogar: cloro, desengrasante multiusos, detergente para ropa, lava trastes — la fórmula activa es la misma en todas las marcas.',
        'Alimentos básicos sin diferencia real: azúcar, sal, arroz blanco, harina, aceite vegetal, leche UHT, pastas.',
        'Dónde sí vale invertir en marca: calzado de uso diario (la calidad dura más), herramientas de uso frecuente, colchón.',
        'Regla práctica: si el ingrediente activo es idéntico en la etiqueta de información, el genérico es la decisión correcta.',
      ],
    ),
    FinancialTip(
      id: 't29',
      title: 'El diario de gastos de una semana',
      content:
          'Durante siete días consecutivos, anota cada peso que gastas: café, transporte, propinas, todo. No juzgues, solo registra. Al final de la semana tendrás una radiografía honesta de tus hábitos reales. La mayoría descubre entre 1 y 3 categorías donde gasta el doble de lo que creía.',
      category: TipCategory.budgeting,
      steps: [
        'Usa Vexa o la app de notas de tu celular — lo importante es registrar en el momento, no reconstruirlo al final del día.',
        'Durante 7 días anota cada gasto inmediatamente después de hacerlo, sin importar el monto: \$5, \$12, lo que sea.',
        'Al final de cada día suma los gastos y asígnales una categoría: comida, transporte, entretenimiento, trabajo, etc.',
        'Al séptimo día suma por categoría y compáralo con lo que estimabas gastar — identifica la categoría que más te sorprende.',
        'Con esa información, establece un límite mensual realista para esa categoría y revisa el cumplimiento cada semana.',
      ],
    ),
    FinancialTip(
      id: 't30',
      title: 'Vende lo que no usas cada trimestre',
      content:
          'Cada tres meses recorre tu casa y separa ropa, electrónica, libros y objetos que no has usado en 6 meses. Véndelos en plataformas de segunda mano. Además del ingreso extra, reduces el desorden (que psicológicamente incentiva más compras) y te acostumbras a valorar lo que ya tienes.',
      category: TipCategory.mindset,
      steps: [
        'Agenda un "día de limpieza" cada 3 meses — elige un área específica: clóset, cajones, bodega o electrónica.',
        'Regla de los 6 meses: si no lo usaste en medio año, probablemente no lo usarás — véndelo, dónalo o deséchalos.',
        'Plataformas para vender en México: Facebook Marketplace, Mercado Libre (cero costo de publicación en muchas categorías), grupos de Telegram locales.',
        'Para electrónica en buen estado: Back Market, eBay y grupos especializados de Facebook pueden dar mejores precios.',
        'El dinero obtenido va directamente a ahorro o a liquidar una deuda — no lo reutilices para comprar más cosas.',
      ],
    ),
    FinancialTip(
      id: 't31',
      title: 'Automatiza el ahorro el día de cobro',
      content:
          'Configura una transferencia automática hacia tu cuenta de ahorro o inversión para que ocurra el mismo día en que recibes tu sueldo. El monto que "nunca ves" nunca se gasta. Incluso el 5% de tu ingreso automatizado produce más ahorro real que intentar guardar "lo que sobre" al final del mes.',
      category: TipCategory.habits,
      steps: [
        'Entra a tu banca en línea y configura una transferencia programada para el mismo día de tu nómina.',
        'Monto mínimo: 5% de tu ingreso neto. Meta a 6 meses: 15–20%.',
        'Dirige la transferencia a una cuenta separada — idealmente en un banco diferente para reducir la tentación de usarla.',
        'Nubank, Hey Banco y Mercado Pago permiten configurar transferencias automáticas y "bóvedas" por meta directamente desde la app.',
        'Trata ese dinero como si no existiera — no lo incluyas en tus cálculos de dinero disponible para el mes.',
      ],
    ),
    FinancialTip(
      id: 't32',
      title: 'Usa efectivo para gastos discrecionales',
      content:
          'Retira en efectivo el dinero destinado a gastos no esenciales (salidas, ropa, entretenimiento) y úsalo exclusivamente para eso. El dolor psicológico de entregar billetes físicos frena el gasto impulsivo mucho más que pagar con tarjeta. Cuando se acaba el efectivo, se acabó ese presupuesto.',
      category: TipCategory.budgeting,
      steps: [
        'Al inicio de cada semana retira en efectivo el monto asignado para gastos no esenciales del presupuesto.',
        'Usa ese efectivo exclusivamente para salidas, entretenimiento, ropa y antojos — nada más.',
        'Cuando el efectivo se acaba, el presupuesto discrecional de esa semana terminó — sin excepciones ni transferencias.',
        'Para compras no esenciales en línea, transfiere primero el monto desde tu "presupuesto discrecional" — crea fricción intencional.',
        'Durante el primer mes, observa qué día de la semana te quedas sin efectivo — eso revela exactamente cuánto necesitas ajustar.',
      ],
    ),
  ];

  static FinancialTip get daily {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return all[dayOfYear % all.length];
  }
}
