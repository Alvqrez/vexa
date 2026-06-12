import 'package:flutter/material.dart';

enum HomeSection {
  balanceCard,
  accounts,
  summaryCards,
  budgets,
  balanceChart,
  projection,
  insights,
  tip,
  categories,
  transactions,
}

extension HomeSectionX on HomeSection {
  String get label => switch (this) {
        HomeSection.balanceCard => 'Balance total',
        HomeSection.accounts => 'Mis cuentas',
        HomeSection.summaryCards => 'Ingresos / Gastos',
        HomeSection.budgets => 'Presupuestos',
        HomeSection.balanceChart => 'Gráfica de balance',
        HomeSection.projection => 'Proyección financiera',
        HomeSection.insights => 'Insights inteligentes',
        HomeSection.tip => 'Consejo del día',
        HomeSection.categories => 'Categorías',
        HomeSection.transactions => 'Transacciones recientes',
      };

  IconData get icon => switch (this) {
        HomeSection.balanceCard => Icons.account_balance_wallet_rounded,
        HomeSection.accounts => Icons.credit_card_rounded,
        HomeSection.summaryCards => Icons.swap_vert_rounded,
        HomeSection.budgets => Icons.pie_chart_rounded,
        HomeSection.balanceChart => Icons.show_chart_rounded,
        HomeSection.projection => Icons.trending_up_rounded,
        HomeSection.insights => Icons.lightbulb_outline_rounded,
        HomeSection.tip => Icons.school_rounded,
        HomeSection.categories => Icons.grid_view_rounded,
        HomeSection.transactions => Icons.list_alt_rounded,
      };
}

class HomeSectionEntry {
  const HomeSectionEntry({required this.section, required this.visible});

  final HomeSection section;
  final bool visible;

  HomeSectionEntry copyWith({bool? visible}) =>
      HomeSectionEntry(section: section, visible: visible ?? this.visible);

  Map<String, dynamic> toJson() =>
      {'section': section.name, 'visible': visible};

  factory HomeSectionEntry.fromJson(Map<String, dynamic> json) {
    final section = HomeSection.values.firstWhere(
      (s) => s.name == json['section'],
      orElse: () => HomeSection.transactions,
    );
    return HomeSectionEntry(
      section: section,
      visible: json['visible'] as bool? ?? true,
    );
  }
}

class HomeConfig {
  const HomeConfig({required this.sections});

  final List<HomeSectionEntry> sections;

  // balanceChart ON by default; projection OFF by default (too noisy for new users)
  static const defaultConfig = HomeConfig(sections: [
    HomeSectionEntry(section: HomeSection.balanceCard, visible: true),
    HomeSectionEntry(section: HomeSection.summaryCards, visible: true),
    HomeSectionEntry(section: HomeSection.balanceChart, visible: true),
    HomeSectionEntry(section: HomeSection.insights, visible: true),
    HomeSectionEntry(section: HomeSection.tip, visible: true),
    HomeSectionEntry(section: HomeSection.accounts, visible: true),
    HomeSectionEntry(section: HomeSection.budgets, visible: true),
    HomeSectionEntry(section: HomeSection.projection, visible: false),
    HomeSectionEntry(section: HomeSection.transactions, visible: true),
  ]);

  List<HomeSectionEntry> get visibleSections =>
      sections.where((e) => e.visible).toList();

  HomeConfig copyWithEntry(HomeSectionEntry updated) => HomeConfig(
        sections: sections
            .map((e) => e.section == updated.section ? updated : e)
            .toList(),
      );

  // newIndex is already adjusted by ReorderableListView.onReorderItem
  HomeConfig reordered(int oldIndex, int newIndex) {
    final list = List<HomeSectionEntry>.from(sections);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    return HomeConfig(sections: list);
  }

  Map<String, dynamic> toJson() => {
        'sections': sections.map((e) => e.toJson()).toList(),
      };

  factory HomeConfig.fromJson(Map<String, dynamic> json) {
    var list = (json['sections'] as List)
        .map((e) => HomeSectionEntry.fromJson(e as Map<String, dynamic>))
        // Migration: categories section removed from home screen.
        .where((e) => e.section != HomeSection.categories)
        .toList();
    // Forward compatibility: append any sections added in a newer version.
    for (final def in HomeConfig.defaultConfig.sections) {
      if (!list.any((e) => e.section == def.section)) {
        list.add(def);
      }
    }
    return HomeConfig(sections: list);
  }
}
