/* Linker script for STM32F103C8T6 */

MEMORY
{
    FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 64K
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 20K
}

ENTRY(reset_handler)

SECTIONS
{
  .text :
  {
    *(.text)
    *(.text.*)

    *(.rodata)
    *(.rodata*)

    *(.vectors)
  } > FLASH

  .data :
  {
    *(.data)
  } > RAM AT > FLASH

  .bss :
  {
    *(.bss)
  } > RAM
}
