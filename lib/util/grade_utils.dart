/// Utility functions for climbing grade conversions, comparisons, and sorting.
library;

/// Converts climbing grades (French sport / V-scale) to approximate US / Ewbank equivalents.
String formatSubgrade(String grade) {
  final clean = grade.trim().toLowerCase();
  switch (clean) {
    case '5a':
      return '5.8 YDS • 16 Ewbank';
    case '5b':
      return '5.9 YDS • 17 Ewbank';
    case '5c':
      return '5.10a YDS • 18 Ewbank';
    case '6a':
      return '5.10a YDS • 18 Ewbank';
    case '6a+':
      return '5.10b YDS • 19 Ewbank';
    case '6b':
      return '5.10c YDS • 20 Ewbank';
    case '6b+':
      return '5.10d YDS • 21 Ewbank';
    case '6c':
      return '5.11a YDS • 22 Ewbank';
    case '6c+':
      return '5.11c YDS • 23 Ewbank';
    case '7a':
      return '5.11d YDS • 24 Ewbank';
    case '7a+':
      return '5.12a YDS • 25 Ewbank';
    case '7b':
      return '5.12b YDS • 26 Ewbank';
    case '7b+':
      return '5.12c YDS • 27 Ewbank';
    case '7c':
      return '5.12d YDS • 28 Ewbank';
    case '7c+':
      return '5.13a YDS • 29 Ewbank';
    case '8a':
      return '5.13b YDS • 30 Ewbank';
    case '8a+':
      return '5.13c YDS • 31 Ewbank';
    case '8b':
      return '5.13d YDS • 32 Ewbank';
    case 'v0':
      return 'VB–V0 • 4–5 Font';
    case 'v1':
      return '5+ Font • 5.10';
    case 'v2':
      return '6a Font • 5.11';
    case 'v3':
      return '6a+ Font • 5.11+';
    case 'v4':
      return '6b Font • 5.12-';
    case 'v5':
      return '6c Font • 5.12';
    case 'v6':
      return '7a Font • 5.12+';
    case 'v7':
      return '7a+ Font • 5.13-';
    default:
      return '$grade Equivalent';
  }
}

/// Helper converting a grade string into a comparable numeric score for sorting.
int gradeToScore(String grade) {
  final clean = grade.trim().toLowerCase();
  const gradeRank = {
    '4': 10,
    '5a': 20,
    '5b': 25,
    '5c': 30,
    '6a': 40,
    '6a+': 45,
    '6b': 50,
    '6b+': 55,
    '6c': 60,
    '6c+': 65,
    '7a': 70,
    '7a+': 75,
    '7b': 80,
    '7b+': 85,
    '7c': 90,
    '7c+': 95,
    '8a': 100,
    '8a+': 105,
    '8b': 110,
    '8b+': 115,
    '8c': 120,
    'v0': 20,
    'v1': 30,
    'v2': 40,
    'v3': 50,
    'v4': 60,
    'v5': 70,
    'v6': 80,
    'v7': 90,
    'v8': 100,
  };
  return gradeRank[clean] ?? 50;
}
