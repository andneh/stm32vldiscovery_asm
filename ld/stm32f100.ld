ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 8K
    FLASH (rx) : ORIGIN = 0x80000000, LENGTH = 128K
}

SECTIONS
{
    .text : {
        *(.text)
		*(.RCC_CR)
    } > FLASH

    .data : {
        *(.data)
    } > RAM AT > FLASH

    .bss : {
        *(.bss)
    } > RAM
}