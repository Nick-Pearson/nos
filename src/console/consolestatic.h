#pragma once

// basic console for displaying ascii strings
// simple static version for early part of the kernel when there is no memory management set up
// no support for user input, history etc.
class ConsoleStatic
{
public:
  static void init();

  static void writeLn(const char* text);
  static void clearScreen();

  static unsigned char color;

private:

  static inline bool isPrintableChar(char c)
  {
    return c >= 0x20 && c <= 0x7E;
  }

  //shortcut for moving the cursor to the next line
  static void newline();

  static void advanceCursor(unsigned int change);

private:
  static unsigned int cursorLoc;

  static constexpr unsigned short* displayPtr = (unsigned short*)0xB8000;
  static constexpr unsigned int displayX = 80;
  static constexpr unsigned int displayY = 25;

};
