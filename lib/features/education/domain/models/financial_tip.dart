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
  });

  final String id;
  final String title;
  final String content;
  final TipCategory category;
}

abstract final class FinancialTips {
  static const List<FinancialTip> all = [
    // ── Tips clásicos ──────────────────────────────────────────────────────────
    FinancialTip(
      id: 't1',
      title: 'La regla 50/30/20',
      content:
          'Destina el 50% de tus ingresos a necesidades, el 30% a deseos y el 20% al ahorro. Es la base de una buena salud financiera.',
      category: TipCategory.budgeting,
    ),
    FinancialTip(
      id: 't2',
      title: 'Fondo de emergencia',
      content:
          'Antes de invertir, asegúrate de tener entre 3 y 6 meses de gastos en una cuenta de ahorro fácilmente accesible.',
      category: TipCategory.saving,
    ),
    FinancialTip(
      id: 't3',
      title: 'El poder del interés compuesto',
      content:
          'Invertir \$100 al mes durante 30 años al 8% anual te da más de \$150,000. Empieza hoy, aunque sea poco.',
      category: TipCategory.investing,
    ),
    FinancialTip(
      id: 't4',
      title: 'Elimina deuda de alto interés',
      content:
          'Pagar una tarjeta con 20% de interés es equivalente a una inversión garantizada del 20%. Prioriza liquidarla.',
      category: TipCategory.debt,
    ),
    FinancialTip(
      id: 't5',
      title: 'Automatiza tu ahorro',
      content:
          'Configura una transferencia automática el día de cobro. Lo que no ves, no lo gastas.',
      category: TipCategory.habits,
    ),
    FinancialTip(
      id: 't6',
      title: 'Presupuesto de gastos hormiga',
      content:
          'Un café de \$5 diario son \$1,825 al año. Identifica tus gastos pequeños recurrentes y evalúa cuáles valen la pena.',
      category: TipCategory.budgeting,
    ),
    FinancialTip(
      id: 't7',
      title: 'Invierte en ti mismo',
      content:
          'Aprender una nueva habilidad puede multiplicar tus ingresos más que cualquier inversión financiera. Tu mayor activo eres tú.',
      category: TipCategory.mindset,
    ),
    FinancialTip(
      id: 't8',
      title: 'Diversificación',
      content:
          'No pongas todos los huevos en una sola canasta. Diversifica entre diferentes tipos de activos para reducir riesgo.',
      category: TipCategory.investing,
    ),
    FinancialTip(
      id: 't9',
      title: 'Revisa tus suscripciones',
      content:
          'Una vez al mes revisa qué suscripciones tienes activas. Es común pagar por servicios que ya no usas.',
      category: TipCategory.habits,
    ),
    FinancialTip(
      id: 't10',
      title: 'Espera 24 horas',
      content:
          'Antes de una compra impulsiva, espera 24 horas. El 80% de las veces ya no querrás comprarlo.',
      category: TipCategory.mindset,
    ),
    FinancialTip(
      id: 't11',
      title: 'Negocia tus tarifas',
      content:
          'Llama a tus proveedores (internet, seguro, celular) y pide una tarifa mejor. Funciona más del 50% de las veces.',
      category: TipCategory.saving,
    ),
    FinancialTip(
      id: 't12',
      title: 'El método avalancha',
      content:
          'Para pagar deudas, ordénalas de mayor a menor interés y ataca la más costosa primero. Ahorras más en intereses.',
      category: TipCategory.debt,
    ),
    FinancialTip(
      id: 't13',
      title: 'Esconde dinero de ti mismo',
      content:
          'Si eres olvidadizo, deja pequeñas cantidades en lugares inusuales del hogar — el cajón del fondo, dentro de un libro, en un bolsillo viejo. Cuando el dinero apriete, esos "descubrimientos" pueden salvarte el día.',
      category: TipCategory.saving,
    ),
    FinancialTip(
      id: 't14',
      title: 'Cuentas con rendimiento',
      content:
          'Muchos bancos digitales (Nubank, Mercado Pago, BBVA) ofrecen rendimientos del 8–15% anual sobre tu saldo diario. Abrir una de estas cuentas es gratuito y tu dinero trabaja mientras duermes.',
      category: TipCategory.investing,
    ),
    FinancialTip(
      id: 't15',
      title: 'Paga primero, gasta después',
      content:
          'Antes de gastar un solo peso del sueldo, transfiere tu ahorro meta. No es lo que queda al final; es lo primero que sale. Así el ahorro deja de ser opcional.',
      category: TipCategory.habits,
    ),
    FinancialTip(
      id: 't16',
      title: 'La trampa de las "pequeñas deudas"',
      content:
          'Una deuda de \$200 al 40% anual se convierte en \$280 en un año sin pagarla. Las deudas pequeñas con alto interés crecen rápido. Liquídalas antes que las grandes con interés bajo.',
      category: TipCategory.debt,
    ),
    FinancialTip(
      id: 't17',
      title: 'Compara antes de renovar',
      content:
          'Cuando venza tu seguro, internet o plan celular, busca 3 cotizaciones antes de renovar. La lealtad raramente es recompensada; el mejor precio casi siempre se consigue cambiando o amenazando con hacerlo.',
      category: TipCategory.saving,
    ),
    FinancialTip(
      id: 't18',
      title: 'El precio por uso',
      content:
          'Antes de comprar algo costoso, divide el precio entre las veces que lo usarás. Una chaqueta de \$300 que usas 100 veces cuesta \$3 por uso; una de \$80 que usas 5 veces, \$16. El costo real no es el precio de etiqueta.',
      category: TipCategory.mindset,
    ),
    // ── Consejos prácticos del hogar ───────────────────────────────────────────
    FinancialTip(
      id: 't19',
      title: 'El sobre de los sobres',
      content:
          'Divide tu efectivo en sobres etiquetados: "Mercado", "Transporte", "Salidas", "Imprevistos". Cuando un sobre se vacía, ese gasto se acabó por el mes. Es el sistema más concreto para no pasarte del presupuesto sin usar ninguna app.',
      category: TipCategory.budgeting,
    ),
    FinancialTip(
      id: 't20',
      title: 'La caja de los imprevistos',
      content:
          'Pon una caja o lata en casa y cada semana deposita una cantidad fija —aunque sea pequeña—. No la toques salvo emergencias reales: arreglos del hogar, gastos médicos, problemas con el auto. Tener este colchón evita que los imprevistos arruinen tu presupuesto mensual.',
      category: TipCategory.saving,
    ),
    FinancialTip(
      id: 't21',
      title: 'Lista antes de ir al super',
      content:
          'Escribe exactamente lo que necesitas antes de ir al supermercado y comprométete a no comprar nada fuera de la lista. Estudios muestran que ir sin lista aumenta el gasto entre 20 y 40%. También ayuda: no ir con hambre y evitar los pasillos centrales donde están los productos más caros.',
      category: TipCategory.habits,
    ),
    FinancialTip(
      id: 't22',
      title: 'Cocina en lotes los domingos',
      content:
          'Dedica 2 horas el domingo a preparar comidas para varios días. Cocinar en lotes reduce el gasto en comida a domicilio y restaurantes, que suele ser el segundo mayor rubro de gastos innecesarios. Una semana de almuerzos preparados en casa puede ahorrarte el equivalente a un día de sueldo.',
      category: TipCategory.saving,
    ),
    FinancialTip(
      id: 't23',
      title: 'Revisa el estado de cuenta en voz alta',
      content:
          'Una vez al mes, abre tu estado de cuenta bancario y lee cada cargo en voz alta. La oralidad activa una parte del cerebro distinta a la visual y te hace notar cobros duplicados, suscripciones olvidadas y cargos incorrectos que por escrito pasarían desapercibidos.',
      category: TipCategory.habits,
    ),
    FinancialTip(
      id: 't24',
      title: 'La regla de las 72 horas para compras grandes',
      content:
          'Cualquier compra mayor a tu "umbral personal" (define el tuyo: puede ser \$500 o \$2,000) debe esperar 72 horas. Escribe en un papel qué quieres comprar y por qué. Si al tercer día todavía lo quieres y puedes pagarlo sin sacrificar ahorro, adelante. La mayoría de las veces el impulso se disipa.',
      category: TipCategory.mindset,
    ),
    FinancialTip(
      id: 't25',
      title: 'Negocia tus servicios cada año',
      content:
          'Internet, seguro de auto, telefonía y servicios de streaming suelen tener tarifas negociables. Llama una vez al año, menciona que estás considerando cambiar de proveedor y pide su "mejor oferta de retención". Funciona en más del 60% de los casos y puede ahorrarte varios cientos al año con 15 minutos de llamada.',
      category: TipCategory.saving,
    ),
    FinancialTip(
      id: 't26',
      title: 'El frasco de metas visibles',
      content:
          'Coloca un frasco o recipiente transparente en un lugar visible de tu hogar para cada meta de ahorro importante. Deposita dinero físicamente cuando puedas y observa cómo crece. Ver el progreso de forma tangible es uno de los motivadores más efectivos para mantener el hábito de ahorro.',
      category: TipCategory.saving,
    ),
    FinancialTip(
      id: 't27',
      title: 'Apaga lo que no usas: la factura eléctrica',
      content:
          'Revisa qué aparatos quedan en standby en tu casa (televisores, cargadores, routers de habitaciones sin uso). Desconectarlos puede reducir entre 5 y 15% tu factura eléctrica mensual. Pequeño esfuerzo, ahorro constante que se acumula todo el año.',
      category: TipCategory.habits,
    ),
    FinancialTip(
      id: 't28',
      title: 'Compra genérico donde importa poco',
      content:
          'En medicamentos de venta libre, limpieza del hogar y muchos alimentos básicos, la versión genérica o de marca blanca tiene la misma fórmula que la de marca. Sustituirlos puede reducir tu gasto en supermercado entre un 15 y 25% sin ninguna pérdida real de calidad.',
      category: TipCategory.budgeting,
    ),
    FinancialTip(
      id: 't29',
      title: 'El diario de gastos de una semana',
      content:
          'Durante siete días consecutivos, anota cada peso que gastas: café, transporte, propinas, todo. No juzgues, solo registra. Al final de la semana tendrás una radiografía honesta de tus hábitos reales. La mayoría descubre entre 1 y 3 categorías donde gasta el doble de lo que creía.',
      category: TipCategory.budgeting,
    ),
    FinancialTip(
      id: 't30',
      title: 'Vende lo que no usas cada trimestre',
      content:
          'Cada tres meses recorre tu casa y separa ropa, electrónica, libros y objetos que no has usado en 6 meses. Véndelos en plataformas de segunda mano. Además del ingreso extra, reduces el desorden (que psicológicamente incentiva más compras) y te acostumbras a valorar lo que ya tienes.',
      category: TipCategory.mindset,
    ),
    FinancialTip(
      id: 't31',
      title: 'Automatiza el ahorro el día de cobro',
      content:
          'Configura una transferencia automática hacia tu cuenta de ahorro o inversión para que ocurra el mismo día en que recibes tu sueldo. El monto que "nunca ves" nunca se gasta. Incluso el 5% de tu ingreso automatizado produce más ahorro real que intentar guardar "lo que sobre" al final del mes.',
      category: TipCategory.habits,
    ),
    FinancialTip(
      id: 't32',
      title: 'Usa efectivo para gastos discrecionales',
      content:
          'Retira en efectivo el dinero destinado a gastos no esenciales (salidas, ropa, entretenimiento) y úsalo exclusivamente para eso. El dolor psicológico de entregar billetes físicos frena el gasto impulsivo mucho más que pagar con tarjeta. Cuando se acaba el efectivo, se acabó ese presupuesto.',
      category: TipCategory.budgeting,
    ),
  ];

  static FinancialTip get daily {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return all[dayOfYear % all.length];
  }
}
