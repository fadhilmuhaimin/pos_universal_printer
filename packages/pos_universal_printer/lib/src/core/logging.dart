import 'dart:collection';

/// A simple ring buffer logger that holds up to [capacity] entries.
class Logger {
  Logger({this.capacity = 200});

  /// Maximum number of log entries retained.
  final int capacity;

  final Queue<LogEntry> _entries = Queue<LogEntry>();

  /// Record a log message with [level] and [message].
  void add(LogLevel level, String message) {
    final entry = LogEntry(level, message, DateTime.now());
    if (_entries.length >= capacity) {
      _entries.removeFirst();
    }
    _entries.add(entry);
  }

  /// Returns an immutable list of the current log entries.
  List<LogEntry> get entries => List.unmodifiable(_entries);
}

/// Severity level for log entries.
enum LogLevel { debug, info, warning, error }

/// A single log entry consisting of a [level], [message] and [timestamp].
class LogEntry {
  LogEntry(this.level, this.message, this.timestamp);

  final LogLevel level;
  final String message;
  final DateTime timestamp;

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] ${level.name.toUpperCase()}: $message';
}