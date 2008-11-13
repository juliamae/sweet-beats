#!/usr/local/bin/macruby
require 'hotcocoa'

class Application

  include HotCocoa
  
  attr_accessor :measure
  
  def start
    self.measure = [false] * 16
    
    application :name => "Sweet-beats" do |app|
      app.delegate = self
      window :size => [800, 200], :title => "Sweet-beats", :view => :nolayout do |win|
        # win << label(:text => "Hello from HotCocoa", :layout => {:start => false})

        16.times do |i|
          # x pos, y pos, width, height
          b = button :title => "#{i}", :type => :push_on_push_off, :bezel => :textured_rounded, :frame => [10 + (30 * i), 10, 30, 30]
          b.on_action { self.measure[i] = b.on?; puts self.measure }
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