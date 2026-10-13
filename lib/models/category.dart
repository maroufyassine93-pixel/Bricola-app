import 'package:flutter/material.dart';

/// A trade (مهنة) with Arabic + French labels.
class TradeInfo {
  final String id;
  final String ar;
  final String fr;
  final IconData icon;

  const TradeInfo({
    required this.id,
    required this.ar,
    required this.fr,
    required this.icon,
  });

  String get label => '$ar / $fr';
}

/// A category group (مجموعة مهن) shown as a big image button on Home.
class CategoryGroup {
  final String id;
  final String titleAr;
  final IconData icon;
  final Color color;
  final List<TradeInfo> trades;

  const CategoryGroup({
    required this.id,
    required this.titleAr,
    required this.icon,
    required this.color,
    required this.trades,
  });
}

/// Static catalogue of the 4 groups + 22 trades. Arabic-first, French alongside.
class Categories {
  Categories._();

  static const List<CategoryGroup> groups = [
    CategoryGroup(
      id: 'construction',
      titleAr: 'أعمال البناء والصيانة',
      icon: Icons.home_repair_service,
      color: Color(0xFF0E7C4A),
      trades: [
        TradeInfo(id: 'electricien', ar: 'كهربائي', fr: 'Électricien', icon: Icons.electrical_services),
        TradeInfo(id: 'plombier', ar: 'بلومبي', fr: 'Plombier', icon: Icons.plumbing),
        TradeInfo(id: 'peintre', ar: 'طلاء', fr: 'Peintre', icon: Icons.format_paint),
        TradeInfo(id: 'carreleur', ar: 'فايونص', fr: 'Carreleur', icon: Icons.grid_on),
        TradeInfo(id: 'ferronnier', ar: 'حداد', fr: 'Ferronnier', icon: Icons.hardware),
        TradeInfo(id: 'menuisier', ar: 'نجار', fr: 'Menuisier', icon: Icons.handyman),
        TradeInfo(id: 'macon', ar: 'بنّاء', fr: 'Maçon', icon: Icons.foundation),
        TradeInfo(id: 'aluminium', ar: 'ألمنيوم وزجاج', fr: 'Aluminium & Vitrerie', icon: Icons.window),
        TradeInfo(id: 'isolation', ar: 'متخصص في العزل', fr: 'Isolation', icon: Icons.layers),
        TradeInfo(id: 'nettoyage', ar: 'خدمات منزلية وتنظيف', fr: 'Nettoyage', icon: Icons.cleaning_services),
      ],
    ),
    CategoryGroup(
      id: 'appliances',
      titleAr: 'إصلاح الأجهزة المنزلية',
      icon: Icons.kitchen,
      color: Color(0xFF1565C0),
      trades: [
        TradeInfo(id: 'lave_linge', ar: 'تصليح الغسالات', fr: 'Lave-linge', icon: Icons.local_laundry_service),
        TradeInfo(id: 'frigo', ar: 'تصليح الثلاجات', fr: 'Réfrigérateur', icon: Icons.kitchen),
        TradeInfo(id: 'climatiseur', ar: 'تصليح المكيفات', fr: 'Climatiseur', icon: Icons.ac_unit),
        TradeInfo(id: 'chauffe_eau', ar: 'تصليح السخانات', fr: 'Chauffe-eau', icon: Icons.hot_tub),
        TradeInfo(id: 'four', ar: 'تصليح الأفران', fr: 'Four', icon: Icons.microwave),
        TradeInfo(id: 'micro_onde', ar: 'تصليح الميكروويف', fr: 'Micro-ondes', icon: Icons.microwave_outlined),
      ],
    ),
    CategoryGroup(
      id: 'tech',
      titleAr: 'الخدمات التكنولوجية',
      icon: Icons.devices,
      color: Color(0xFF6A1B9A),
      trades: [
        TradeInfo(id: 'smartphone', ar: 'إصلاح الهواتف الذكية', fr: 'Smartphones', icon: Icons.smartphone),
        TradeInfo(id: 'informatique', ar: 'الحواسب والطابعات', fr: 'Informatique & Imprimantes', icon: Icons.computer),
        TradeInfo(id: 'cameras', ar: 'تركيب كاميرات المراقبة', fr: 'Caméras de surveillance', icon: Icons.videocam),
        TradeInfo(id: 'domotique', ar: 'البيوت الذكية', fr: 'Domotique', icon: Icons.home_work),
      ],
    ),
    CategoryGroup(
      id: 'auto',
      titleAr: 'صيانة السيارات',
      icon: Icons.directions_car,
      color: Color(0xFFE65100),
      trades: [
        TradeInfo(id: 'electricien_auto', ar: 'كهربائي السيارات', fr: 'Électricien auto', icon: Icons.bolt),
        TradeInfo(id: 'mecanicien_mobile', ar: 'ميكانيكي السيارات المتنقل', fr: 'Mécanicien auto mobile', icon: Icons.car_repair),
      ],
    ),
  ];

  /// Find a trade by id across all groups.
  static TradeInfo? tradeById(String id) {
    for (final g in groups) {
      for (final t in g.trades) {
        if (t.id == id) return t;
      }
    }
    return null;
  }

  static CategoryGroup? groupById(String id) {
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }
}
