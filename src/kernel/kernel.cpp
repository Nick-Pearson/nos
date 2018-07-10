#include "kernel.h"

#include "../console/consolestatic.h"
#include "../memory/memorymanager.h"

Kernel* Kernel::kernel = nullptr;
MemoryManager* Kernel::mm = nullptr;

void Kernel::KernelMain()
{
  ConsoleStatic::init();

  ConsoleStatic::writeLn("Entering KernelMain");

  mm = MemoryManager::init();

  while(true)
  {
      ;
  }
}
