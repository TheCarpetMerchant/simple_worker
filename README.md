Offload work to another Isolate or group of Isolates in any Dart program or Flutter application in a simple manner.

## Features

SimpleWorkers can compute be re-used by calling `compute`, or used once by calling `computeOnce`.
Calling `computeOnce` will result in a worker being created and destroyed for the task. No serialization cost is incurred for the data returned by the worker in this case.

You can use a WorkerGroup to compute the same function for a list of objects.
The object will be passed a the first argument to the function, and additional arguments are provided afterwards.

## Usage

```dart
print(await SimpleWorker().compute(bigTask, data0: 'param'));
```
