require 'gosu'

class Game < Gosu::Window
    def initialize
        super(800, 600, false)  # creates 800x600 window
    end
  
    def update
        # Called 60 times/second. Manage game state here
    end
  
    def draw
        # Called 60 times/second, if performance allows.
        # Draw the entire screen here. You can skip by
        # overriding Gosu::Window::needs_redraw? to improve
        # performance.
    end

    def button_down id
        # Quit the program if user hits 'Q' or Escape key
        close if id == Gosu::KbEscape or id == Gosu::KbQ 
    end
end
  
Game.new.show