
class Gui
  def initialize
    @window = SF::RenderWindow.new(SF::VideoMode.new(WIDTH, HEIGHT), "CryDS", settings: SF::ContextSettings.new(depth: 24, antialiasing: 8))
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

    @texture = SF::Texture.new(256, 192)
  end

  def debugFalse
    @debug = false
  end

  def debug
    @debug
  end

  def updateScreen(regs9, regs7, pixels)
    # Called once every 1/60th of a second, converts BGR565 to RGB888, displays it

    while (event = @window.poll_event)
      ImGui::SFML.process_event(event)

      if event.is_a? SF::Event::Closed
        @window.close
        exit
      end
    end
    ImGui::SFML.update(@window, @delta_clock.restart)

    @texture.update(pixels.to_unsafe.as(UInt8*), 256, 192, 0, 0)
    ImGui.begin_main_menu_bar
      if ImGui.begin_menu("debug")
        if ImGui.menu_item("Toggle debug mode")
          @debug = true
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
        ImGui.text("R#{i}: 0x#{regs7[i].to_s(16)}   0x#{regs9[i].to_s(16)}")
      end
      ImGui.text("sp_irq: 0x#{regs9[16].to_s(16)}")
      ImGui.text("sp_usr: 0x#{regs9[17].to_s(16)}")

    ImGui.end

    ImGui.begin("ROMS")
      if ImGui.button("Load ROM")
        @loadrom = !@loadrom
      end
      (0...@roms.size).each do |i|
        if ImGui.selectable(@roms[i], i == @romselected)
          @romselected = i
          @romname = @roms[i]
        end
      end
    ImGui.end

    @window.clear
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
