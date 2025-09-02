import 'dart:async';

import 'logging.dart';

/// Represents a unit of work to be processed by [JobQueue].
class PrintJob {
  PrintJob(this.description, this.action);

  /// A human friendly description of the job.
  final String description;

  /// The function that performs the job.
  final Future<void> Function() action;
}

/// Simple queue that processes print jobs sequentially with basic retry
/// logic and backpressure. If a job fails it will be retried with
/// exponential backoff up to [maxRetries] times.
class JobQueue {
  JobQueue(this.logger, {this.maxRetries = 3});

  final Logger logger;
  final int maxRetries;
  final List<PrintJob> _queue = <PrintJob>[];
  bool _isProcessing = false;

  /// Adds a job to the queue and schedules processing.
  void addJob(PrintJob job) {
    _queue.add(job);
    _process();
  }

  Future<void> _process() async {
    if (_isProcessing) return;
    _isProcessing = true;
    while (_queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      int attempt = 0;
      while (true) {
        try {
          logger.add(LogLevel.debug, 'Running job: ${job.description}');
          await job.action();
          break;
  } catch (e) {
          attempt++;
          logger.add(LogLevel.error,
              'Job "${job.description}" failed (attempt $attempt): $e');
          if (attempt > maxRetries) {
            logger.add(LogLevel.error,
                'Job "${job.description}" exceeded max retries, dropping');
            break;
          }
          // Exponential backoff: 500ms * 2^(attempt-1)
          final delayMs = 500 * (1 << (attempt - 1));
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
    }
    _isProcessing = false;
  }
}