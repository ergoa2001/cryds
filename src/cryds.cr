require "./cryds/arm7"
require "./cryds/arm9"
require "./cryds/bus"
require "./cryds/display_engine"
require "./cryds/gui"

module CryDS
  VERSION = "0.1.0"
  extend self



  def run
    gui = Gui.new

    rom = File.read("./roms/redpanda.nds").bytes

    displayEngineA = DisplayEngineA.new

    bus = Bus.new(rom, displayEngineA)
    debug = false
    arm7 = Arm7.new(bus)
    arm9 = Arm9.new(bus, debug)

    runtime = 0
    while arm7.running && arm9.running
      elapsed_time = Time.measure do
        arm7.run
        arm9.run
        arm9.run
      end
      runtime += elapsed_time.nanoseconds
      if runtime >= 5000000 #16666666
        gui.updateScreen(arm9.getRegs, arm7.getRegs, displayEngineA.getPixels)
        runtime = 0
      end

      if gui.loadRom
        rom = File.read("./roms/#{gui.getRomName}").bytes

        displayEngineA = DisplayEngineA.new

        bus = Bus.new(rom, displayEngineA)
        arm7 = Arm7.new(bus)
        arm9 = Arm9.new(bus, debug)
      end

      if gui.debug
        debug = !debug
        arm9.toggleDebug
        gui.debugFalse
      end
    end
  end
end

CryDS.run
