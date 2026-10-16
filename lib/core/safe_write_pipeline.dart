class WriteRequest {
  const WriteRequest({required this.parameter, required this.value});
  final String parameter;
  final double value;
}

class WritePolicy {
  const WritePolicy({
    required this.minimum,
    required this.maximum,
    required this.verifiedForHardware,
  });
  final double minimum;
  final double maximum;
  final bool verifiedForHardware;
}

class SafeWritePipeline {
  const SafeWritePipeline();
  bool canExecute(WriteRequest request, WritePolicy policy) =>
      policy.verifiedForHardware &&
      request.value >= policy.minimum &&
      request.value <= policy.maximum;
  Never directRawWrite() => throw StateError(
    'Raw writes are prohibited. Use a verified parameter policy.',
  );
}
