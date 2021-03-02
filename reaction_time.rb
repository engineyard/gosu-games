require 'gosu'

AVERAGE_RESPONSE_TIME = 284.to_f     # Per humanbenchmark.com, in milliseconds

class Game < Gosu::Window
    def initialize
        super(800, 600, false)
        self.caption = "Reaction Time Game"
        @font = Gosu::Font.new(32)
        @city_background = Gosu::Image.new("./images/Background.png")
        @red_light = Gosu::Image.new("./images/RedLight.png")
        @yellow_light = Gosu::Image.new("./images/YellowLight.png")
        @green_light = Gosu::Image.new("./images/GreenLight.png")
        @messages = ["Press 's' to start"]
        @update_count = 0
        @next_light_count = 0
        @traffic_light_color = 0
        #  traffic_light_color   0           1           2              3             4
        #  state                 Ready       Red         Yellow         Green         Game over
        @traffic_light_images = [@red_light, @red_light, @yellow_light, @green_light, @green_light]
    end
  
    def update
        @update_count = @update_count + 1
        @traffic_light_image = @traffic_light_images[@traffic_light_color]

        if @traffic_light_color == 0
            @messages = ["Press 's' to start"]
        else
            next_traffic_light unless @update_count < @next_light_count
            @messages = ["Hit the space bar", "when the light turns green"] unless @traffic_light_color > 2
        end
    end
  
    def draw
        @city_background.draw 0, 0, 0
        @font.draw_text("Reaction Time Game", 520, 10, 1)
        y = 10
        @messages.each do |msg|
            @font.draw_text(msg, 20, y, 1)
            y = y + 32
        end 
        @traffic_light_image.draw 348, 156, 1
    end

    def button_down id
        close if id == Gosu::KbEscape or id == Gosu::KbQ 

        if id == Gosu::KbS 
            if @traffic_light_color >= 3
                @traffic_light_color = 0
            end
            @game_start_time = Time.now
            next_traffic_light

        elsif id == Gosu::KbReturn or id == Gosu::KbSpace
            if @traffic_light_color == 3
                time_since_green = ((Time.now - @mark_time) * 1000.to_f).round(3)
                @messages = ["Response time: #{time_since_green} ms"]
                diff_from_average = (((time_since_green - AVERAGE_RESPONSE_TIME) / AVERAGE_RESPONSE_TIME) * 100).round
                if diff_from_average > 0
                    @messages << "#{diff_from_average}% slower than the average human"
                elsif diff_from_average < 0
                    @messages << "#{-diff_from_average}% faster than the average human"
                else 
                    @messages << "Wow, that is exactly the human average."
                end 
                @messages << "'q' to quit, 's' to play again"
            else 
                @traffic_light_color = 4
                @messages = ["Sorry, you were too early", "'q' to quit, 's' to play again"]
            end 
        end
    end

    def next_traffic_light 
        return unless @traffic_light_color < 3
        @traffic_light_color = @traffic_light_color + 1
        @mark_time = Time.now
        @next_light_count = @update_count + 60 + rand(100)
    end
end
  
Game.new.show