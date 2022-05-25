import 'package:simple_worker/simple_worker.dart';

void main() async {
  print(await SimpleWorker().compute(bigTask, data0: 'param'));
}

String bigTask(String param) => '$param $param';