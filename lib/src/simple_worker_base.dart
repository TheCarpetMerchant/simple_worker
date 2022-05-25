import 'dart:async';
import 'dart:isolate';

/// An interface for giving work to another Isolate.
class SimpleWorker {

  SimpleWorker({
    this.maxDelayInMilliseconds = defaultMaxDelayInMilliseconds,
    bool initializeWorker = false,
  }) {
    if(initializeWorker) initWorker();
  }

  SendPort? _workerSendPort;
  Completer? _initCompleter;
  Isolate? _isolate;
  Completer _workCompleter = Completer()..complete();

  /// The duration of the timeout for compute(). The Isolate isn't killed after timeout, the returned value is just ignored.
  final int maxDelayInMilliseconds;

  /// True if no work is being done (work is finished). Will return true after instantiating a [SimpleWorker].
  bool get isCompleted => _workCompleter.isCompleted;

  /// The Future of a Completer which will complete when the Worker finishes its current task.
  Future<dynamic> get future => _workCompleter.future;

  /// Spawn the Isolate of the worker if not already done, or not already in the process of spawning.
  Future<void> initWorker() async {

    // If we are currently spawning, the completer exists.
    if(_initCompleter != null && _initCompleter!.isCompleted == false) {
      await _initCompleter!.future;
      _initCompleter = null;
      if(_workerSendPort != null) return;
    }

    // If the Isolate isn't up and running, set it up.
    if(_workerSendPort != null) return;

    _initCompleter = Completer();

    // To do that, we pass the Isolate a SendPort, with which he will send us its own sendPort, which he will listen on for our messages.
    ReceivePort tempPort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntryPoint,tempPort.sendPort);

    // Catch the returned SendPort, which we will use to send instructions.
    _workerSendPort = await tempPort.first;

    _initCompleter?.complete();

  }


  /// A [method] and its arguments, to be executed in an Isolate. Return the return value of [method], or null if timeout (see [maxDelayInMilliseconds]).
  ///
  /// User-friendly function just like flutter/foundation, just with more arguments.
  /// Arguments are optional. Any null argument is ignored, except if there is a non-null argument after it.
  /// So compute(function, 'test', null) is stupid, but compute(function, 'test', null, 'other test') is valid and the null will be passed.
  /// Null is returned in case of timeout.
  Future<dynamic> compute(
      Function method,
      {
        data0,
        data1,
        data2,
        data3,
        data4,
        data5,
        data6,
        data7,
        data8,
        data9,
        bool exit = false,
      }
  ) async {

    // Create a Completer so we can listen to when the compute() finishes. Used in WorkerGroup.
    _workCompleter = Completer();

    // Create the map of arguments to be interpreted by _doJob.
    Map<String, dynamic> job = {
      jobKey: method,
      exitKey: exit,
      '0': data0,
      '1': data1,
      '2': data2,
      '3': data3,
      '4': data4,
      '5': data5,
      '6': data6,
      '7': data7,
      '8': data8,
      '9': data9,
    };

    // What is the last non-null member ? We remove all those after. This keep nulls in between two values.
    for(int i = 9; i >= 0; i--) {
      if(job[i.toString()] == null) {
        job.remove(i.toString());
      } else {
        break;
      }
    }

    // Verify the worker is initialized.
    await initWorker();

    // Create a port which will be used to get our answer and add it to the arguments.
    ReceivePort response = ReceivePort();
    job[sendPortKey] = response.sendPort;

    // Send the job to the Isolate and await the response (only the first).
    _workerSendPort!.send(job);

    var value = await response.first.timeout(Duration(milliseconds: maxDelayInMilliseconds), onTimeout: () => null);

    _workCompleter.complete();

    return value;
  }

  /// Kills the Isolate. The SimpleWorker will be the same as if you called SimpleWorker(), unless work is being done (see [maxDelayInMilliseconds]).
  void dispose() {
    _isolate!.kill(priority: Isolate.beforeNextEvent);
    _workerSendPort = null;
    _initCompleter = null;
    _isolate = null;
  }

  /// Creates an Isolate and runs [compute] with [exit] = true.
  /// The Isolate is destructed when the result is returned.
  /// The result isn't copied (serialized), a pointer to the result is given on Isolate.exit().
  /// This means we can return huge amounts of data at next to no cost (ex: large json download).
  static Future<dynamic> computeOnce(
      Function method,
      {
        int maxDelayInMilliseconds = defaultMaxDelayInMilliseconds,
        data0,
        data1,
        data2,
        data3,
        data4,
        data5,
        data6,
        data7,
        data8,
        data9,
      }
  ) async {
    SimpleWorker worker = SimpleWorker(maxDelayInMilliseconds: maxDelayInMilliseconds);
    await worker.initWorker();
    return worker.compute(
      method,
      data0: data0,
      data1: data1,
      data2: data2,
      data3: data3,
      data4: data4,
      data5: data5,
      data6: data6,
      data7: data7,
      data8: data8,
      data9: data9,
      exit: true,
    );
  }

  /// The worker itself. On spawning, it sends back a SendPort which will he will be listening on for instructions from [askWorker].
  static void _isolateEntryPoint(SendPort replyTo) async {

    // Send back our communication SendPort.
    ReceivePort receivePort = ReceivePort();
    replyTo.send(receivePort.sendPort);

    // Listen for a job to do.
    receivePort.listen((message) => _doJob(message));
  }

  /// Interprets the map passed by [compute] and executes the required task.
  static void _doJob(Map<String, dynamic> job) async {

    // Extract the Function and the SendPort. Clear the so we only have the arguments left.
    Function function = job.remove(jobKey);
    SendPort port = job.remove(sendPortKey);
    bool? exit = job.remove(exitKey);

    // Execute the job according to the number of arguments provided.
    // Minus 2 because the arguments 'SendPort' and 'job' are mandatory.
    List<String> keys = job.keys.toList();

    dynamic execute() async {
      switch(keys.length) {
        case 0: return function();
        case 1: return function(job[keys[0]],);
        case 2: return function(job[keys[0]],job[keys[1]],);
        case 3: return function(job[keys[0]],job[keys[1]],job[keys[2]],);
        case 4: return function(job[keys[0]],job[keys[1]],job[keys[2]],job[keys[3]],);
        case 5: return function(job[keys[0]],job[keys[1]],job[keys[2]],job[keys[3]],job[keys[4]],);
        case 6: return function(job[keys[0]],job[keys[1]],job[keys[2]],job[keys[3]],job[keys[4]],job[keys[5]],);
        case 7: return function(job[keys[0]],job[keys[1]],job[keys[2]],job[keys[3]],job[keys[4]],job[keys[5]],job[keys[6]],);
        case 8: return function(job[keys[0]],job[keys[1]],job[keys[2]],job[keys[3]],job[keys[4]],job[keys[5]],job[keys[6]],job[keys[7]],);
        case 9: return function(job[keys[0]],job[keys[1]],job[keys[2]],job[keys[3]],job[keys[4]],job[keys[5]],job[keys[6]],job[keys[7]],job[keys[8]],);
        case 10: return function(job[keys[0]],job[keys[1]],job[keys[2]],job[keys[3]],job[keys[4]],job[keys[5]],job[keys[6]],job[keys[7]],job[keys[8]],job[keys[9]],);
      }
    }

    if(exit == true) {
      Isolate.exit(port, await execute());
    } else {
      port.send(await execute());
    }
  }

  /// This value (10 000) will be used for [SimpleWorker.maxDelayInMilliseconds] if no value is provided.
  static const int defaultMaxDelayInMilliseconds = 10000;

  static const String sendPortKey = 'SendPort';
  static const String jobKey = 'job';
  static const String exitKey = 'exit';
}

/// A wrapper for easily using a group of workers.
class WorkerGroup {

  final List<SimpleWorker> _workers = [];

  /// The maximum amount of Isolates spawned. If the number of tasks exceeds the number of Isolates, the first Isolate to finish its task is re-used immediately.
  final int maxIsolates;

  /// Passed to [SimpleWorker.maxDelayInMilliseconds] for each worker.
  final int maxDelayInMilliseconds;

  WorkerGroup({this.maxIsolates = 10, this.maxDelayInMilliseconds = 10000});

  /// Equivalent to [SimpleWorker.compute]. Will call [method] on each element of [objects], each in an Isolate.
  /// The [objects] list is not replaced, but its elements are each replaced by the result of [method].
  /// Hence, method needs to return [T].
  Future<void> compute<T>(
      List<T> objects,
      Function method,
      {
        data0,
        data1,
        data2,
        data3,
        data4,
        data5,
        data6,
        data7,
        data8,
      }
  ) async {

    // Spawn enough Isolates, but no more then the maxIsolates
    while(_workers.length < maxIsolates && _workers.length < objects.length) {
      _workers.add(
        SimpleWorker(
          maxDelayInMilliseconds: maxDelayInMilliseconds,
          initializeWorker: true,
        ),
      );
    }

    // Each object is now passed to an Isolate. The returned object must be the same type, there is no error management. If the delay is passed, nothing is done.
    // It is advisable to have a simple error management consisting of a 'result' String and a 'done' bool (see WorkerResult class).
    List<Future<dynamic>> resultsFutures = [];
    for(T object in objects) {
      // Get the first free worker and get the Future of its compute()
      SimpleWorker worker = await _giveNextWorker();
      resultsFutures.add(
        worker.compute(
          method,
          data0: object,
          data1: data1,
          data2: data2,
          data3: data3,
          data4: data4,
          data5: data5,
          data6: data6,
          data7: data7,
          data8: data8,
          data9: data8,
        ),
      );
    }

    // Wait for everything to complete
    await Future.wait(_workers.map((e) => e.future));

    // Transpose the new objects into the given list
    for(int i = 0; i < resultsFutures.length; i++) {
      objects[i] = await resultsFutures[i];
    }

  }

  // Waits for any of the workers to finish, then give it.
  Future<SimpleWorker> _giveNextWorker() async {
    await Future.any(_workers.map((e) => e.future));
    return _workers.firstWhere((e) => e.isCompleted);
  }

  /// Calls dispose() on all workers.
  void dispose() {
    for(SimpleWorker worker in _workers) {
      worker.dispose();
    }
  }

}

/// Extend this class to use it as an error handler.
class WorkerResult {

  String workerResult = '';
  bool workerDone = false;

  WorkerResult();
  WorkerResult.write(this.workerResult);

}