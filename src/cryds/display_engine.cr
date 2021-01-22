require "crsfml"
require "imgui"
require "imgui-sfml"


WIDTH = 1280 #256
HEIGHT = 720 #256*2

class DisplayEngineA
  def initialize
    @window = SF::RenderWindow.new(SF::VideoMode.new(WIDTH, HEIGHT), "CryDS", settings: SF::ContextSettings.new(depth: 24, antialiasing: 8))
    @window.vertical_sync_enabled = true
    #@window.framerate_limit = 60
    ImGui::SFML.init(@window)

    @delta_clock = SF::Clock.new

    # Tahaks mingi list boxi teha kus sees romide valik
    @roms = Dir.new("././roms")
    @roms.each { |x| puts x}

    @texture = SF::Texture.new(256, 192)
    @sprite = SF::Sprite.new(@texture)

    @lcd_control = 0_u32
    @vramcnt_a = 0_u32
    @vram_a = Array(UInt8).new(0x20000, 0_u8)
  end

  def store32(addr, data)
    case addr
    when 0x04000000 then @lcd_control = data
    when 0x04000240 then @vramcnt_a = data
    else
      puts "DEBUGDEA: Unhandled store32 at #{addr.to_s(16)}"
    end
  end

  def store16(addr, data)
    case addr
    when (0x6800000..0x681FFFF)
      @vram_a[addr - 0x6800000] = ((data & (0xFF << 8)) >> 8).to_u8
      @vram_a[addr - 0x6800000 + 1] = (data & 0xFF).to_u8
    end
  end

  def updateScreen(regs9, regs7)
    # Called once every 1/60th of a second, converts BGR565 to RGB888, displays it

    while (event = @window.poll_event)
      ImGui::SFML.process_event(event)

      if event.is_a? SF::Event::Closed
        @window.close
        exit
      end
    end
    ImGui::SFML.update(@window, @delta_clock.restart)

    # Pixel conversion
    pixels = Array(UInt8).new
    (0...@vram_a.size / 2).each do |pixel_index|
      index = pixel_index*2
      val1 = @vram_a[index]
      val2 = @vram_a[index + 1]

      b5 = (val1 & 0b11111000) >> 3
      g6 = ((val1 & 0b111) << 3) | ((val2 & 0b11100000) >> 5)
      r5 = val2 & 0b11111

      b5 = b5.to_u32
      g6 = g6.to_u32
      r5 = r5.to_u32
      b8 = (b5 * 527 + 23 ) >> 6
      g8 = (g6 * 259 + 33 ) >> 6
      r8 = (r5 * 527 + 23 ) >> 6

      pixels << r8.to_u8
      pixels << g8.to_u8
      pixels << b8.to_u8
      pixels << 255

    end


    @texture.update(pixels.to_unsafe.as(UInt8*), 256, 192, 0, 0)
    ImGui.begin("VRAM_A")
    ImGui.image(@texture)
    ImGui.end

    ImGui.begin("Registers ARM9")
    regs9.each_with_index do |reg, i|
      ImGui.text("R#{i}: 0x#{reg.to_s(16)}" )
    end
    ImGui.end

    ImGui.begin("Registers ARM7")
    regs7.each_with_index do |reg, i|
      ImGui.text("R#{i}: 0x#{reg.to_s(16)}" )
    end
    ImGui.end

    @window.clear
    #@window.draw @sprite
    ImGui::SFML.render(@window)
    @window.display


  end
end
