import 'package:flutter/foundation.dart';

import 'package:designdynamos/core/models/task_draft.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/models/db_subtask.dart';
import 'package:designdynamos/data/services/task_service.dart';
import 'package:designdynamos/data/services/subtask_service.dart';
import 'package:designdynamos/data/services/label_service.dart';
import 'dart:math' as math;

class TaskProvider extends ChangeNotifier {
  TaskProvider(this._service, {SubtaskService? subtasks, LabelService? labels})
    : _subtaskService = subtasks ?? SubtaskService(_service.client),
      _labelService = labels ?? LabelService(_service.client);

  final TaskService _service;
  final SubtaskService _subtaskService;
  final LabelService _labelService;

  bool _loading = false;
  bool _creating = false;
  List<TaskItem> _today = [];
  List<TaskItem> _allTasks = [];
  String? _selectedTaskId;
  final Map<String, List<DbSubtask>> _subtasksByTask = {};
  final Map<String, String?> _notesByTask = {};
  final Map<String, Set<String>> _labelsByTask = {};

  //Daily filters/state
  DateTime _day = DateTime.now();
  bool _includeOverdue = true;
  bool _includeSpanning = true;
  bool _sortByEstimate = false;
  List<TaskItem> get unassignedTasks =>
      List.unmodifiable(_today.where((task) => task.goalStepId == null));

  bool get isLoading => _loading;
  bool get isCreating => _creating;
  List<TaskItem> get today => List.unmodifiable(_today);
  List<TaskItem> get allTasks => List.unmodifiable(_allTasks); //get all tasks
  DateTime get day => _day;
  bool get includeOverdue => _includeOverdue;
  bool get includeSpanning => _includeSpanning;
  bool get sortByEstimate => _sortByEstimate;
  List<DbSubtask> subtasksOf(String taskId) =>
      List.unmodifiable(_subtasksByTask[taskId] ?? const []);
  (int done, int total) subtaskProgress(String taskId) {
    final list = _subtasksByTask[taskId] ?? const [];
    final total = list.length;
    final done = list.where((s) => s.isDone).length;
    return (done, total); //tuple of done and total
  }

  String? noteOf(String taskId) => _notesByTask[taskId];
  Set<String> labelsOf(String taskId) => _labelsByTask[taskId] ?? {};

  TaskItem? get selectedTask {
    if (_selectedTaskId == null) return null;
    for (final task in _today) {
      if (task.id == _selectedTaskId) return task;
    }
    return null;
  }

  Future<void> refreshDaily({
    DateTime? day,
    bool? includeOverdue,
    bool? includeSpanning,
  }) async {
    if (day != null) _day = DateTime(day.year, day.month, day.day);
    if (includeOverdue != null) _includeOverdue = includeOverdue;
    if (includeSpanning != null) _includeSpanning = includeSpanning;

    _loading = true;
    notifyListeners();

    try {
      final tasks = await _service.getDailyTasks(
        _day,
        includeOverdue: _includeOverdue,
        includeSpanning: _includeSpanning,
      );
      _today = tasks;
      // Keep the all-tasks cache current so overdue widgets stay fresh.
      _allTasks = await _service.getAllTasks();
      _sortToday();

      if (_today.isEmpty) {
        _selectedTaskId = null;
      } else if (_selectedTaskId == null ||
          !_today.any((t) => t.id == _selectedTaskId)) {
        _selectedTaskId = _today.first.id;
      }
      final sel = _selectedTaskId;
      if (sel != null) {
        await _loadDetails(sel);
      }
    } catch (error, stack) {
      debugPrint('refreshDaily failed: $error');
      debugPrint('$stack');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<TaskItem> get overdueTasks {
    final now = DateTime.now();
    return _allTasks
        .where(
          (t) =>
              !t.isDone &&
              t.dueAt != null &&
              t.dueAt!.toLocal().isBefore(now),
        )
        .toList()
      ..sort((a, b) => a.dueAt!.toLocal().compareTo(b.dueAt!.toLocal()));
  }

  /// Suggested tasks for today (and near-term) using a local heuristic.
  List<SuggestedTask> get suggestedTasks {
    return _buildSuggestions();
  }

  Future<void> refreshAllTasks() async {
    _loading = true;
    notifyListeners();

    try {
      final tasks = await _service.getAllTasks();
      _allTasks = tasks;
    } finally {
      _loading = false;
      notifyListeners();
    }
  } 



  Future<void> refreshToday() => refreshDaily(day: DateTime.now());

  void setSortByEstimate(bool enabled) {
    if (_sortByEstimate == enabled) return;
    _sortByEstimate = enabled;
    _sortToday();
    notifyListeners();
  }

  void selectTask(String? id) {
    if (_selectedTaskId == id) return;
    _selectedTaskId = id;
    notifyListeners();
    if (id != null) {
      //Fire and forget detail load
      _loadDetails(id);
    }
  }

  Future<void> createTask(TaskDraft draft) async {
    if (_creating) return;

    final nextOrderHint = _today.isEmpty
        ? 1000
        : (_today.last.orderHint + 1000);
    final tempId = 'tmp-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    final fallbackStart = draft.startAt ?? now;
    final fallbackDue = draft.dueAt ?? _defaultDueAt(fallbackStart);
    final fallbackTarget = draft.targetAt ?? fallbackDue;
    final tempTask = draft.toTask(
      id: tempId,
      orderHint: nextOrderHint,
      fallbackStartAt: fallbackStart,
      fallbackDueAt: fallbackDue,
      fallbackTargetAt: fallbackTarget,
    );

    _creating = true;
    _today = [..._today, tempTask];
    _sortToday();
    _selectedTaskId = tempTask.id;
    notifyListeners();

    try {
      final created = await _service.createTask(tempTask);
      _today = _today
          .map((task) => task.id == tempId ? created : task)
          .toList();
      _sortToday();
      _selectedTaskId = created.id;

      // Update _allTasks
      final allIndex = _allTasks.indexWhere((t) => t.id == tempId);
      if (allIndex >= 0) {
        _allTasks[allIndex] = created;
        } else {
        _allTasks.add(created);
      }

      //Optional: notes
      if (draft.notes != null && draft.notes!.trim().isNotEmpty) {
        await _service.upsertNote(created.id, draft.notes);
        _notesByTask[created.id] = draft.notes;
      }

      //Optional: subtasks
      if (draft.subtasks.isNotEmpty) {
        int hint = 0;
        final items = <DbSubtask>[];
        for (final title in draft.subtasks) {
          hint += 1000;
          final sub = await _subtaskService.create(
            created.id,
            title,
            orderHint: hint,
          );
          items.add(sub);
        }
        _subtasksByTask[created.id] = items;
      }

      //Optional: labels
      if (draft.labels.isNotEmpty) {
        for (final name in draft.labels) {
          await _labelService.toggleTaskLabel(created.id, name, true);
        }
        _labelsByTask[created.id] = {...draft.labels};
      }
    } catch (error) {
      _today = _today.where((task) => task.id != tempId).toList();
      rethrow;
    } finally {
      _creating = false;
      notifyListeners();
    }
  }


  Future<void> toggleDone(String id, bool done) async {
    final index = _today.indexWhere((task) => task.id == id);
    if (index < 0) return;

    final before = _today[index];
    final updated = before.copyWith(
      isDone: done,
      completedAt: done ? DateTime.now() : null,
    );
    _today[index] = updated;
    final allIndex = _allTasks.indexWhere((t) => t.id == id);
    if (allIndex != -1) {
      _allTasks[allIndex] = updated;
    }
    _sortToday();
    notifyListeners();

    try {
      await _service.toggleDone(id, done);
    } catch (error) {
      _today[index] = before;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(
    String id, {
    DateTime? dueDatePart,
    Duration? dueTime,
    DateTime? dueAt,
    bool clearDueAt = false,
    DateTime? targetDatePart,
    Duration? targetTime,
    DateTime? targetAt,
    bool clearTargetAt = false,
    String? goalStepId,
    bool clearGoalStep = false,
    int? priority,
    String? iconName,
    int? estimatedMinutes,
    bool clearEstimatedMinutes = false,
  }) async {
    final index = _today.indexWhere((task) => task.id == id);
    if (index < 0) return;

    final before = _today[index];
    var updated = before;

    if (iconName != null) {
      updated = updated.copyWith(iconName: iconName);
    }

    if (priority != null) {
      updated = updated.copyWith(
        priority: priority,
        points: priority * 2, //keep points in sync locally with priority
      );
    }

    int? nextEstimatedMinutes = before.estimatedMinutes;
    if (clearEstimatedMinutes) {
      nextEstimatedMinutes = null;
      updated = updated.copyWith(clearEstimatedMinutes: true);
    } else if (estimatedMinutes != null) {
      nextEstimatedMinutes = estimatedMinutes;
      updated = updated.copyWith(estimatedMinutes: estimatedMinutes);
    }

    DateTime? nextDueAt = before.dueAt;
    if (clearDueAt) {
      nextDueAt = null;
      updated = updated.copyWith(clearDueAt: true);
    } else if (dueAt != null || dueDatePart != null || dueTime != null) {
      nextDueAt =
          dueAt ??
          _composeDueAt(
            date: dueDatePart,
            time: dueTime,
            existing: before.dueAt,
          );
      updated = updated.copyWith(dueAt: nextDueAt);
    }

    DateTime? nextTargetAt = before.targetAt;
    if (clearTargetAt) {
      nextTargetAt = null;
      updated = updated.copyWith(clearTargetAt: true);
    } else if (targetAt != null ||
        targetDatePart != null ||
        targetTime != null) {
      nextTargetAt =
          targetAt ??
          _composeDueAt(
            date: targetDatePart,
            time: targetTime,
            existing: before.targetAt,
          );
      updated = updated.copyWith(targetAt: nextTargetAt);
    }

    if (clearGoalStep) {
      updated = updated.copyWith(clearGoalStep: true);
    } else if (goalStepId != null) {
      updated = updated.copyWith(goalStepId: goalStepId);
    }

    _today[index] = updated;
    final allIndex = _allTasks.indexWhere((t) => t.id == id);
    if (allIndex != -1) _allTasks[allIndex] = updated;
    _sortToday();
    notifyListeners();

    final dueAtForUpdate = clearDueAt
        ? null
        : (nextDueAt != before.dueAt ? nextDueAt : null);
    final targetAtForUpdate = clearTargetAt
        ? null
        : (nextTargetAt != before.targetAt ? nextTargetAt : null);
    final estimateForUpdate = clearEstimatedMinutes
        ? null
        : (nextEstimatedMinutes != before.estimatedMinutes
            ? nextEstimatedMinutes
            : null);

    try {
      await _service.updateTask(
        id,
        dueAt: dueAtForUpdate,
        clearDueAt: clearDueAt,
        targetAt: targetAtForUpdate,
        clearTargetAt: clearTargetAt,
        goalStepId: goalStepId,
        clearGoalStep: clearGoalStep,
        priority: priority,
        iconName: iconName,
        estimatedMinutes: estimateForUpdate,
        clearEstimatedMinutes: clearEstimatedMinutes,
      );
    } catch (error) {
      _today[index] = before;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    final idx = _today.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final removed = _today.removeAt(idx);
    _allTasks.removeWhere((t) => t.id == id);
    notifyListeners();
    try {
      await _service.deleteTask(id);
      _subtasksByTask.remove(id);
      _labelsByTask.remove(id);
      _notesByTask.remove(id);
      if (_selectedTaskId == id) {
        _selectedTaskId = _today.isEmpty ? null : _today.first.id;
      }
    } catch (e) {
      //rollback
      _today.insert(idx, removed);
      notifyListeners();
      print('Failed to delete task: $e');
      rethrow;
    }
  }

  Future<void> _loadDetails(String taskId) async {
    try {
      final subs = await _subtaskService.fetchForTask(taskId);
      _subtasksByTask[taskId] = subs;
      _labelsByTask[taskId] = await _labelService.getTaskLabelNames(taskId);
      _notesByTask[taskId] = await _service.fetchNote(taskId);
    } catch (_) {
      //ignore detail failures for now
    } finally {
      notifyListeners();
    }
  }

  Future<void> addSubtask(String taskId, String title) async {
    final list = List<DbSubtask>.from(_subtasksByTask[taskId] ?? const []);
    final temp = DbSubtask(
      id: 'tmp-${DateTime.now().microsecondsSinceEpoch}',
      taskId: taskId,
      title: title,
      isDone: false,
    );
    list.add(temp);
    _subtasksByTask[taskId] = list;
    notifyListeners();
    try {
      final created = await _subtaskService.create(
        taskId,
        title,
        orderHint: 1000 * list.length,
      );
      final updated = List<DbSubtask>.from(_subtasksByTask[taskId] ?? const []);
      final idx = updated.indexWhere((s) => s.id == temp.id);
      if (idx >= 0) updated[idx] = created;
      _subtasksByTask[taskId] = updated;
      notifyListeners();
    } catch (e) {
      final updated = List<DbSubtask>.from(_subtasksByTask[taskId] ?? const []);
      updated.removeWhere((s) => s.id == temp.id);
      _subtasksByTask[taskId] = updated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleSubtask(String taskId, String subtaskId, bool done) async {
    final list = List<DbSubtask>.from(_subtasksByTask[taskId] ?? const []);
    final idx = list.indexWhere((s) => s.id == subtaskId);
    if (idx < 0) return;
    final before = list[idx];
    list[idx] = before.copyWith(isDone: done);
    _subtasksByTask[taskId] = list;
    notifyListeners();
    try {
      await _subtaskService.toggleDone(subtaskId, done);
    } catch (e) {
      list[idx] = before;
      _subtasksByTask[taskId] = list;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final list = List<DbSubtask>.from(_subtasksByTask[taskId] ?? const []);
    final idx = list.indexWhere((s) => s.id == subtaskId);
    if (idx < 0) return;
    final removed = list.removeAt(idx);
    _subtasksByTask[taskId] = list;
    notifyListeners();
    try {
      await _subtaskService.delete(subtaskId);
    } catch (e) {
      list.insert(idx, removed);
      _subtasksByTask[taskId] = list;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setNote(String taskId, String? content) async {
    _notesByTask[taskId] = content;
    notifyListeners();
    await _service.upsertNote(taskId, content);
  }

  Future<void> toggleLabel(
    String taskId,
    String labelName,
    bool enabled,
  ) async {
    final set = _labelsByTask.putIfAbsent(taskId, () => <String>{});
    if (enabled) {
      set.add(labelName);
    } else {
      set.remove(labelName);
    }
    _labelsByTask[taskId] = set;
    notifyListeners();
    await _labelService.toggleTaskLabel(taskId, labelName, enabled);
  }
  
  //For task ordering
  Future<void> updateTaskOrder(String taskId, int newOrderHint) async {
    try {
      // Update local list
      final index = _today.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _today[index] = _today[index].copyWith(orderHint: newOrderHint);
        notifyListeners();
      }
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  Future<void> assignTaskToStep(String taskId, String? goalStepId) async {
    final index = _today.indexWhere((task) => task.id == taskId);
    if (index < 0) return;
    final before = _today[index];
    final updated = before.copyWith(
      goalStepId: goalStepId,
      clearGoalStep: goalStepId == null,
    );
    _today[index] = updated;
    notifyListeners();
    try {
      await _service.setGoalStep(taskId, goalStepId: goalStepId);
    } catch (error) {
      _today[index] = before;
      notifyListeners();
      rethrow;
    }
  }

  void _sortToday() {
    //ensure list is growable before sorting (avoid const list sort errors)
    _today = List<TaskItem>.from(_today);
    _today.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      final dueA = a.dueAt;
      final dueB = b.dueAt;
      if (dueA != null && dueB != null) {
        final dueComparison = dueA.compareTo(dueB);
        if (dueComparison != 0) return dueComparison;
      } else if (dueA == null && dueB != null) {
        return 1;
      } else if (dueA != null && dueB == null) {
        return -1;
      }
      if (_sortByEstimate) {
        final estA = a.estimatedMinutes;
        final estB = b.estimatedMinutes;
        if (estA != null || estB != null) {
          if (estA == null) return 1;
          if (estB == null) return -1;
          final estimateComparison = estB.compareTo(estA);
          if (estimateComparison != 0) return estimateComparison;
        }
      }
      final targetA = a.targetAt;
      final targetB = b.targetAt;
      if (targetA != null && targetB != null) {
        final targetComparison = targetA.compareTo(targetB);
        if (targetComparison != 0) return targetComparison;
      } else if (targetA == null && targetB != null) {
        return 1;
      } else if (targetA != null && targetB == null) {
        return -1;
      }
      final priorityComparison = b.priority.compareTo(a.priority);
      if (priorityComparison != 0) {
        return priorityComparison;
      }
      return a.orderHint.compareTo(b.orderHint);
    });
  }

  DateTime _defaultDueAt(DateTime reference) {
    final local = reference.toLocal();
    final truncated = DateTime(local.year, local.month, local.day, local.hour);
    return truncated.add(const Duration(hours: 1));
  }

  DateTime _composeDueAt({DateTime? date, Duration? time, DateTime? existing}) {
    final baseDate = (date ?? existing ?? DateTime.now()).toLocal();
    final resolvedTime =
        time ??
        (existing != null
            ? Duration(
                hours: existing.toLocal().hour,
                minutes: existing.toLocal().minute,
              )
            : const Duration(hours: 23, minutes: 59));
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      resolvedTime.inHours.remainder(24),
      resolvedTime.inMinutes.remainder(60),
    );
  }

  List<SuggestedTask> _buildSuggestions() {
    if (_today.isEmpty) return const [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = today.add(const Duration(days: 1));
    const horizonDays = 2;
    final horizon = today.add(Duration(days: horizonDays + 1));

    final List<SuggestedTask> suggestions = [];
    for (final task in _today) {
      if (task.isDone) continue;

      final warnings = <String>[];
      final due = task.dueAt?.toLocal();
      final estimate = task.estimatedMinutes;
      final priority = task.priority;
      final target = task.targetAt?.toLocal();

      // Base urgency
      double urgency = 100; // baseline for undated
      if (due == null) {
        warnings.add('No due date set');
      } else if (due.isBefore(today)) {
        final daysOverdue = today.difference(due).inDays + 1;
        urgency = 1000 + daysOverdue * 20;
      } else if (!due.isAfter(endOfToday)) {
        urgency = 700;
      } else if (!due.isAfter(horizon)) {
        final daysAway = due.difference(today).inDays;
        urgency = 500 - daysAway * 40;
      } else {
        urgency = 200;
      }

      // Priority weight (higher priority value => more weight in this app)
      if (priority <= 0) warnings.add('No priority set');
      final priorityWeight = (priority <= 0 ? 5 : priority) * 40.0;

      // Target boost
      double targetBoost = 0;
      if (target != null &&
          !target.isBefore(today) &&
          !target.isAfter(horizon)) {
        targetBoost = 80;
      }

      // Goal link boost
      final goalBoost =
          (task.goalStepId != null || task.goalId != null) ? 60.0 : 0.0;

      final baseScore = urgency + priorityWeight + targetBoost + goalBoost;

      // Estimated minutes factor: prefer shorter, but avoid zero/negative.
      double divisor = 1;
      if (estimate != null && estimate > 0) {
        divisor = math.log(estimate + 1);
        if (divisor <= 0) divisor = 1;
      } else {
        warnings.add('No estimate set');
      }

      final score = baseScore / divisor;

      suggestions.add(
        SuggestedTask(
          task: task,
          score: score,
          warnings: warnings,
        ),
      );
    }

    suggestions.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;

      final dueA = a.task.dueAt;
      final dueB = b.task.dueAt;
      if (dueA != null && dueB != null) {
        final dueCmp = dueA.compareTo(dueB);
        if (dueCmp != 0) return dueCmp;
      } else if (dueA == null && dueB != null) {
        return 1;
      } else if (dueA != null && dueB == null) {
        return -1;
      }

      final priCmp = b.task.priority.compareTo(a.task.priority);
      if (priCmp != 0) return priCmp;

      final orderCmp = a.task.orderHint.compareTo(b.task.orderHint);
      if (orderCmp != 0) return orderCmp;

      return a.task.title.compareTo(b.task.title);
    });

    return suggestions;
  }
}

class SuggestedTask {
  const SuggestedTask({
    required this.task,
    required this.score,
    required this.warnings,
  });

  final TaskItem task;
  final double score;
  final List<String> warnings;
}
