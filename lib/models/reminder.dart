import 'package:flutter/material.dart';

enum ReminderCategory {
  personal,
  financial,
  healthcare,
  cultural,
  birthday,
  anniversary,
  invitation,
  shopping,
  medicine,
  school,
}

enum ReminderRecurrence {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

enum AlertOffset {
  atTime,
  fifteenMin,
  oneHour,
  oneDay,
}

extension ReminderCategoryLabel on ReminderCategory {
  String get label {
    switch (this) {
      case ReminderCategory.personal:
        return 'व्यक्तिगत';
      case ReminderCategory.financial:
        return 'आर्थिक';
      case ReminderCategory.healthcare:
        return 'स्वास्थ्य';
      case ReminderCategory.cultural:
        return 'सांस्कृतिक';
      case ReminderCategory.birthday:
        return 'जन्मदिन';
      case ReminderCategory.anniversary:
        return 'वार्षिकोत्सव';
      case ReminderCategory.invitation:
        return 'निमन्त्रणा';
      case ReminderCategory.shopping:
        return 'किनमेल';
      case ReminderCategory.medicine:
        return 'औषधि';
      case ReminderCategory.school:
        return 'विद्यालय';
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderCategory.personal:
        return Icons.person_outline_rounded;
      case ReminderCategory.financial:
        return Icons.account_balance_wallet_outlined;
      case ReminderCategory.healthcare:
        return Icons.favorite_outline_rounded;
      case ReminderCategory.cultural:
        return Icons.celebration_outlined;
      case ReminderCategory.birthday:
        return Icons.cake_outlined;
      case ReminderCategory.anniversary:
        return Icons.favorite_border_rounded;
      case ReminderCategory.invitation:
        return Icons.mail_outline_rounded;
      case ReminderCategory.shopping:
        return Icons.shopping_bag_outlined;
      case ReminderCategory.medicine:
        return Icons.medication_outlined;
      case ReminderCategory.school:
        return Icons.school_outlined;
    }
  }
}

extension ReminderRecurrenceLabel on ReminderRecurrence {
  String get label {
    switch (this) {
      case ReminderRecurrence.none:
        return 'एक पटक';
      case ReminderRecurrence.daily:
        return 'दैनिक';
      case ReminderRecurrence.weekly:
        return 'साप्ताहिक';
      case ReminderRecurrence.monthly:
        return 'मासिक';
      case ReminderRecurrence.yearly:
        return 'वार्षिक';
    }
  }
}

extension AlertOffsetLabel on AlertOffset {
  String get label {
    switch (this) {
      case AlertOffset.atTime:
        return 'समयमा';
      case AlertOffset.fifteenMin:
        return '१५ मिनेट अगाडि';
      case AlertOffset.oneHour:
        return '१ घण्टा अगाडि';
      case AlertOffset.oneDay:
        return '१ दिन अगाडि';
    }
  }
}

class Reminder {
  final String id;
  final String title;
  final String description;
  final int bsYear;
  final int bsMonth;
  final int bsDay;
  final int hour;
  final int minute;
  final ReminderCategory category;
  final ReminderRecurrence recurrence;
  final AlertOffset alertOffset;
  final bool isEnabled;

  const Reminder({
    required this.id,
    required this.title,
    this.description = '',
    required this.bsYear,
    required this.bsMonth,
    required this.bsDay,
    required this.hour,
    required this.minute,
    this.category = ReminderCategory.personal,
    this.recurrence = ReminderRecurrence.none,
    this.alertOffset = AlertOffset.atTime,
    this.isEnabled = true,
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  String get timeLabel {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    int? bsYear,
    int? bsMonth,
    int? bsDay,
    int? hour,
    int? minute,
    ReminderCategory? category,
    ReminderRecurrence? recurrence,
    AlertOffset? alertOffset,
    bool? isEnabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      bsYear: bsYear ?? this.bsYear,
      bsMonth: bsMonth ?? this.bsMonth,
      bsDay: bsDay ?? this.bsDay,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      alertOffset: alertOffset ?? this.alertOffset,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'bsYear': bsYear,
        'bsMonth': bsMonth,
        'bsDay': bsDay,
        'hour': hour,
        'minute': minute,
        'category': category.index,
        'recurrence': recurrence.index,
        'alertOffset': alertOffset.index,
        'isEnabled': isEnabled,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      bsYear: json['bsYear'] as int,
      bsMonth: json['bsMonth'] as int,
      bsDay: json['bsDay'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      category: ReminderCategory.values[json['category'] as int? ?? 0],
      recurrence: ReminderRecurrence.values[json['recurrence'] as int? ?? 0],
      alertOffset: AlertOffset.values[json['alertOffset'] as int? ?? 0],
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }
}
