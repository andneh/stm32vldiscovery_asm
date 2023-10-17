# Enable the TUI layout
layout

# Split the screen horizontally (you can also use 'vertical' for a vertical split)
layout split

# Enable source code and assembly view in the TUI layout
tui enable

# Set the source code window to be larger
#tui src

# Optionally, you can add keybindings to switch between layouts
define keybindings
  # Switch to the source view
  tui source
  tui reg float
  tui reg general
end

# Load the keybindings
#document tui reg float TUI register float layout
#document tui reg general TUI register general layout
#end
