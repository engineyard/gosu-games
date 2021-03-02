require 'gosu'
require 'net/http'
require 'json'
require 'date'

X_INTERVAL_PIXELS = 20
X_INTERVAL_SECONDS = 30
X_INTERVALS_TOTAL = 600 / X_INTERVAL_PIXELS
VISIBLE_TIME_SECONDS = X_INTERVALS_TOTAL * X_INTERVAL_SECONDS
HH_MM_SS_FORMAT = "%k:%M:%S"
MM_SS_FORMAT = "%M:%S"

class BitcoinPrice 
    attr_accessor :price  
    attr_accessor :time 
    attr_accessor :center_x, :center_y
    attr_accessor :predition_bottom, :predition_top

    def initialize(price, time = Time.now)
        @price = price 
        @time = time 
    end 
end 

def time_display(t = Time.now)
    t.strftime(HH_MM_SS_FORMAT) 
end

def get_bitcoin_price
    # Data returned from the Coinbase API is of the form:
    # {"trade_id":138743100,"price":"48193.54","size":"0.0001864","time":"2021-02-26T16:58:31.604327Z",
    #  "bid":"48193.53","ask":"48193.54","volume":"39188.75217871"}
    data = Net::HTTP.get(URI("https://api.pro.coinbase.com/products/BTC-USD/ticker"))
    JSON.parse(data)["price"].to_f
end

class Game < Gosu::Window
    def initialize
        super(800, 600, false)
        self.caption = "The Bitcoin Game"
        @font = Gosu::Font.new(32)
        @messages = ["Click on the graph to make a prediction."]
        @white_background = Gosu::Image.new("./images/WhiteBackground.png")
        @bitcoin = Gosu::Image.new("./images/bitcoin.png")
        @prices = []
        @prediction = nil
        @update_count = 0
        @result = nil
    end
  
    def update
        @update_count = @update_count + 1

        if @prices.empty? or (@update_count % 1800 == 0)  # approx every 30 seconds 
            @prices << BitcoinPrice.new(get_bitcoin_price)
        end

        first_price = @prices[0].price
        five_percent = first_price * 0.05
        @top_price = first_price + five_percent
        @bottom_price = first_price - five_percent
        @price_range = @top_price - @bottom_price

        @y_axis_labels = []
        @y_axis_labels << @top_price.round(2)
        @y_axis_labels << (@top_price - (@price_range * 0.25)).round(2)
        @y_axis_labels << first_price.round(2)
        @y_axis_labels << (@top_price - (@price_range * 0.75)).round(2)
        @y_axis_labels << @bottom_price.round(2)

        @start_time = @prices[0].time 
        @x_axis_labels = []
        @x_axis_labels << @start_time.strftime(MM_SS_FORMAT) 
        @x_axis_labels << (@start_time + (VISIBLE_TIME_SECONDS * 0.25).round).strftime(MM_SS_FORMAT)
        @x_axis_labels << (@start_time + (VISIBLE_TIME_SECONDS * 0.5).round).strftime(MM_SS_FORMAT)
        @x_axis_labels << (@start_time + (VISIBLE_TIME_SECONDS * 0.75).round).strftime(MM_SS_FORMAT)
        @x_axis_labels << (@start_time + VISIBLE_TIME_SECONDS).strftime(MM_SS_FORMAT)

        running_x = 205
        @prices_to_draw = @prices.last(10)
        @prices_to_draw.each do |price|
            price.center_x = running_x
            running_x = running_x + X_INTERVAL_PIXELS
            y_pct = (price.price - @bottom_price) / @price_range 
            price.center_y = 400 - (400.to_f * y_pct).round
        end

        # Three possibilities here
        if @prediction.nil? 
            # 1. User has not made a prediction yet
            @messages = ["Click on the graph to make a prediction."]
            if is_cursor_on_graph
                @messages << "Higlighted price: $#{cursor_price}" 
            end 
        else 
            prediction_msg = "You predicted $#{@prediction.price} at #{@prediction.time.strftime(MM_SS_FORMAT)}"
            if @prediction.time > @prices_to_draw.last.time
                # 2. User made a prediction and we are waiting to see if it comes true
                @messages = [prediction_msg]
            else 
                # 3. User made a prediction and the time has arrived
                # We actually check the price within a range, about the size of the Bitcoin image
                if @result.nil?
                    current_price = @prices_to_draw.last.price
                    if current_price >= @prediction.predition_bottom and current_price <= @prediction.predition_top 
                        @messages = [prediction_msg, "YOU WON!!! The price was $#{current_price}"]
                        @result = "WINNER !!!"
                    else
                        @messages = [prediction_msg, "Sorry, the price was $#{current_price}"] 
                        @result = "BETTER LUCK NEXT TIME :-)"
                    end
                end
            end
        end
    end
  
    def draw
        draw_line 200,0, Gosu::Color::GREEN, 200, 400, Gosu::Color::GREEN
        draw_line 200,400, Gosu::Color::GREEN, 800, 400, Gosu::Color::GREEN
        if @prediction 
            @bitcoin.draw @prediction.center_x - 25, @prediction.center_y - 37, 1
        end
        if is_cursor_on_graph and @prediction.nil?
            draw_line mouse_x, 0, Gosu::Color::YELLOW, mouse_x, 399, Gosu::Color::YELLOW
            draw_line 201, mouse_y, Gosu::Color::GREEN, 799, mouse_y, Gosu::Color::GREEN
        end 

        y = 0
        @y_axis_labels.each do |label|
            draw_line 180, y, Gosu::Color::WHITE, 200, y, Gosu::Color::GREEN
            @font.draw_text("$#{label}", 36, (y == 0 ? 0 : y - 16), 1, 1, 1, Gosu::Color::GREEN)
            y = y + 100
        end

        x = 200
        @x_axis_labels.each do |label|
            draw_line x, 400, Gosu::Color::YELLOW, x, 420, Gosu::Color::WHITE
            @font.draw_text(label, (x > 700 ? 730 : x - 38), 426, 1, 1, 1, Gosu::Color::YELLOW)
            x = x + 150
        end

        last_price = 0
        @prices_to_draw.each do |price|
            color_to_draw = last_price > price.price ? Gosu::Color::RED : Gosu::Color::GREEN
            draw_rect(price.center_x - 4, price.center_y - 4, 8, 8, color_to_draw, 2) 
            last_price = price.price
        end

        if @prices_to_draw.length > 1
            @prices_to_draw.inject(@prices_to_draw[0]) do |last, the_next|
                color_to_draw = last.price > the_next.price ? Gosu::Color::RED : Gosu::Color::GREEN
                draw_line last.center_x, last.center_y, color_to_draw,
                        the_next.center_x, the_next.center_y, color_to_draw, 2
                the_next
            end
        end

        @white_background.draw 0, 500, 0
        current_price = @prices_to_draw.last 
        @font.draw_text("Last BTC:", 10, 568, 1, 1, 1, Gosu::Color::BLACK)
        @font.draw_text("$#{current_price.price}", 146, 568, 1, 1, 1, Gosu::Color::BLUE)
        @font.draw_text("(#{time_display(current_price.time)})", 282, 568, 1, 1, 1, Gosu::Color::BLACK)
        @font.draw_text(time_display, 688, 568, 1, 1, 1, Gosu::Color::BLUE)
        y = 504
        @messages.each do |msg|
            @font.draw_text(msg, 10, y, 1, 1, 1, Gosu::Color::BLACK)
            y = y + 32
        end 
        @font.draw_text(@result, 330, 460, 1, 1, 1, Gosu::Color::WHITE) unless @result.nil?
    end

    def is_cursor_on_graph
        mouse_x > 199 and mouse_y < 400 
    end 

    def cursor_price 
        pct = (400 - mouse_y).to_f / 400.to_f
        (@bottom_price + (pct * @price_range)).round(2)
    end 

    def button_down id
        close if id == Gosu::KbEscape or id == Gosu::KbQ
        if id == Gosu::MsLeft
            if is_cursor_on_graph
                if @prediction.nil?
                    pct = (mouse_x - 200).to_f / 600.to_f
                    click_time = Time.at(@start_time.to_i + (pct * VISIBLE_TIME_SECONDS))
                    click_price = cursor_price
                    @prediction = BitcoinPrice.new(click_price, click_time)
                    @prediction.center_x = mouse_x
                    @prediction.center_y = mouse_y
                    nine_percent_of_range = @price_range * 0.09
                    @prediction.predition_bottom = click_price - nine_percent_of_range
                    @prediction.predition_top = click_price + nine_percent_of_range
                    puts "Prediction range: #{@prediction.predition_bottom} - #{@prediction.predition_top}"
                else 
                    @prediction = nil
                    @result = nil
                end
            end
        end
    end
end
  
Game.new.show