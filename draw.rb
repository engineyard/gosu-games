require 'gosu'

class Game < Gosu::Window
    def initialize
        super(800, 600, false)
        self.caption = "Your Drawing"
        @all_sets_of_points = []
        @current_set_of_points = nil
        @set_colors = [Gosu::Color::CYAN]
    end
  
    def update
        if @current_set_of_points 
            @current_set_of_points << [ mouse_x, mouse_y ]
            @current_set_of_points.shift if @current_set_of_points.size > 1000 
        end
    end
  
    def draw
        color_index = 0
        @all_sets_of_points.each do |set_of_points|
            set_of_points.inject(set_of_points[0]) do |last, point|
                draw_line last[0],last[1], @set_colors[color_index],
                          point[0],point[1], @set_colors[color_index]
                point
            end
            color_index += 1
        end
    end

    def button_down id
        close if id == Gosu::KbEscape or id == Gosu::KbQ
        if id == Gosu::MsLeft
            @current_set_of_points = []   # start a new set of lines
            @all_sets_of_points << @current_set_of_points
        elsif id == Gosu::KbB
            @set_colors[-1] = Gosu::Color::BLACK
        elsif id == Gosu::KbW
            @set_colors[-1] = Gosu::Color::WHITE
        elsif id == Gosu::KbC
            @set_colors[-1] = Gosu::Color::CYAN
        elsif id == Gosu::KbL
            @set_colors[-1] = Gosu::Color::BLUE
        elsif id == Gosu::KbG
            @set_colors[-1] = Gosu::Color::GREEN
        elsif id == Gosu::KbR
            @set_colors[-1] = Gosu::Color::RED
        elsif id == Gosu::KbY
            @set_colors[-1] = Gosu::Color::YELLOW
        end
    end

    def button_up id
        if id == Gosu::MsLeft
            @current_set_of_points = nil   # stop drawing for now
            @set_colors << @set_colors[-1]
        end
    end
end
  
Game.new.show