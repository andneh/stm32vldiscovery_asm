idr = 0

while 1:
    r1 = 0x000 # button state
    r2 = 0x000 # time state
    r3 = 0x000 # led8 state

    if idr == 1:
        r1 = r1 + 0x1000        # button pressed bit
        on9()                   # turn on led9
        if r1 == 0x1000+4:      # 1 second after button pressed bit
            r2 = 0x3            # set time state to 3 seconds
        if r1 == 0x1000+4*3:    # 3 second after button pressed bit
            r2 = 0x10           # set time state to 10 seconds
        r1 = r1 + 1             # each 25 second +1 bit of button time state

    else:
        if r1 = 0x1000:         # check if button pressed bit
            r1 = 0x01000        # set button released bit
        if r1 = 0x01000:        # check if button released bit
            r1 = 0x000          # reset button state

    if r1 = 0x01000:            # button released bit
        on8()                   # turn on led8
        if r2 == 0x3:           # 3 second time state