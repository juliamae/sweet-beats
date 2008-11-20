# pulled from midi.rb

class BpmTimer
  def initialize(bpm, &block)
    @bpm = bpm
    @queue = []
    @block = block

    @t = Thread.new do 
    end.exit
  end

  def on?
    @t.alive?
  end
  
  def toggle
    on? ? stop : start
  end
  
  def start
    @t = Thread.new do
      while true
        @block.call
        # dispatch
        sleep(60.0 / @bpm)
      end
    end
  end
  
  def stop
    @t.exit
  end

  # def at(time, &block)
  #   time = time.to_f if time.kind_of?(Time)
  #   @queue.push [time, block]
  # end
  # 
  # def self.get(interval)
  #   @timers ||= {}
  #   return @timers[interval] if @timers[interval]
  #   return @timers[interval] = self.new(interval)  
  # end
  # 
  # private
  # 
  #   def dispatch
  #     now = Time.now.to_f
  #     ready, @queue = @queue.partition{|time, proc|  time <= now }
  #     ready.each {|time, proc| proc.call(time) }
  #   end

end
