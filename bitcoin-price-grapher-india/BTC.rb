require 'rubygems'
require 'twitter'
require 'gruff'
require 'sinatra'
require 'securerandom'
require 'time'

set :server, 'webrick'

get '/' do
  chart = BTCChart.new
  cache_control :public, max_age: 900
  "<html><head><meta http-equiv='refresh' content='300'/></head><body>0.28 will cash out with #{chart.get_cash_out(0.28)} and 0.6242 will cash out with #{chart.get_cash_out(0.6242)}. Here is the latest chart<br/><img src='/graph' alt='BTC Graph'/></body></html>"
end

get '/graph' do
  cache_control :public, max_age: 900
  send_file "result.png", :filename => "BTC_price.png", :type => 'image/png'
end

class BTCChart
  def initialize
    client = Twitter::REST::Client.new do |config|
      # Put your own configs here
      config.consumer_key        = ""
      config.consumer_secret     = ""
      config.access_token        = ""
      config.access_token_secret = ""
    end
    timeline = client.user_timeline("BuySellBitcoinR")
    buy_price = Array.new
    sell_price = Array.new
    times = Array.new
    timeline.each do |tweet|
      #p tweet.inspect
      tokens = tweet.text.split(" ")
      buy_price.push tokens[7].to_i
      sell_price.push tokens[11].to_i
      tweet_time = Time.parse(tweet.created_at.to_s).utc + (5*3600 + 1800)
      times.push tweet_time.to_s.split(" ")[1][0..4]
      #puts "#{tweet_time} #{tokens[7]} #{tokens[11]}"
    end
    @latest_sell = sell_price[0].to_f
    graph = Gruff::Line.new(800, false)
    graph.title = "BuySellBitCo.In prices(by prab97)"
    graph.x_axis_label = "Time(In IST)"
    graph.y_axis_label = "Price(in Rs.)"
    graph.dataxy :Buy, (0..times.size-1).to_a, buy_price.reverse, "#000000"
    graph.dataxy :Sell, (0..times.size-1).to_a, sell_price.reverse, "#ffffff"
    labels = (0..times.size-1).step(2).to_a
    label_times = Array.new
    labels.each do |i|
      label_times.push times[i]
    end
    graph.labels = Hash[labels.zip label_times.reverse]
    graph.theme_rails_keynote
    graph.write "result.png"
  end

  def get_cash_out(value)
    price = @latest_sell * value
    puts "Price for #{value} @ #{@latest_sell} is #{price}"
    fees = (price * 3.0)/100.0
    puts "Fees at 3 percent for #{price} is #{fees}"
    (price - fees - 96.0).to_i
  end
end
