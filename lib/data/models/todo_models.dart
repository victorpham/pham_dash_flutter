import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/api/api_date.dart';
import 'converters.dart';

part 'todo_models.freezed.dart';
part 'todo_models.g.dart';

@freezed
abstract class TodoItem with _$TodoItem {
  const factory TodoItem({
    required int id,
    required int todoListId,

    /// Null for an ungrouped item. Note that **sending** `groupId: 0` is what
    /// removes an item from its group - see `UpdateTodoItem`.
    int? groupId,
    required String content,
    @JsonKey(defaultValue: false) required bool isCompleted,
    @JsonKey(defaultValue: 0) required int displayOrder,

    /// 0-2. The web UI caps nesting at 2 and forbids indenting the first item.
    @JsonKey(defaultValue: 0) required int indentLevel,

    /// Signed, root-relative picture of the item, or null. Resolve with
    /// `AppConfig.mediaUrl`. Set and cleared through the dedicated image
    /// endpoints - `UpdateTodoItem` cannot touch it.
    String? imageUrl,

    /// Where to find it in the shop - "Aisle 7", "Bakery". Free text, null when
    /// unset; the server never returns `""`. Cleared with `""` on the wire - see
    /// `UpdateTodoItem.clearLocation`.
    String? location,
    @UtcStamp() DateTime? createdAt,
    @UtcStamp() DateTime? completedAt,
  }) = _TodoItem;

  factory TodoItem.fromJson(Map<String, dynamic> json) =>
      _$TodoItemFromJson(json);
}

@freezed
abstract class TodoItemGroup with _$TodoItemGroup {
  const factory TodoItemGroup({
    required int id,
    required int todoListId,
    required String name,
    @JsonKey(defaultValue: 0) required int displayOrder,
    @JsonKey(defaultValue: <TodoItem>[]) required List<TodoItem> items,
  }) = _TodoItemGroup;

  factory TodoItemGroup.fromJson(Map<String, dynamic> json) =>
      _$TodoItemGroupFromJson(json);
}

@freezed
abstract class TodoLabel with _$TodoLabel {
  const factory TodoLabel({
    required int id,
    required String name,
    String? color,
    @JsonKey(defaultValue: 0) required int listCount,
  }) = _TodoLabel;

  factory TodoLabel.fromJson(Map<String, dynamic> json) =>
      _$TodoLabelFromJson(json);
}

/// The calendar event a list is linked to.
///
/// Only ever populated by `GET /api/todo/lists/all-scheduled`, which **this
/// client no longer calls** — the Lists tab is the full list browser now, not
/// the scheduled feed. So this is null on every payload the app currently
/// reads. Kept because it is still on the wire and the web dashboard still
/// relies on it; anything reading it here needs the server to start sending it
/// on `GET /todo/lists` first.
@freezed
abstract class LinkedEvent with _$LinkedEvent {
  const factory LinkedEvent({
    required String eventId,
    String? eventTitle,
    @RequiredWallClock() required DateTime eventStart,
    @WallClock() DateTime? eventEnd,
    @JsonKey(defaultValue: false) required bool isAllDay,
  }) = _LinkedEvent;

  factory LinkedEvent.fromJson(Map<String, dynamic> json) =>
      _$LinkedEventFromJson(json);
}

@freezed
abstract class TodoList with _$TodoList {
  const factory TodoList({
    required int id,
    required String title,
    String? color,
    @JsonKey(defaultValue: false) required bool isPinned,
    @JsonKey(defaultValue: false) required bool isArchived,
    @JsonKey(defaultValue: 0) required int displayOrder,
    @UtcStamp() DateTime? createdAt,
    @UtcStamp() DateTime? updatedAt,
    @WallClock() DateTime? reminderDateTime,

    /// An `"HH:mm"` **string**, not a timestamp. Use [scheduledMinutes].
    String? scheduledTime,

    /// CSV of `0`=Sunday..`6`=Saturday. Null or empty means every day.
    String? scheduledDays,
    String? personId,
    String? personName,

    /// **Ungrouped items only.** Items that belong to a group live in
    /// `groups[].items`. Use [allItems] unless you specifically want the
    /// ungrouped ones - rendering this list alone silently drops every grouped
    /// item, which is the easiest mistake to make against this API.
    @JsonKey(defaultValue: <TodoItem>[]) required List<TodoItem> items,
    @JsonKey(defaultValue: <TodoItemGroup>[])
    required List<TodoItemGroup> groups,
    @JsonKey(defaultValue: <TodoLabel>[]) required List<TodoLabel> labels,

    /// Counts **all** items, grouped and ungrouped.
    @JsonKey(defaultValue: 0) required int totalItems,
    @JsonKey(defaultValue: 0) required int completedItems,
    LinkedEvent? linkedEvent,
  }) = _TodoList;

  const TodoList._();

  factory TodoList.fromJson(Map<String, dynamic> json) =>
      _$TodoListFromJson(json);

  /// Every item on the list, ungrouped ones first then each group's, in
  /// display order.
  List<TodoItem> get allItems => [
        ...items,
        for (final group in groups) ...group.items,
      ];

  /// The full item ordering to send to `/todo/lists/{id}/items/reorder` after
  /// one section has been rearranged.
  ///
  /// The server assigns `displayOrder = index` across the **whole list**, not
  /// per group, and ids left out of the request keep their old value — so
  /// posting just the section that moved leaves duplicate orders behind. Pass
  /// the new ordering for whichever section changed under [ungrouped] or in
  /// [groups]; every other section is taken as it currently stands.
  List<int> reorderPayload({
    List<int>? ungrouped,
    Map<int, List<int>> groups = const {},
  }) =>
      [
        ...ungrouped ?? items.map((item) => item.id),
        for (final group in this.groups)
          ...groups[group.id] ?? group.items.map((item) => item.id),
      ];

  /// Minutes since midnight for [scheduledTime], or null when unscheduled.
  int? get scheduledMinutes => ApiDate.parseMinutesOfDay(scheduledTime);

  Set<int> get scheduledDaySet => ApiDate.parseScheduledDays(scheduledDays);

  /// True when this list is driven by a calendar event rather than a time.
  bool get isEventLinked => linkedEvent != null;

  /// Whether the list should show today, per its day-of-week filter.
  ///
  /// The server applies this on `/todo/lists/scheduled` but **not** on
  /// `/todo/lists/all-scheduled`, so the client has to.
  bool runsOn(DateTime day) {
    final days = scheduledDaySet;
    if (days.isEmpty) return true;
    return days.contains(ApiDate.jsWeekday(day));
  }
}

/// Body for `POST /api/todo/lists`.
@freezed
abstract class CreateTodoList with _$CreateTodoList {
  const factory CreateTodoList({
    required String title,
    String? color,
    String? personId,
    @WallClock() DateTime? reminderDateTime,
    String? scheduledTime,
    String? scheduledDays,

    /// Optional seed items. Ungrouped, order preserved.
    List<CreateTodoItem>? items,
  }) = _CreateTodoList;

  factory CreateTodoList.fromJson(Map<String, dynamic> json) =>
      _$CreateTodoListFromJson(json);
}

@freezed
abstract class CreateTodoItem with _$CreateTodoItem {
  const factory CreateTodoItem({
    required String content,
    @JsonKey(defaultValue: 0) int? indentLevel,
    int? groupId,
    String? location,
  }) = _CreateTodoItem;

  factory CreateTodoItem.fromJson(Map<String, dynamic> json) =>
      _$CreateTodoItemFromJson(json);
}

/// Body for `PUT /api/todo/lists/{id}`.
///
/// Hand-written rather than generated because the API's partial-update
/// semantics are unusual enough to be worth stating in code:
///
///  * A field left null is **ignored**, not cleared. You cannot blank
///    `scheduledTime`, `color` or `personId` by sending null.
///  * [clearSchedule] is the only way to remove a schedule, and it nulls
///    **both** `scheduledTime` and `scheduledDays`.
///  * A colour is cleared by sending the **empty string**, not null — the
///    server stores it verbatim and every client parses `""` back to "no
///    colour". The web's "None" swatch sends null and so silently does
///    nothing; see [kClearColor].
///  * `personId` has no such escape hatch. It is a foreign key, so `""` fails
///    the constraint rather than unlinking, and null is ignored — a list's
///    person can be set and changed but **not removed** without an API change.
///  * An unparseable `scheduledTime` is silently dropped by the server rather
///    than rejected, so validate before sending.
/// Sent as `color` to clear a list's colour.
///
/// `null` would be ignored by the partial-update rules, and the column is a
/// plain `nvarchar(7)`, so the empty string is both accepted and parsed back to
/// "no colour" by `parseHexColor`.
const String kClearColor = '';

class UpdateTodoList {
  const UpdateTodoList({
    this.title,
    this.color,
    this.isPinned,
    this.isArchived,
    this.displayOrder,
    this.reminderDateTime,
    this.scheduledTime,
    this.scheduledDays,
    this.clearSchedule = false,
    this.personId,
  });

  final String? title;
  final String? color;
  final bool? isPinned;
  final bool? isArchived;
  final int? displayOrder;
  final DateTime? reminderDateTime;
  final String? scheduledTime;
  final String? scheduledDays;

  /// Sends `clearScheduledTime: true`, nulling the time *and* the days.
  final bool clearSchedule;
  final String? personId;

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (color != null) 'color': color,
        if (isPinned != null) 'isPinned': isPinned,
        if (isArchived != null) 'isArchived': isArchived,
        if (displayOrder != null) 'displayOrder': displayOrder,
        if (reminderDateTime != null)
          'reminderDateTime': ApiDate.formatWallClock(reminderDateTime!),
        if (scheduledTime != null) 'scheduledTime': scheduledTime,
        if (scheduledDays != null) 'scheduledDays': scheduledDays,
        if (clearSchedule) 'clearScheduledTime': true,
        if (personId != null) 'personId': personId,
      };
}

/// Body for `PUT /api/todo/items/{id}`.
///
/// `groupId` carries a third state the other fields do not: `null` means "leave
/// the grouping alone", while **`0` means "remove this item from its group"**.
/// There is no other way to un-group an item, so it is expressed here as an
/// explicit intent rather than a magic number at the call site. `location` has
/// the same shape - null is "leave it", the empty string clears - and gets the
/// same treatment through [clearLocation].
class UpdateTodoItem {
  const UpdateTodoItem({
    this.content,
    this.isCompleted,
    this.displayOrder,
    this.indentLevel,
    this.groupId,
    this.removeFromGroup = false,
    this.location,
    this.clearLocation = false,
  });

  final String? content;

  /// Setting this also sets or clears `completedAt` server-side.
  final bool? isCompleted;
  final int? displayOrder;
  final int? indentLevel;

  /// The group to move this item into. Ignored when [removeFromGroup] is set.
  final int? groupId;

  /// Sends the sentinel `groupId: 0`, which un-groups the item.
  final bool removeFromGroup;

  /// New location text. Ignored when [clearLocation] is set.
  final String? location;

  /// Sends `location: ""`, which the server stores as null.
  final bool clearLocation;

  Map<String, dynamic> toJson() => {
        if (content != null) 'content': content,
        if (isCompleted != null) 'isCompleted': isCompleted,
        if (displayOrder != null) 'displayOrder': displayOrder,
        if (indentLevel != null) 'indentLevel': indentLevel,
        if (removeFromGroup)
          'groupId': 0
        else if (groupId != null)
          'groupId': groupId,
        if (clearLocation)
          'location': ''
        else if (location != null)
          'location': location,
      };
}
