idr = 0

while 1:
    r1 = 0x000 # button state
    r2 = 0x000 # time state
    r3 = 0x000 # led8 state
    r4 = 0x000 # led9 state

    if idr == 1:                    # check if button pressed
        on9()                       # turn on led9

        if r1 == 0x1000:            # if button was pressed before
            r1 = r1 + 1             # each 25ms +1 bit of button time state
            if r1 == 0x1000+4:      # 1 second after button pressed bit
                r2 = 0x3            # set time state to 3 seconds
            if r1 == 0x1000+4*3:    # 3 second after button pressed bit
                r2 = 0x10           # set time state to 10 seconds

        if r1 == 0x0000:            # if button was not pressed before
            r1 = r1 + 0x1000        # button pressed bit



    if idr == 0:                    # button not pressed
        if r1 == 0x1000:            # if button was pressed bit
            r1 = 0x01000            # set button released bit
            on8()                   # turn on led8

        if r1 = 0x01000:            # if button was released bit
            r1 = 0x000              # reset button state

    if r1 = 0x01000:                # button released bit
        on8()                       # turn on led8
        if r2 == 0x3:               # 3 second time state


    if r2 == 0x12:                   # 6 second time state
        off8()                       # turn on led8

    if r2 == 0x10:                 # 10 second time state
        on8()                   # toogle led8

    if r2 == 0x8:                   # 4 second time state
        off8()                       # turn on led8

    if r2 == 0x6:                   # 3 second time state
        on8()                   # toogle led8

    if r2 == 0x4:                   # 2 second time state
        off8()                       # turn on led8

    if r2 == 0x2:                   # 1 second time state
        on8()                   # toogle led8

    if r2 == 0x0:                   # 0 second time state
        off8()                   # toogle led8




    r2  = r2 - 1                    # each 25ms -1 bit of time state

    delay(25)                   # 25ms delay