require "./cryds/arm7"
require "./cryds/arm9"
require "./cryds/bus"
require "./cryds/display_engine"
require "./cryds/gui"

module CryDS
  VERSION = "0.1.0"
  extend self

  def run
    rom = File.read("./roms/redpanda.nds").bytes

    displayEngineA = DisplayEngineA.new

    bus = Bus.new(rom, displayEngineA)
    debug = false
    arm7 = Arm7.new(bus)
    arm9 = Arm9.new(bus, debug)

    gui = Gui.new(arm9.get_reg_pointer, arm7.getRegPointer, arm9.get_sp_irq_pointer, arm9.get_sp_usr_pointer, displayEngineA.get_vrama_pointer, arm9.get_debug_args_pointer)

    runtime = 0

    while true
      elapsed_time = Time.measure do
        while arm7.running && arm9.running
          elapsed_time_run = Time.measure do
            #arm7.run
            arm9.run
            arm9.run
          end

          runtime += elapsed_time_run.nanoseconds
          if runtime >= 5000000 #16666666
            gui.updateScreen
            runtime = 0
          end

          if gui.loadRom
            rom = File.read("./roms/#{gui.getRomName}").bytes

            displayEngineA = DisplayEngineA.new

            bus = Bus.new(rom, displayEngineA)
            arm7 = Arm7.new(bus)
            arm9 = Arm9.new(bus, debug)
            gui.setPointers(arm9.get_reg_pointer, arm7.getRegPointer, arm9.get_sp_irq_pointer, arm9.get_sp_usr_pointer, displayEngineA.get_vrama_pointer, arm9.get_debug_args_pointer)
          end

          if gui.debug
            debug = !debug
            arm9.toggleDebug
            gui.debugFalse
          end
          if !gui.running
            arm9.stop
          end
        end
      end

      runtime += elapsed_time.nanoseconds
      if runtime >= 5000000 #16666666
        gui.updateScreen
        runtime = 0
      end
      if gui.loadRom
        rom = File.read("./roms/#{gui.getRomName}").bytes

        displayEngineA = DisplayEngineA.new

        bus = Bus.new(rom, displayEngineA)
        arm7 = Arm7.new(bus)
        arm9 = Arm9.new(bus, debug)
        gui.setPointers(arm9.get_reg_pointer, arm7.getRegPointer, arm9.get_sp_irq_pointer, arm9.get_sp_usr_pointer, displayEngineA.get_vrama_pointer, arm9.get_debug_args_pointer)
      end
    end
  end
end

CryDS.run
