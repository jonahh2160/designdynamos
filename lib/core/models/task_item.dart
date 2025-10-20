import 'package:flutter/material.dart';
import 'tag_info.dart';

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    //required this.icon,
    required this.points,
    required this.isDone,
    this.notes,
    this.startDate,
    this.dueDate,
    this.priority = 5,//5 by default cause why not
    this.orderHint = 1000,
  });

  final String id;
  final String title;
  //final IconData icon;
  final int points;
  final bool isDone;
  final String? notes;
  final DateTime? startDate;
  final DateTime? dueDate;
  final int priority;
  final int orderHint;

  factory TaskItem.fromMap(Map<String, dynamic> m) => TaskItem( 
      id: m['id'] as String,
      title: m['title'] as String,
      //icon: m['icon'] as IconData,
      points: (m['points'] ?? 10) as int,
      isDone: (m['isDone'] ?? false) as bool,
      notes: m['notes'] as String?,
      startDate: m['startDate'] != null ? DateTime.parse(m['startDate']) : null,
      dueDate: m['dueDate'] != null ? DateTime.parse(m['dueDate']) : null,
      priority: (m['priority'] ?? 5) is int ? m['priority'] : int.tryParse(m['priority'] ?? '5') ?? 5,
      orderHint: (m['orderHint'] ?? 1000) as int,
  );

  Map<String, dynamic> toInsert() => {
    'title': title,
    'notes': notes,
    'start_date': startDate?.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'points': points,
    'priority': priority,
    'orderHint': orderHint,
  };

  TaskItem copyWith({bool? isDone}) =>
      TaskItem(
        id: id,
        title: title,
        //icon: icon,
        points: points,
        isDone: isDone ?? this.isDone,
        notes: notes,
        startDate: startDate,
        dueDate: dueDate,
        priority: priority,
        orderHint: orderHint,
      );
}