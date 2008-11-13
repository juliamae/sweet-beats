require 'dl/import'

class LiveMIDI
  ON  = 0x90
  OFF = 0x80
  PC  = 0xC0
  
  attr_reader :interval

  def initialize(bpm=120)
    @interval = 60.0 / bpm
    @timer = Timer.get( @interval/10 )
    open
  end

  def note_on(channel, note, velocity=64)
    message(ON | channel, note, velocity)
  end

  def note_off(channel, note, velocity=64)
    message(OFF | channel, note, velocity)
  end

  def program_change(channel, preset)
    message(PC | channel, preset)
  end
  
  def play(channel, note, duration, velocity=100, time=nil)
    on_time = time || Time.now.to_f
    @timer.at(on_time) { note_on(channel, note, velocity) }
    
    off_time = on_time + duration
    @timer.at(off_time) { note_off(channel, note, velocity) }
  end
  
  ##
  module C
    extend DL::Importable
    dlload '/System/Library/Frameworks/CoreMIDI.framework/Versions/Current/CoreMIDI'

    extern "int MIDIClientCreate(void *, void *, void *, void *)"
    extern "int MIDIClientDispose(void *)"
    extern "int MIDIGetNumberOfDestinations()"
    extern "void * MIDIGetDestination(int)"
    extern "int MIDIOutputPortCreate(void *, void *, void *)"
    extern "void * MIDIPacketListInit(void *)"
    extern "void * MIDIPacketListAdd(void *, int, void *, int, int, int, void *)"
    extern "int MIDISend(void *, void *, void *)"
  end

  module CF
    extend DL::Importable
    dlload '/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation'

    extern "void * CFStringCreateWithCString (void *, char *, int)"
  end

  def open
    client_name = CF.cFStringCreateWithCString(nil, "RubyMIDI", 0)
    @client = DL::PtrData.new(nil)
    C.mIDIClientCreate(client_name, nil, nil, @client.ref);

    port_name = CF.cFStringCreateWithCString(nil, "Output", 0)
    @outport = DL::PtrData.new(nil)
    C.mIDIOutputPortCreate(@client, port_name, @outport.ref);

    num = C.mIDIGetNumberOfDestinations()
    @destination = C.mIDIGetDestination(0)
  end

  def close
    C.mIDIClientDispose(@client)
  end

  def message(*args)
    format = "C" * args.size
    bytes = args.pack(format).to_ptr
    packet_list = DL.malloc(256)
    packet_ptr  = C.mIDIPacketListInit(packet_list)
    # Pass in two 32 bit 0s for the 64 bit time
    packet_ptr  = C.mIDIPacketListAdd(packet_list, 256, packet_ptr, 0, 0, args.size, bytes)
    C.mIDISend(@outport, @destination, packet_list)
  end
end

class Timer
  def initialize(resolution)
    @resolution = resolution
    @queue = []

    Thread.new do
      while true
        dispatch
        sleep(@resolution)
      end
    end
  end

  def at(time, &block)
    time = time.to_f if time.kind_of?(Time)
    @queue.push [time, block]
  end
  
  def self.get(interval)
    @timers ||= {}
    return @timers[interval] if @timers[interval]
    return @timers[interval] = self.new(interval)  
  end

  private
  def dispatch
    now = Time.now.to_f
    ready, @queue = @queue.partition{|time, proc|  time <= now }
    ready.each {|time, proc| proc.call(time) }
  end
end

class Metronome
  def initialize(bpm)
    @midi = LiveMIDI.new
    @midi.program_change(0, 115)
    @interval = 60.0 / bpm
    @timer = Timer.get(@interval/10)
    now = Time.now.to_f
    register_next_bang(now)
  end
	
  def register_next_bang(time)
    @timer.at(time) do
      now = Time.now.to_f
      register_next_bang(now + @interval)
      bang
    end
  end

  def bang
    @midi.play(0, 84, 0.1, 100, Time.now.to_f + 0.2)
  end
end

module Enumerable
  def rest
    return [] if empty?
    self[1..-1]
  end
end

class Pattern
  def initialize(base, string)
    @base = base
    @seq = parse(string)
  end

  def [](index)
    value, duration = @seq[index % @seq.size]
    return value, duration if value.nil?
    return @base + value, duration
  end

  def size
   return @seq.size
  end

  private
  def parse(string)
    characters = string.split(//)
    no_spaces = characters.grep(/\S/)
    return build(no_spaces)
  end

  def build(list)
    return [] if list.empty?
    duration = 1 + run_length(list.rest)
    value = case list.first
      when /-|=/ then nil
      when /\D/ then 0
      else list.first.to_i
    end
    return [[value, duration]] + build(list.rest)
  end

  def run_length(list)
    return 0 if list.empty?
    return 0 if list.first != "="
    return 1 + run_length(list.rest)
  end
  
end

class SongPlayer
  def initialize(player, bpm, pattern)
    @player = player
    @interval = 60.0 / bpm
    @pattern = Pattern.new(60, pattern)
    @timer = Timer.get(@interval / 10)
    @count = 0
    play(Time.now.to_f)
  end

  def play(time)
    note, duration = @pattern[@count]
    @count += 1
    return if @count >= @pattern.size

    length = @interval * duration - (@interval * 0.10)
    @player.play(0, note, length) unless note.nil?
    @timer.at(time + @interval) {|at| play(at) }
  end
end

class Tapper
  def initialize(player, length, base, pattern)
    @player = player
    @length = length
    @pattern = Pattern.new(base, pattern)
    @count = 0
  end

  def run
    while true
      gets
      note, duration = @pattern[@count]
      @player.play(0, note, @length * duration) if note
      @count += 1
    end
  end
end
