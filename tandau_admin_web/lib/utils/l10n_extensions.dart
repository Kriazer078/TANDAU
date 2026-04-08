import '../l10n/app_localizations.dart';

extension AppLocalizationsExt on AppLocalizations? {
  String get filterEducationType {
    if (this?.localeName == 'ru') return 'Тип обучения';
    if (this?.localeName == 'kk') return 'Оқу түрі';
    return 'Education Type';
  }

  String get filterGrant {
    if (this?.localeName == 'ru') return 'Грант';
    if (this?.localeName == 'kk') return 'Грант';
    return 'Grant';
  }

  String get filterPaid {
    if (this?.localeName == 'ru') return 'Платное';
    if (this?.localeName == 'kk') return 'Ақылы';
    return 'Paid';
  }

  String get filterMaxPrice {
    if (this?.localeName == 'ru') return 'Макс. цена (в год)';
    if (this?.localeName == 'kk') return 'Макс. баға (жылына)';
    return 'Max Price (per year)';
  }

  String get filterPricePerYear {
    if (this?.localeName == 'ru') return 'Цена за год';
    if (this?.localeName == 'kk') return 'Жылдық баға';
    return 'Price per year';
  }
}
