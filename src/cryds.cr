require "./cryds/arm7"
require "./cryds/arm9"
require "./cryds/bus"
require "./cryds/display_engine"

module CryDS
  VERSION = "0.1.0"
  extend self

  def run
    rom = File.read("./roms/armwrestler.nds").bytes

    displayEngineA = DisplayEngineA.new

    bus = Bus.new(rom, displayEngineA)
    arm7 = Arm7.new(bus)
    arm9 = Arm9.new(bus)
    runtime = 0
    while arm7.running && arm9.running
      elapsed_time = Time.measure do
        arm7.run
        arm9.run
        arm9.run
      end
      runtime += elapsed_time.nanoseconds
      if runtime >= 16666666
        displayEngineA.updateScreen
        runtime = 0
      end
    end
  end
end

CryDS.run
