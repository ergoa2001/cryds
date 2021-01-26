require "crsfml"
require "imgui"
require "imgui-sfml"


WIDTH = 1280 #256
HEIGHT = 720 #256*2

class DisplayEngineA
  def initialize
    @lcd_control = 0_u32
    @vramcnt_a = 0_u8
    @vramcnt_b = 0_u8
    @vram_a = Array(UInt8).new(0x20000, 0_u8)
  end

  def store32(addr, data)
    case addr
    when 0x04000000 then @lcd_control = data
    when 0x04000240 then @vramcnt_a = data.to_u8! # TODO: wrong, i think
    when (0x6800000..0x681FFFF)
      @vram_a[addr - 0x6800000] = ((data & (0xFF << 24)) >> 24).to_u8
      @vram_a[addr - 0x6800000 + 1] = ((data & (0xFF << 16)) >> 16).to_u8
      @vram_a[addr - 0x6800000 + 2] = ((data & (0xFF << 8)) >> 8).to_u8
      @vram_a[addr - 0x6800000 + 3] = (data & 0xFF).to_u8
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
  def store8(addr, data)
    case addr
    when 0x4000240 # ???? reading 0s from the top lol?
      @vramcnt_a = ((data & (0xFF << 8)) >> 8).to_u8
      @vramcnt_b = (data & 0xFF).to_u8
    end
  end

  def getPixels
    # Pixel conversion
    pixels = Array(UInt8).new
    (0...@vram_a.size / 2).each do |pixel_index|
      index = pixel_index*2
      val1 = @vram_a[index]
      val2 = @vram_a[index + 1]

      b5 = (val1 & 0b01111100) >> 2
      g5 = ((val1 & 0b11) << 3) | ((val2 & 0b11100000) >> 5)
      r5 = val2 & 0b11111

      b5 = b5.to_u32
      g5 = g5.to_u32
      r5 = r5.to_u32
      b8 = (b5 * 527 + 23 ) >> 6
      g8 = (g5 * 527 + 23 ) >> 6
      r8 = (r5 * 527 + 23 ) >> 6

      pixels << r8.to_u8
      pixels << g8.to_u8
      pixels << b8.to_u8
      pixels << 255
    end
    pixels
  end

end
