require "colorize"

class Bus

  @rom : Array(UInt8)
  @title : Array(UInt8)
  @displayEngineA : DisplayEngineA
  def initialize(rom, displayEngineA)
    @rom = rom
    @title = Array(UInt8).new

    @ITCM = Array(UInt8).new(0x8000, 0_u8)

    @arm9_rom_offset = 0_u32
    @arm9_entry_address = 0_u32
    @arm9_ram_address = 0_u32
    @arm9_size = 0_u32

    @arm7_rom_offset = 0_u32
    @arm7_entry_address = 0_u32
    @arm7_ram_address = 0_u32
    @arm7_size = 0_u32

    @POWCNT1 = 0_u32

    @displayEngineA = displayEngineA

    parse_header(@rom)
    @memory = Array(UInt8).new(0x100000, 0_u8)
    @memory[@arm9_entry_address - 0x2000000...@arm9_entry_address - 0x2000000 + @arm9_size] = @rom[@arm9_rom_offset...@arm9_rom_offset + @arm9_size]
    #@memory[@arm7_entry_address - 0x2000000...@arm7_entry_address - 0x2000000 + @arm7_size] = @rom[@arm7_rom_offset...@arm7_rom_offset + @arm7_size]
    @vblank = 0_u16
  end

  def arm7_rom_offset : UInt32
    @arm7_rom_offset
  end

  def arm9_rom_offset : UInt32
    @arm9_rom_offset
  end

  def arm9_entry_address : UInt32
    @arm9_entry_address
  end

  def parse_header(rom)
    # 020h    4     ARM9 rom_offset    (4000h and up, align 1000h)
    # 024h    4     ARM9 entry_address (2000000h..23BFE00h)
    # 028h    4     ARM9 ram_address   (2000000h..23BFE00h)
    # 02Ch    4     ARM9 size          (max 3BFE00h) (3839.5KB)
    # 030h    4     ARM7 rom_offset    (8000h and up)
    # 034h    4     ARM7 entry_address (2000000h..23BFE00h, or 37F8000h..3807E00h)
    # 038h    4     ARM7 ram_address   (2000000h..23BFE00h, or 37F8000h..3807E00h)
    # 03Ch    4     ARM7 size          (max 3BFE00h, or FE00h) (3839.5KB, 63.5KB)
    @title = rom[0...12]

    @arm9_rom_offset = rom[0x20].to_u32 | rom[0x20 + 1].to_u32 << 8 | rom[0x20 + 2].to_u32 << 16 | rom[0x20 + 3].to_u32 << 24
    @arm9_entry_address = rom[0x24].to_u32 | rom[0x24 + 1].to_u32 << 8 | rom[0x24 + 2].to_u32 << 16 | rom[0x24 + 3].to_u32 << 24
    @arm9_ram_address = rom[0x28].to_u32 | rom[0x28 + 1].to_u32 << 8 | rom[0x28 + 2].to_u32 << 16 | rom[0x28 + 3].to_u32 << 24
    @arm9_size = rom[0x2C].to_u32 | rom[0x2C + 1].to_u32 << 8 | rom[0x2C + 2].to_u32 << 16 | rom[0x2C + 3].to_u32 << 24

    @arm7_rom_offset = rom[0x30].to_u32 | rom[0x30 + 1].to_u32 << 8 | rom[0x30 + 2].to_u32 << 16 | rom[0x30 + 3].to_u32 << 24
    @arm7_entry_address = rom[0x34].to_u32 | rom[0x34 + 1].to_u32 << 8 | rom[0x34 + 2].to_u32 << 16 | rom[0x34 + 3].to_u32 << 24
    @arm7_ram_address = rom[0x38].to_u32 | rom[0x38 + 1].to_u32 << 8 | rom[0x38 + 2].to_u32 << 16 | rom[0x38 + 3].to_u32 << 24
    @arm7_size = rom[0x3C].to_u32 | rom[0x3C + 1].to_u32 << 8 | rom[0x3C + 2].to_u32 << 16 | rom[0x3C + 3].to_u32 << 24

    print "Title: "
    @title.each do |x|
      print x.chr
    end
    puts
    puts "DEBUG: arm9_rom_offset : 0x#{@arm9_rom_offset.to_s(16)}"
    puts "DEBUG: arm9_entry_address : 0x#{@arm9_entry_address.to_s(16)}"
    puts "DEBUG: arm9_ram_address : 0x#{@arm9_ram_address.to_s(16)}"
    puts "DEBUG: arm9_size : 0x#{@arm9_size.to_s(16)}"
    puts "DEBUG: arm7_rom_offset : 0x#{@arm7_rom_offset.to_s(16)}"
    puts "DEBUG: arm7_entry_address : 0x#{@arm7_entry_address.to_s(16)}"
    puts "DEBUG: arm7_ram_address : 0x#{@arm7_ram_address.to_s(16)}"
    puts "DEBUG: arm7_size : 0x#{@arm7_size.to_s(16)}"
    puts ""


  end

  def arm9_get_opcode(addr, mode)
    if mode
      if addr >= @arm9_entry_address && addr < @arm9_entry_address + @arm9_size
        addr -= 0x2000000
        @memory[addr].to_u32 | @memory[addr + 1].to_u32 << 8 | @memory[addr + 2].to_u32 << 16 | @memory[addr + 3].to_u32 << 24
      else
        #puts "DEBUG9: Unhandled pc32 at 0x#{addr.to_s(16)}"
        0_u32
      end
    else
      if addr >= @arm9_entry_address && addr < @arm9_entry_address + @arm9_size
        addr -= 0x2000000
        @memory[addr].to_u32 | @memory[addr + 1].to_u32 << 8
      else
        #puts "DEBUG9: Unhandled pc32 at 0x#{addr.to_s(16)}"
        0_u32
      end
    end
  end

  def arm9_load32(addr)
    case addr
    when (0x00000000..0x02000000)
      addr &= 0x7FFF
      @ITCM[addr].to_u32 | (@ITCM[addr + 1].to_u32 << 8) | (@ITCM[addr + 2].to_u32 << 16) | (@ITCM[addr + 3].to_u32 << 24)
    when (0x02000000..0x03000000)
      addr &= 0x020FFFFF
      addr -= 0x02000000
      @memory[addr].to_u32 | (@memory[addr + 1].to_u32 << 8) | (@memory[addr + 2].to_u32 << 16) | (@memory[addr + 3].to_u32 << 24)
    when 0x04000130 then 0xFF_u32
    else
      puts "DEBUG9: Unhandled load32 at 0x#{addr.to_s(16)}".colorize(:red)
      0_u32
    end
  end

  def arm9_load16(addr)
    case addr
    when (0x02000000..0x03000000)
      addr &= 0x020FFFFF
      addr -= 0x02000000
      @memory[addr].to_u16 | @memory[addr + 1].to_u16 << 8
    when 0x4000004
      @vblank ^= 1
      @vblank
    else
      puts "DEBUG9: Unhandled load16 from 0x#{addr.to_s(16)}".colorize(:red)
      0_u32
    end
  end

  def arm9_load8(addr)
    case addr
    when (0x00000000..0x02000000)
      addr &= 0x7FFF
      @ITCM[addr].to_u32
    when (0x02000000..0x03000000)
      addr &= 0x020FFFFF
      addr -= 0x02000000
      @memory[addr].to_u32
    else
      puts "DEBUG9: Unhandled load8 pos #{addr.to_s(16)}".colorize(:red)
      0_u32
    end
  end

  def arm9_store32(addr, data)
    case addr
    when (0x00000000..0x02000000)
      addr &= 0x7FFF
      @ITCM[addr] = (data & 0xFF).to_u8
      @ITCM[addr + 1] = ((data & 0xFF00) >> 8).to_u8
      @ITCM[addr + 2] = ((data & 0xFF0000) >> 16).to_u8
      @ITCM[addr + 3] = ((data & 0xFF000000) >> 24).to_u8
    when (0x02000000..0x03000000)
      addr &= 0x020FFFFF
      addr -= 0x02000000
      @memory[addr + 0] = (data & 0xFF).to_u8
      @memory[addr + 1] = ((data & 0xFF00) >> 8).to_u8
      @memory[addr + 2] = ((data & 0xFF0000) >> 16).to_u8
      @memory[addr + 3] = ((data & 0xFF000000) >> 24).to_u8
    when 0x04000304 then @POWCNT1 = data
    when (0x04000000..0x0400006C) then @displayEngineA.store32(addr, data)
    when (0x04000240..0x04000249) then @displayEngineA.store32(addr, data)
    when (0x04000000..0x05000000)
      puts "DEBUG9: Unhandled store32 to I/O ports #{addr.to_s(16)}".colorize(:red)
    when (0x6800000..0x681FFFF) then @displayEngineA.store32(addr, data)
    else
      puts "DEBUG9: Unhandled store32 pos #{addr.to_s(16)}, data #{data.to_s(16)}".colorize(:red)
    end
  end

  def arm9_store16(addr, data)
    case addr
    when (0x02000000..0x03000000)
      addr &= 0x020FFFFF
      addr -= 0x02000000
      @memory[addr + 0] = (data & 0xFF).to_u8
      @memory[addr + 1] = ((data & 0xFF00) >> 8).to_u8
    when (0x6800000..0x681FFFF) then @displayEngineA.store16(addr, data.to_u16!)

    else
      puts "DEBUG9: Unhandled store16 pos #{addr.to_s(16)}, data #{data.to_u16!.to_s(16)}".colorize(:red)
    end
  end

  def arm9_store8(addr, data)
    case addr
    when (0x00000000..0x02000000)
      addr &= 0x7FFF
      @ITCM[addr] = (data & 0xFF).to_u8
    when 0x4000240 then @displayEngineA.store8(addr, data)
    when (0x02000000..0x03000000)
      addr &= 0x020FFFFF
      addr -= 0x02000000
      @memory[addr + 0] = (data & 0xFF).to_u8
    else puts "DEBUG9: Unhandled store8 pos #{addr.to_s(16)}".colorize(:red)
    end
  end

  def arm7_load32(addr)
    if addr < 0
      # ROM read
      addr = addr * -1
      return @rom[addr].to_u32 | @rom[addr + 1].to_u32 << 8 | @rom[addr + 2].to_u32 << 16 | @rom[addr + 3].to_u32 << 24
    else
      puts "DEBUG7: Unhandled load32 at 0x#{addr.to_s(16)}".colorize(:red)
      return 0_u32
    end
  end

end
