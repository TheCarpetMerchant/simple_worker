import 'package:simple_worker/simple_worker.dart';
import 'package:test/test.dart';

void main() async {
  test('SimpleWorker',() async {
    SimpleWorker worker = SimpleWorker();
    expect(await worker.compute(addString, data0: 'One and ', data1: 'Two'), 'One and Two');
  });

  test('Completed by default', () {
    SimpleWorker worker = SimpleWorker();
    expect(worker.isCompleted, true);
  });

  test('WorkerGroup',() async {

    List<WorkerResult> tests = [WorkerResult(),WorkerResult(),WorkerResult()];
    WorkerGroup zeGroup = WorkerGroup(maxIsolates: 2);
    await zeGroup.compute<WorkerResult>(tests, addWorkerResult);
    for(WorkerResult result in tests) {
      expect(result.workerResult, 'Done!');
      expect(result.workerDone, true);
    }

    zeGroup.dispose();

  });

  test('Isolate.exit()',() async {
    int amount = 100;
    List<BigData> data = await SimpleWorker.computeOnce(BigData.getLotsOfData, maxDelayInMilliseconds: 100000, data0: amount, data1: amount);
    //print('Back to main Isolate at ${DateTime.now()}');
    expect(data.length, amount);
    expect(data[50].dateTimes.length, amount);
  });

}

String addString(String one, String two) => one + two;

WorkerResult addWorkerResult(WorkerResult w) {
  w.workerResult = 'Done!';
  w.workerDone = true;
  return w;
}

class BigData {
  List<String> strings = [];
  List<int> ints = [];
  List<DateTime> dateTimes = [];
  List<Duration> durations = [];

  BigData();
  BigData.withInit([int length = 1000]) {
    initLotsOfData(length);
  }

  void initLotsOfData([int length = 1000]) {
    for(int i = 0; i < length; i++) {
      strings.add('value : $i');
      ints.add(i);
      dateTimes.add(DateTime(i));
      durations.add(Duration(hours: i));
    }
  }

  static List<BigData> getLotsOfData([int length = 1000, int dataLength = 1000]) => List<BigData>.generate(length, (index) => BigData.withInit(dataLength));
}