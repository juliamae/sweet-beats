#!/usr/local/bin/macruby
require 'hotcocoa'

class Application

  include HotCocoa
  
  attr_accessor :measure
  
  def start
    self.measure = [false] * 16
    
    application :name => "Sweet-beats" do |app|
      app.delegate = self
      window :frame => [100, 100, 800, 100], :title => "Sweet-beats" do |win|
        win << label(:text => "Hello from HotCocoa", :layout => {:start => false})

        win.view = layout_view :mode => :horizontal do |layout|
          layout.spacing = 0
          buttons = []
          16.times do |i|
            b = button :title => "#{i}", :type => :push_on_push_off, :bezel => :textured_rounded
            b.on_action { self.measure[i] = b.on?; puts self.measure }
            buttons << b
            layout << b
          end
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