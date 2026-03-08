import 'package:flutter/material.dart';

enum WeightStatus {
  veryLow,    // < -3SD (Red)
  low,        // -3SD to -2SD (Orange)
  warning,    // -2SD to -1SD (Light Green)
  normal,     // -1SD to +2SD (Clear Green)
  high,       // > +2SD (Purple)
}

class GrowthCalculator {
  // WHO Growth Standards for Boys (kg) - Birth to 24 months
  static final Map<int, Map<String, double>> whoStandardsBoys = {
    0:  { '-3SD': 2.1, '-2SD': 2.5, '-1SD': 2.9, 'median': 3.3, '+1SD': 3.9, '+2SD': 4.4, '+3SD': 5.0 },
    1:  { '-3SD': 2.9, '-2SD': 3.4, '-1SD': 3.9, 'median': 4.5, '+1SD': 5.1, '+2SD': 5.8, '+3SD': 6.6 },
    2:  { '-3SD': 3.8, '-2SD': 4.3, '-1SD': 4.9, 'median': 5.6, '+1SD': 6.3, '+2SD': 7.1, '+3SD': 8.0 },
    3:  { '-3SD': 4.4, '-2SD': 5.0, '-1SD': 5.7, 'median': 6.4, '+1SD': 7.2, '+2SD': 8.0, '+3SD': 9.0 },
    4:  { '-3SD': 4.9, '-2SD': 5.6, '-1SD': 6.2, 'median': 7.0, '+1SD': 7.8, '+2SD': 8.7, '+3SD': 9.7 },
    5:  { '-3SD': 5.3, '-2SD': 6.0, '-1SD': 6.7, 'median': 7.5, '+1SD': 8.4, '+2SD': 9.3, '+3SD': 10.4 },
    6:  { '-3SD': 5.7, '-2SD': 6.4, '-1SD': 7.1, 'median': 7.9, '+1SD': 8.8, '+2SD': 9.8, '+3SD': 10.9 },
    7:  { '-3SD': 6.0, '-2SD': 6.7, '-1SD': 7.4, 'median': 8.3, '+1SD': 9.2, '+2SD': 10.3, '+3SD': 11.4 },
    8:  { '-3SD': 6.2, '-2SD': 6.9, '-1SD': 7.7, 'median': 8.6, '+1SD': 9.6, '+2SD': 10.7, '+3SD': 11.9 },
    9:  { '-3SD': 6.4, '-2SD': 7.1, '-1SD': 7.9, 'median': 8.9, '+1SD': 9.9, '+2SD': 11.0, '+3SD': 12.3 },
    10: { '-3SD': 6.6, '-2SD': 7.4, '-1SD': 8.2, 'median': 9.2, '+1SD': 10.2, '+2SD': 11.4, '+3SD': 12.7 },
    11: { '-3SD': 6.8, '-2SD': 7.6, '-1SD': 8.4, 'median': 9.4, '+1SD': 10.5, '+2SD': 11.7, '+3SD': 13.0 },
    12: { '-3SD': 6.9, '-2SD': 7.7, '-1SD': 8.6, 'median': 9.6, '+1SD': 10.8, '+2SD': 12.0, '+3SD': 13.3 },
    13: { '-3SD': 7.1, '-2SD': 7.9, '-1SD': 8.8, 'median': 9.9, '+1SD': 11.0, '+2SD': 12.3, '+3SD': 13.7 },
    14: { '-3SD': 7.2, '-2SD': 8.1, '-1SD': 9.0, 'median': 10.1, '+1SD': 11.3, '+2SD': 12.6, '+3SD': 14.0 },
    15: { '-3SD': 7.4, '-2SD': 8.3, '-1SD': 9.2, 'median': 10.3, '+1SD': 11.5, '+2SD': 12.8, '+3SD': 14.3 },
    16: { '-3SD': 7.5, '-2SD': 8.4, '-1SD': 9.4, 'median': 10.5, '+1SD': 11.7, '+2SD': 13.1, '+3SD': 14.6 },
    17: { '-3SD': 7.7, '-2SD': 8.6, '-1SD': 9.6, 'median': 10.7, '+1SD': 12.0, '+2SD': 13.4, '+3SD': 14.9 },
    18: { '-3SD': 7.8, '-2SD': 8.8, '-1SD': 9.8, 'median': 10.9, '+1SD': 12.2, '+2SD': 13.7, '+3SD': 15.3 },
    19: { '-3SD': 8.0, '-2SD': 8.9, '-1SD': 10.0, 'median': 11.1, '+1SD': 12.5, '+2SD': 14.0, '+3SD': 15.6 },
    20: { '-3SD': 8.1, '-2SD': 9.1, '-1SD': 10.1, 'median': 11.3, '+1SD': 12.7, '+2SD': 14.3, '+3SD': 15.9 },
    21: { '-3SD': 8.2, '-2SD': 9.2, '-1SD': 10.3, 'median': 11.5, '+1SD': 12.9, '+2SD': 14.5, '+3SD': 16.2 },
    22: { '-3SD': 8.4, '-2SD': 9.4, '-1SD': 10.5, 'median': 11.8, '+1SD': 13.2, '+2SD': 14.8, '+3SD': 16.5 },
    23: { '-3SD': 8.5, '-2SD': 9.5, '-1SD': 10.7, 'median': 12.0, '+1SD': 13.4, '+2SD': 15.0, '+3SD': 16.8 },
    24: { '-3SD': 8.6, '-2SD': 9.7, '-1SD': 10.8, 'median': 12.2, '+1SD': 13.6, '+2SD': 15.3, '+3SD': 17.1 },
  };

  // WHO Growth Standards for Girls (kg)
  static final Map<int, Map<String, double>> whoStandardsGirls = {
    0:  { '-3SD': 2.0, '-2SD': 2.4, '-1SD': 2.8, 'median': 3.2, '+1SD': 3.7, '+2SD': 4.2, '+3SD': 4.8 },
    1:  { '-3SD': 2.7, '-2SD': 3.2, '-1SD': 3.6, 'median': 4.2, '+1SD': 4.8, '+2SD': 5.5, '+3SD': 6.2 },
    2:  { '-3SD': 3.4, '-2SD': 3.9, '-1SD': 4.5, 'median': 5.1, '+1SD': 5.8, '+2SD': 6.6, '+3SD': 7.5 },
    3:  { '-3SD': 4.0, '-2SD': 4.5, '-1SD': 5.2, 'median': 5.8, '+1SD': 6.6, '+2SD': 7.5, '+3SD': 8.5 },
    4:  { '-3SD': 4.4, '-2SD': 5.0, '-1SD': 5.7, 'median': 6.4, '+1SD': 7.3, '+2SD': 8.2, '+3SD': 9.3 },
    5:  { '-3SD': 4.8, '-2SD': 5.4, '-1SD': 6.1, 'median': 6.9, '+1SD': 7.8, '+2SD': 8.8, '+3SD': 10.0 },
    6:  { '-3SD': 5.1, '-2SD': 5.7, '-1SD': 6.5, 'median': 7.3, '+1SD': 8.2, '+2SD': 9.3, '+3SD': 10.6 },
    7:  { '-3SD': 5.3, '-2SD': 6.0, '-1SD': 6.8, 'median': 7.6, '+1SD': 8.6, '+2SD': 9.8, '+3SD': 11.1 },
    8:  { '-3SD': 5.6, '-2SD': 6.3, '-1SD': 7.0, 'median': 7.9, '+1SD': 9.0, '+2SD': 10.2, '+3SD': 11.6 },
    9:  { '-3SD': 5.8, '-2SD': 6.5, '-1SD': 7.3, 'median': 8.2, '+1SD': 9.3, '+2SD': 10.5, '+3SD': 12.0 },
    10: { '-3SD': 5.9, '-2SD': 6.7, '-1SD': 7.5, 'median': 8.5, '+1SD': 9.6, '+2SD': 10.9, '+3SD': 12.4 },
    11: { '-3SD': 6.1, '-2SD': 6.9, '-1SD': 7.7, 'median': 8.7, '+1SD': 9.9, '+2SD': 11.2, '+3SD': 12.8 },
    12: { '-3SD': 6.3, '-2SD': 7.0, '-1SD': 7.9, 'median': 8.9, '+1SD': 10.1, '+2SD': 11.5, '+3SD': 13.1 },
    // Continue for 13-24 months as needed
  };

  static Map<int, Map<String, double>> _getStandards(String gender) {
    return gender.toLowerCase() == 'boy' ? whoStandardsBoys : whoStandardsGirls;
  }

  static WeightStatus calculateWeightStatus(double weight, int ageInMonths, String gender) {
    final standards = _getStandards(gender);
    
    if (!standards.containsKey(ageInMonths)) {
      return WeightStatus.normal;
    }

    final ageStandards = standards[ageInMonths]!;
    
    if (weight < ageStandards['-3SD']!) {
      return WeightStatus.veryLow;
    } else if (weight < ageStandards['-2SD']!) {
      return WeightStatus.low;
    } else if (weight < ageStandards['-1SD']!) {
      return WeightStatus.warning;
    } else if (weight <= ageStandards['+2SD']!) {
      return WeightStatus.normal;
    } else {
      return WeightStatus.high;
    }
  }

  static Color getStatusColor(WeightStatus status) {
    switch (status) {
      case WeightStatus.veryLow:
        return Colors.red;
      case WeightStatus.low:
        return Colors.orange;
      case WeightStatus.warning:
        return Colors.lightGreen;
      case WeightStatus.normal:
        return Colors.green;
      case WeightStatus.high:
        return Colors.purple;
    }
  }

  static String getStatusMessage(WeightStatus status, bool isSinhala) {
    switch (status) {
      case WeightStatus.veryLow:
        return isSinhala ? 'ඉතා අඩු බර' : 'Very Low Weight';
      case WeightStatus.low:
        return isSinhala ? 'අඩු බර' : 'Low Weight';
      case WeightStatus.warning:
        return isSinhala ? 'අවධානය යොමු කළ යුතුයි' : 'At Risk';
      case WeightStatus.normal:
        return isSinhala ? 'සාමාන්‍ය බර' : 'Normal Weight';
      case WeightStatus.high:
        return isSinhala ? 'අධික බර' : 'High Weight';
    }
  }

  static String getStatusSinhala(WeightStatus status) {
    return getStatusMessage(status, true);
  }

  static String getStatusEnglish(WeightStatus status) {
    return getStatusMessage(status, false);
  }
}