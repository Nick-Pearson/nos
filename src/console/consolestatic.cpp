#include "consolestatic.h"

unsigned char ConsoleStatic::color = 0x0F;
unsigned int ConsoleStatic::cursorLoc = 0;

void ConsoleStatic::init()
{
  clearScreen();
}

void ConsoleStatic::writeLn(const char* text)
{
  char c = *text;
  while(c != 0)
  {
    if(isPrintableChar(c))
    {
      displayPtr[cursorLoc] = (color << 8) | c;
      advanceCursor(1);
    }
    else if(c == '\n')
    {
      newline();
    }

    c = *(++text);
  }

  newline();
}

void ConsoleStatic::clearScreen()
{
  cursorLoc = 0;
  unsigned int DisplaySize = displayX * displayY;

  for(unsigned int i = 0; i < DisplaySize; ++i)
  {
    displayPtr[i] = (color << 8);
  }
}

void ConsoleStatic::advanceCursor(unsigned int change)
{
  cursorLoc += change;
  unsigned int DisplaySize = displayX * displayY;

  while(cursorLoc > DisplaySize)
  {
    for(unsigned int i = 0; i < DisplaySize-displayX; ++i)
    {
      displayPtr[i] = displayPtr[i+displayX];
    }

    for(unsigned int i = DisplaySize - displayX; i < DisplaySize; ++i)
    {
      displayPtr[i] = (color << 8);
    }

    cursorLoc -= displayX;
  }
}

void ConsoleStatic::newline()
{
  advanceCursor(displayX - (cursorLoc%displayX));
}
