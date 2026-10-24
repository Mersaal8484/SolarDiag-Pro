abstract interface class ModbusLink {
  Future<List<int>> exchange(
    List<int> request, {
    required Duration timeout,
  });
}

abstract interface class ModbusByteTransport {
  Stream<List<int>> exchange(List<int> request);
}
