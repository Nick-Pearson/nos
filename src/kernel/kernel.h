#pragma once

class Kernel
{
public:
  static void KernelMain();

  static Kernel* kernel;

private:
  Kernel() {}
  ~Kernel() {}

  static class MemoryManager* mm;
};
