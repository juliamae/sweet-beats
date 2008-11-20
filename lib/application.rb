#!/usr/local/bin/macruby
require 'hotcocoa'
require 'bpm_timer'
# require 'midi'

class Application

  include HotCocoa
  
  attr_accessor :measure, :timer, :index
  
  def start
    self.measure = [false] * 16
    self.index = 0
    self.timer = BpmTimer.new(180) do
      puts self.index
      self.index += 1
      self.index %= measure.length
    end
    
    application :name => "Sweet-beats" do |app|
      app.delegate = self
      window :size => [800, 200], :title => "Sweet-beats", :view => :nolayout do |win|
        # win << label(:text => "Hello from HotCocoa", :layout => {:start => false})

        b = button(:title => "Play", :bezel => :textured_rounded, :frame => [10, 80, 50, 50])
        b.on_action { self.timer.toggle }
        win << b

        16.times do |i|
          # x pos, y pos, width, height
          b = button :title => "#{i}", :type => :push_on_push_off, :bezel => :textured_rounded, :frame => [10 + (30 * i), 10, 30, 30]
          b.on_action { |b| self.measure[i] = b.on? }
          win << b
        end

        16.times do |i|
          i = image_view :frame => [0, 0, 50, 50], :file => "/Users/luke/Desktop/haven_logo.png", :frame => [10 + (30 * i), 40, 30, 10]
          win << i
        end
        
        win.will_close { exit }
      end
    end
  end

  def play_song
    puts self.measure
    # bpm = 120
    # midi = LiveMIDI.new(bpm)
    # song = self.measure.map{|x| x ? "0" : "-"}.join("")
    # player = SongPlayer.new(midi, bpm, song)
    # player.play
  end
  
  # file/open
  def on_open(menu)
  end
  
  # file/new 
  def on_new(menu)
  end
  
  # help menu item
  def on_help(menu)
  end
  
  # This is commented out, so the minimize menu item is disabled
  #def on_minimize(menu)
  #end
  
  # window/zoom
  def on_zoom(menu)
  end
  
  # window/bring_all_to_front
  def on_bring_all_to_front(menu)
  end
end

Application.new.start