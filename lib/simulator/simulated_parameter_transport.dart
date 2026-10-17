part of '../parameters/write_pipeline.dart';

ParameterTransport createSimulatedParameterTransport({
  required ParameterReader read,
  required ConfigurationReader readAll,
  required ParameterWriter write,
}) => ParameterTransport._simulator(read: read, readAll: readAll, write: write);
