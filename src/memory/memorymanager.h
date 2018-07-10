#pragma once

class MemoryManager
{
public:

  virtual ~MemoryManager() {}

  static MemoryManager* init();

private:
  MemoryManager() {}
};
