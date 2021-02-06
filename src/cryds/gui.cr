
class Gui
  def initialize(arm9regs : Pointer(Array(UInt32)), arm7regs : Pointer(Array(UInt32)), sp_irq : Pointer(UInt32), sp_usr : Pointer(UInt32), vrama_pixels : Pointer(Array(UInt8)), debug_args : Pointer(Array(Array(String))))
    @window = SF::RenderWindow.new(SF::VideoMode.new(1280, 720), "CryDS", settings: SF::ContextSettings.new(depth: 24, antialiasing: 8))
    @window.vertical_sync_enabled = true
    #@window.framerate_limit = 60
    ImGui::SFML.init(@window)

    @delta_clock = SF::Clock.new

    @loadrom = false
    @romselected = 0
    @romname = "red.nds"
    @roms = Array(String).new
    @romsdir = Dir.new("././roms")
    @romsdir.each_child {|rom| @roms << rom }
    @romsdir.close

    @debug = false
    @debug_selected = false

    @texture = SF::Texture.new(256, 192)

    @arm9regs = arm9regs
    @arm7regs = arm7regs
    @sp_irq = sp_irq
    @sp_usr = sp_usr
    @vrama_pixels = vrama_pixels

    @debug_args = debug_args

    @running = true


  end

  def running
    @running
  end

  def debugFalse
    @debug = false
  end

  def debug
    @debug
  end

  def setPointers(arm9regs : Pointer(Array(UInt32)), arm7regs : Pointer(Array(UInt32)), sp_irq : Pointer(UInt32), sp_usr : Pointer(UInt32), vrama_pixels : Pointer(Array(UInt8)), debug_args : Pointer(Array(Array(String))))
    @arm9regs = arm9regs
    @arm7regs = arm7regs
    @sp_irq = sp_irq
    @sp_usr = sp_usr
    @vrama_pixels = vrama_pixels
    @debug_args = debug_args
  end

  def updateScreen

    @window.clear
    while (event = @window.poll_event)
      ImGui::SFML.process_event(event)

      if event.is_a? SF::Event::Closed
        @window.close
        exit
      end
    end
    ImGui::SFML.update(@window, @delta_clock.restart)

    @texture.update(@vrama_pixels.value.to_unsafe.as(UInt8*), 256, 192, 0, 0)
    ImGui.begin_main_menu_bar
      if ImGui.begin_menu("Debug")
        if ImGui.menu_item("Toggle debug mode", nil, @debug_selected)
          @debug = true
          @debug_selected = !@debug_selected
        end
        ImGui.end_menu
      end
    ImGui.end_main_menu_bar


    ImGui.begin("VRAM_A")
    ImGui.image(@texture)
    ImGui.end

    ImGui.begin("Registers")
      ImGui.text("    ARM7    ARM9" )
      (0...16).each do |i|
        ImGui.text("R#{i}: 0x#{@arm7regs.value[i].to_s(16)}   0x#{@arm9regs.value[i].to_s(16)}")
      end
      ImGui.text("sp_irq: 0x#{@sp_irq.value.to_s(16)}")
      ImGui.text("sp_usr: 0x#{@sp_usr.value.to_s(16)}")

    ImGui.end

    ImGui.begin("ROMS")
      if ImGui.button("Load ROM")
        @loadrom = !@loadrom
        @running = true
      end
      if ImGui.button("Stop ROM")
        @running = false
      end
      (0...@roms.size).each do |i|
        if ImGui.selectable(@roms[i], i == @romselected)
          @romselected = i
          @romname = @roms[i]
        end
      end
    ImGui.end
    if @debug_selected
      ImGui.begin("DEBUG")
        @debug_args.value.each do |debug_line|
          ImGui.text(debug_line.to_s)
        end
        if @running
          ImGui.set_scroll_here_y(1_f32)
        end
      ImGui.end
    end

    ImGui::SFML.render(@window)
    @window.display

  end


  def loadRom
    temp = @loadrom
    if @loadrom
      @loadrom = !@loadrom
    end
    temp
  end

  def getRomName
    @romname
  end
end
