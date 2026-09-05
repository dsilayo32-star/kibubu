import 'savings_entry.dart';

class Goal {
  Goal({
    required this.name,
    required this.target,
    required this.saved,
    this.image = '🎯',
    this.start,
    this.end,
    this.lastSavedAt,
    this.lastPenaltyAt,
    this.completed = false,
    List<SavingsEntry>? history,
  }) : history = history ?? [];

  final String name;
  final double target;
  double saved;
  final String image;
  final DateTime? start;
  final DateTime? end;
  DateTime? lastSavedAt;
  DateTime? lastPenaltyAt;
  bool completed;
  final List<SavingsEntry> history;

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0);
  double get remaining => (target - saved).clamp(0.0, double.infinity);

  Map<String, dynamic> toMap() => {
    'name': name,
    'target': target,
    'saved': saved,
    'image': image,
    'start': start?.toIso8601String(),
    'end': end?.toIso8601String(),
    'lastSavedAt': lastSavedAt?.toIso8601String(),
    'lastPenaltyAt': lastPenaltyAt?.toIso8601String(),
    'completed': completed,
    'history': history.map((entry) => entry.toMap()).toList(),
  };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
    name: map['name'] as String? ?? '',
    target: (map['target'] as num?)?.toDouble() ?? 0,
    saved: (map['saved'] as num?)?.toDouble() ?? 0,
    image: map['image'] as String? ?? '🎯',
    start: _parseDate(map['start']),
    end: _parseDate(map['end']),
    lastSavedAt: _parseDate(map['lastSavedAt']),
    lastPenaltyAt: _parseDate(map['lastPenaltyAt']),
    completed: map['completed'] as bool? ?? false,
    history: (map['history'] as List<dynamic>? ?? [])
        .map(
          (entry) =>
              SavingsEntry.fromMap(Map<String, dynamic>.from(entry as Map)),
        )
        .toList(),
  );

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
