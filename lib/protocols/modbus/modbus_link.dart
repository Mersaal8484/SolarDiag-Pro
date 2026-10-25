abstract interface class ModbusLink {
  Future<List<int>> exchange(List<int> request, {required Duration timeout});
}

abstract interface class ModbusRtuResponder {
  List<int> respondRtu(List<int> requestBytes);
}

abstract interface class ModbusByteTransport {
  Stream<List<int>> exchange(List<int> request);
}
