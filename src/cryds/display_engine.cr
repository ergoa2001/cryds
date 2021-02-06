require "crsfml"
require "imgui"
require "imgui-sfml"


WIDTH = 1280 #256
HEIGHT = 720 #256*2

class DisplayEngineA
  def initialize
    @dispcnt = 0_u32
    @vramcnt_a = 0_u8
    @vramcnt_b = 0_u8
    @vram_a = Array(UInt8).new(0x20000, 0_u8)
    @vrama_pixels = Array(UInt8).new(0x40000, 0_u8)
    (1...0x10000).each do |i|
      @vrama_pixels[i*4 - 1] = 255_u8
    end
    @oam = Array(UInt8).new(1024, 0_u8)
  end

  def store32(addr, data)
    #puts "Disp store32 addr 0x#{addr.to_s(16)}, data 0x#{data.to_s(16)}"
    case addr
    when 0x04000000
      puts "LCD Control 0x#{data.to_s(16)}"
      @dispcnt = data
    when 0x04000240 then @vramcnt_a = (data & 0xFF).to_u8
    when (0x6800000..0x681FFFF)
      addr = addr - 0x6800000
      val1 = ((data & (0xFF << 24)) >> 24).to_u8
      val2 = ((data & (0xFF << 16)) >> 16).to_u8
      val3 = ((data & (0xFF << 8)) >> 8).to_u8
      val4 = (data & 0xFF).to_u8
      @vram_a[addr] = val1
      @vram_a[addr + 1] = val2
      @vram_a[addr + 2] = val3
      @vram_a[addr + 3] = val4

      b5_1 = ((val1 & 0b01111100) >> 2).to_u32
      g5_1 = (((val1 & 0b11) << 3) | ((val2 & 0b11100000) >> 5)).to_u32
      r5_1 = (val2 & 0b11111).to_u32

      b5_2 = ((val3 & 0b01111100) >> 2).to_u32
      g5_2 = (((val3 & 0b11) << 3) | ((val4 & 0b11100000) >> 5)).to_u32
      r5_2 = (val4 & 0b11111).to_u32

      @vrama_pixels[addr*2] = ((r5_1 * 527 + 23 ) >> 6).to_u8
      @vrama_pixels[addr*2 + 1] = ((g5_1 * 527 + 23 ) >> 6).to_u8
      @vrama_pixels[addr*2 + 2] = ((b5_1 * 527 + 23 ) >> 6).to_u8
      @vrama_pixels[addr*2 + 3] = 255

      @vrama_pixels[addr*2 + 4] = ((r5_2 * 527 + 23 ) >> 6).to_u8
      @vrama_pixels[addr*2 + 5] = ((g5_2 * 527 + 23 ) >> 6).to_u8
      @vrama_pixels[addr*2 + 6] = ((b5_2 * 527 + 23 ) >> 6).to_u8
      @vrama_pixels[addr*2 + 7] = 255

    else
      puts "DEBUGDEA: Unhandled store32 at #{addr.to_s(16)}"
    end
  end

  def store16(addr, data)
    case addr
    when (0x7000000..0x8000000)
      addr -= 0x7000000
      addr &= 0x3FF
      @oam[addr] = ((data & 0xFF00) >> 8).to_u8
      @oam[addr + 1] = (data & 0xFF).to_u8
    when (0x6800000..0x681FFFF)
      addr = addr - 0x6800000
      val1 = ((data & (0xFF << 8)) >> 8).to_u8
      val2 = (data & 0xFF).to_u8
      @vram_a[addr] = val1
      @vram_a[addr + 1] = val2

      b5 = ((val1 & 0b01111100) >> 2).to_u32
      g5 = (((val1 & 0b11) << 3) | ((val2 & 0b11100000) >> 5)).to_u32
      r5 = (val2 & 0b11111).to_u32

      @vrama_pixels[addr*2] = ((r5 * 527 + 23 ) >> 6).to_u8
      @vrama_pixels[addr*2 + 1] = ((g5 * 527 + 23 ) >> 6).to_u8
      @vrama_pixels[addr*2 + 2] = ((b5 * 527 + 23 ) >> 6).to_u8
      @vrama_pixels[addr*2 + 3] = 255
    end
  end
  def store8(addr, data)
    case addr
    when 0x4000240 # ???? reading 0s from the top lol?
      @vramcnt_a = ((data & (0xFF << 8)) >> 8).to_u8
      @vramcnt_b = (data & 0xFF).to_u8
    end
  end

  def get_vrama_pointer
    pointerof(@vrama_pixels)
  end

end
