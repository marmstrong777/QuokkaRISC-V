#include <stdint.h>
#include <stddef.h>

#include "quokka_rv.h"

// Display a banner that bounces across the screen.

char *banner[] = {
    "  ___              _    _         ____  ___ ____   ____   __     __",
    " / _ \\ _   _  ___ | | _| | ____ _|  _ \\|_ _/ ___| / ___|  \\ \\   / /",
    "| | | | | | |/ _ \\| |/ / |/ / _` | |_) || |\\___ \\| |   ____\\ \\ / / ",
    "| |_| | |_| | (_) |   <|   < (_| |  _ < | | ___) | |__|_____\\ V /  ",
    " \\__\\_\\\\__,_|\\___/|_|\\_\\_|\\_\\__,_|_| \\_\\___|____/ \\____|     \\_/   ",
};

#define BANNER_WIDTH 68
#define BANNER_HEIGHT 5

void BusyWait(uint32_t num_loops)
{
   for (volatile size_t i = 0; i < num_loops; i++)
   {
      i++;
   }

   return;
}

void ColourWheel(uint8_t pos, uint8_t *red, uint8_t *green, uint8_t *blue)
{
   if (pos < 85)
   {
      *red = pos * 3;
      *green = 255 - pos * 3;
      *blue = 0;
   }
   else if (pos < 170)
   {
      pos -= 85;
      *red = 255 - pos * 3;
      *green = 0;
      *blue = pos * 3;
   }
   else
   {
      pos -= 170;
      *red = 0;
      *green = pos * 3;
      *blue = 255 - pos * 3;
   }
}

#define TIMER_PERIOD 50000000

void TimerInterruptHandler()
{
   CpuTimerSetMtime(0);

   static uint8_t bg_red = 0;
   static uint8_t bg_green = 0;
   static uint8_t bg_blue = 0;

   bg_red += 10;
   bg_green = bg_red;
   bg_blue = bg_red;

   CharDisplaySetBackgroundColour((volatile char *)CHAR_DISPLAY_BASE, bg_red, bg_green, bg_blue);

   if (bg_red > 50)
   {
      bg_red = 0;
   }
}

__attribute__((interrupt)) void TrapHandler()
{
   static int interrupt_count = 0;

   interrupt_count++;

   uint32_t mcause = GetMcause();

   if (mcause == CSR_MCAUSE_TIMER_M)
   {
      TimerInterruptHandler();
   }
}

int main()
{
   void (*trap_handler_addr)(void) = &TrapHandler;
   // REFACTOR Define a function.
   asm volatile("csrw mtvec, %0" ::"r"(trap_handler_addr));

   CpuTimerSetMtime(0);
   CpuTimerSetMtimecmp(TIMER_PERIOD);

   EnableTimerInterrupts();
   EnableGlobalInterrupts();

   volatile char *display_base = (volatile char *)CHAR_DISPLAY_BASE;

   uint8_t red, green, blue;
   uint8_t colour_pos = 0;

   int32_t x_offset = 0;
   int32_t y_offset = 0;

   int32_t x_vel = 1;
   int32_t y_vel = 1;

   while (1)
   {
      CharDisplayClear(display_base, ' ');

      for (uint32_t i = 0; i < BANNER_HEIGHT; i++)
      {
         CharDisplayWriteString(display_base, banner[i], x_offset, y_offset + i);
      }

      x_offset += x_vel;
      y_offset += y_vel;

      if (x_offset >= (CHAR_DISPLAY_WIDTH_CHARS - BANNER_WIDTH))
      {
         x_vel = -1;
      }
      else if (x_offset <= 0)
      {
         x_vel = 1;
      }

      if (y_offset >= (CHAR_DISPLAY_HEIGHT_CHARS - BANNER_HEIGHT))
      {
         y_vel = -1;
      }
      else if (y_offset <= 0)
      {
         y_vel = 1;
      }

      for (uint32_t i = 0; i < 8; i++)
      {
         ColourWheel(colour_pos, &red, &green, &blue);
         CharDisplaySetFontColour(display_base, red, green, blue);
         colour_pos++;

         BusyWait(60000);
      }
   }

   return 0;
}
