import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/kochmodus/domain/cook_duration.dart';
import 'package:yamt/features/recipes/domain/cook_line_text.dart';

/// What the cook said, understood. The guide ("Kochhelfer") acts on
/// [CookVoiceNext], [CookVoiceBack] and [CookVoiceTimer]; the cooking page
/// on [CookVoiceUndo] and [CookVoiceAddLines].
@immutable
sealed class CookVoiceCommand {
  /// Creates the command.
  const new();
}

/// "weiter", "next": the next instruction.
final class CookVoiceNext extends CookVoiceCommand {
  /// Creates the command.
  const new();

  @override
  bool operator ==(Object other) => other is CookVoiceNext;

  @override
  int get hashCode => (CookVoiceNext).hashCode;
}

/// "zurück", "back": the instruction before.
final class CookVoiceBack extends CookVoiceCommand {
  /// Creates the command.
  const new();

  @override
  bool operator ==(Object other) => other is CookVoiceBack;

  @override
  int get hashCode => (CookVoiceBack).hashCode;
}

/// "Timer 10 Minuten", "set a timer for 5 minutes".
final class CookVoiceTimer extends CookVoiceCommand {
  /// Creates the command.
  const new(this.duration);

  /// How long the timer runs.
  final Duration duration;

  @override
  bool operator ==(Object other) =>
      other is CookVoiceTimer && other.duration == duration;

  @override
  int get hashCode => duration.hashCode;
}

/// "nein", "weg", "no", "undo": what was said last is taken back.
final class CookVoiceUndo extends CookVoiceCommand {
  /// Creates the command.
  const new();

  @override
  bool operator ==(Object other) => other is CookVoiceUndo;

  @override
  int get hashCode => (CookVoiceUndo).hashCode;
}

/// Anything else: lines, one per part split at "und", "and" or a comma
/// ("200 g Sahne und Salz"). A part after a comma that is only an amount stays
/// with the part before ("Öl, 30 g"). The cooking page adds them, or records a
/// weight on the assigned line they name.
final class CookVoiceAddLines extends CookVoiceCommand {
  /// Creates the command.
  new(List<String> lines) : lines = List.unmodifiable(lines);

  /// The lines as said, trimmed, in their case.
  final List<String> lines;

  @override
  bool operator ==(Object other) =>
      other is CookVoiceAddLines &&
      const ListEquality<String>().equals(other.lines, lines);

  @override
  int get hashCode => const ListEquality<String>().hash(lines);
}

/// What [heard] asks for, in German or English, or `null` when it says
/// nothing, such as "Timer" without a duration.
CookVoiceCommand? parseCookVoiceCommand(String heard) {
  final said = heard.trim().replaceAll(_trailingMarks, '');
  final text = said.toLowerCase();
  if (text.isEmpty) return null;
  if (_next.contains(text)) return const CookVoiceNext();
  if (_back.contains(text)) return const CookVoiceBack();
  if (_undo.contains(text)) return const CookVoiceUndo();
  if (_timerWord.hasMatch(text)) {
    final durations = cookDurationsIn(text);
    return durations.isEmpty ? null : CookVoiceTimer(durations.first.shortest);
  }
  final lines = [for (final part in said.split(_and)) ..._commaParts(part)];
  return lines.isEmpty ? null : CookVoiceAddLines(lines);
}

// The lines of [said], split at its commas; a part that is only an amount
// joins the part before it.
List<String> _commaParts(String said) {
  final lines = <String>[];
  for (final raw in said.split(_comma)) {
    final part = raw.trim();
    if (part.isEmpty) continue;
    final joined = lines.isEmpty
        ? null
        : cookTextJoinedAmount(lines.last, part);
    if (joined == null) {
      lines.add(part);
    } else {
      lines.last = joined;
    }
  }
  return lines;
}

// Speech recognition ends a sentence with a mark.
final _trailingMarks = RegExp(r'[.!?]+$');

const _next = {
  'weiter',
  'nächster schritt',
  'nächsten schritt',
  'next',
  'next step',
};

const _back = {
  'zurück',
  'zurückgehen',
  'vorheriger schritt',
  'vorherigen schritt',
  'back',
  'previous step',
};

const _undo = {'nein', 'weg', 'no', 'undo'};

final _timerWord = RegExp(r'\btimer\b|\bwecker\b');

final _and = RegExp(r'\bund\b|\band\b', caseSensitive: false);

// A comma between digits is a decimal comma ("1,5 kg Mehl").
final _comma = RegExp(r',(?!\d)|(?<!\d),');
