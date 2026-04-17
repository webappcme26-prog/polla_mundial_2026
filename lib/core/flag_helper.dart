class FlagHelper {
  static String getFlagEmoji(String teamName) {
    const flags = {
      'México': '🇲🇽',
      'Sudáfrica': '🇿🇦',
      'Corea del Sur': '🇰🇷',
      'República Checa': '🇨🇿',
      'Canadá': '🇨🇦',
      'Bosnia y Herzegovina': '🇧🇦',
      'Estados Unidos': '🇺🇸',
      'Paraguay': '🇵🇾',
      'Catar': '🇶🇦',
      'Suiza': '🇨🇭',
      'Brasil': '🇧🇷',
      'Marruecos': '🇲🇦',
      'Haití': '🇭🇹',
      'Escocia': '🏴',
      'Australia': '🇦🇺',
      'Turquía': '🇹🇷',
    };

    return flags[teamName] ?? '🏳️';
  }
}