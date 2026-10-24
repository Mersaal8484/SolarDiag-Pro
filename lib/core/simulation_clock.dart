abstract interface class SimulationClock {
  int get tick;
  set tick(int value);
  void advance();
}
