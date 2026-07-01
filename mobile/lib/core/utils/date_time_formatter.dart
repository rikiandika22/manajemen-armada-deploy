import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DateTimeFormatter {
  static const String locale = 'id_ID';

  static String formatIndonesianDate(DateTime date) {
    return DateFormat('d MMMM yyyy', locale).format(date);
  }

  static String formatIndonesianShortDate(DateTime date) {
    return DateFormat('dd MMM yyyy', locale).format(date);
  }

  static String formatIndonesianDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy, HH.mm', locale).format(date) + ' WIB';
  }

  static String formatIndonesianTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')} WIB';
  }

  static String formatBackendDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatBackendTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }
}
