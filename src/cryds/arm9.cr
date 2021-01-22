require "colorize"


class Arm9
  @pc : UInt32
  def initialize(bus : Bus)
    @running = true

    @bus = bus
    @pc = @bus.arm9_rom_offset
    @prevpc
    @sp = 0_u16

    @opcode = 0_u32

    @registers = Array(UInt32).new(16, 0_u8)
    @registers[15] = @pc

    @flag_C = 0_u32
    @flag_Z = 0_u32

    @debug = false

  end

  def getRegs
    @registers
  end

  def run
    @pc = @registers[15]

    @opcode = @bus.arm9_load32(@pc.to_i32 * -1)
    @prevpc = @pc
    @pc += 4

    # Not needed, but easier to find opcode from http://imrannazar.com/ARM-Opcode-Map
    op1 = (@opcode & 0xF0) >> 4
    op2 = (@opcode & (0xFF << 20)) >> 20

    if @opcode & 0xC000000 == 0 && @opcode & 0xF0 != 0x90 && @opcode & 0xE400090 != 0x400090 # Funny magic numbers to select the right opcode, hopefully
      opcode_data_processing
    # elsif @opcode & 0b1111110000000000000011110000 == 0b0000000000000000000010010000
    #   opcode_multiply
    # elsif @opcode & 0b1111100000000000000011110000 == 0b0000100000000000000010010000
    #   opcode_multiply_long
    # elsif @opcode & 0b1111101100000000111111110000 == 0b0001000000000000000010010000
    #   opcode_single_data_swap
    elsif @opcode & 0xE000000 == 0xA000000
      opcode_branch

    # elsif @opcode & 0b1111100000000000000011110000 == 0b0000100000000000000010010000
    #   opcode_multiply_long
    elsif @opcode & @opcode & 0xE400090 == 0x400090
      opcode_halword_data_immediate
    elsif @opcode & 0xC000000 == 0x4000000 && @opcode & 0x2000010 != 0x2000010
      opcode_single_data_transfer
    # elsif @opcode & 0b1111100000000000000011110000 == 0b0000100000000000000010010000
    #   opcode_multiply_long
    elsif @opcode & 0xE000000 == 0x8000000
      opcode_block_data_transfer
    # elsif @opcode & 0b1111100000000000000011110000 == 0b0000100000000000000010010000
    #   opcode_multiply_long
    # elsif @opcode & 0b1111100000000000000011110000 == 0b0000100000000000000010010000
    #   opcode_multiply_long
    # elsif @opcode & 0b1111100000000000000011110000 == 0b0000100000000000000010010000
    #   opcode_multiply_long
    # elsif @opcode & 0b1111100000000000000011110000 == 0b0000100000000000000010010000
    #   opcode_multiply_long
    # elsif @opcode & 0b1111100000000000000011110000 == 0b0000100000000000000010010000
    #   opcode_multiply_long
    else
      puts "DEBUG9: Invalid opcode #{@opcode.to_s(16)} #{@opcode.to_s(2)} (#{op1.to_s(16)}, #{op2.to_s(16)}), terminating!".colorize(:red)
      @running = false
    end

    if @debug
      #puts "DEBUG9: opcode #{@opcode.to_s(16)} bits4-7 #{op1.to_s(16)}, bits20-27 #{op2.to_s(16)}"
    end

    @registers[15] = @pc
  end

  def running
    @running
  end

  ######## OPCODES ########

  def opcode_data_processing
    operation = (@opcode & (0b1111 << 21)) >> 21
    op1 = @registers[(@opcode & (0xF << 16)) >> 16]
    if @opcode & (1 << 25) != 0
      rot = ((@opcode & (0xF << 8)) >> 8)*2
      op2 = ((@opcode & 0xFF) >> rot) | ((@opcode & 0xFF) << (32 - rot))
    else
      op2 = @registers[@opcode & 0xF] >> ((@opcode & 0xFF0) >> 4)
    end

    # Condition check
    cond = true
    condition = (@opcode & (0xF << 28)) >> 28
    case condition
    when 0b0000
      if @flag_Z != 1
        cond = false
      end
    when 0b0001
      # NE
      if @flag_Z != 0
        cond = false
      end
    when 0b0101 then cond = true
    when 0b1110 # AL
    else puts "DEBUG9: Invalid opcode_data_processing condition, #{condition.to_s(16)}"
    end

    if cond
      case operation
      when 0b0000 # AND    regs =
        answer = @registers[(@opcode & (0xF << 16)) >> 16] & op2
        @registers[(@opcode & (0xF << 12)) >> 12] = answer
        if answer == 0
          @flag_Z = 1_u32
        else
          @flag_Z = 0_u32
        end

        if @debug
          puts "ARM9: AND"
        end
      #elsif operation == 0b0001
      when 0b0010 # SUB
        answer = op1 &- op2
        @registers[(@opcode & (0xF << 12)) >> 12] = answer
        if answer == 0
          @flag_Z = 1_u32
        else
          @flag_Z = 0_u32
        end

        if @debug# && @pc != 0x2d8
          puts "ARM9: SUB"
        end
      #elsif operation == 0b0011
      when 0b0100 # ADD
        answer = op1 &+ op2
        @registers[(@opcode & (0xF << 12)) >> 12] = answer
        if answer == 0
          @flag_Z = 1_u32
        else
          @flag_Z = 0_u32
        end

        if @debug
          puts "ARM9: ADD"
        end
      #elsif operation == 0b0100

      #elsif operation == 0b0101
      when 0b0110 # SBC

        @registers[(@opcode & (0xF << 12)) >> 12] = op1 - op2 + @flag_C - 1

        if @debug
          puts "ARM9: SBC"
        end
      #elsif operation == 0b0111

      #elsif operation == 0b1000
    when 0b1001 # TEQ
        answer = op1 ^ op2
        if answer == 0
          @flag_Z = 1_u32
        else
          @flag_Z = 0_u32
        end

        if @debug
          puts "ARM9: TEQ"
        end

      when 0b1010 # CMP
        answer = op1 &- op2
        if answer == 0
          @flag_Z = 1_u32
        else
          @flag_Z = 0_u32
        end

        if @debug
          puts "ARM9: CMP"
        end
      #elsif operation == 0b1011

      #elsif operation == 0b1100
      when 0b1101 # MOV
        @registers[(@opcode & (0xF << 12)) >> 12] = op2
        if op2 == 0
          @flag_Z = 1
        end

        if @debug
          puts "ARM9: MOV"
        end
      when 0b1110
        answer = op1 & ~op2
        @registers[(@opcode & (0xF << 12)) >> 12] = answer
        if answer == 0
          @flag_Z = 1_u32
        else
          @flag_Z = 0_u32
        end

        if @debug
          puts "ARM9: AND NOT"
        end
      #elsif operation == 0b1110

      #elsif operation == 0b1111

      else
        puts "DEBUG9: missing opcode_dataprocessing #{operation.to_s(2)}"
      end
    end
  end

  def opcode_multiply
    puts "DEBUG9: missing opcode_multiply"
  end

  def opcode_multiply_long
    puts "DEBUG9: missing opcode_multiply_long"
  end

  def opcode_single_data_swap
    puts "DEBUG9: missing opcode_single_data_swap"
  end

  def opcode_single_data_transfer
    if @opcode & (1 << 25) == 0
      # Immediate offset
      offset = @opcode & 0xFFF
    else
      offset = (@opcode & 0xF) >> ((@opcode & 0xFF0) >> 4)
    end

    base_reg = @registers[(@opcode & (0xF << 16)) >> 16]

    # TODO: pre/post add
    # TODO: write-back bit

    if @opcode & (1 << 23) == 0
      address = base_reg &- offset
    else
      address = base_reg &+ offset
    end

    if @opcode & (1 << 20) == 0
      data = @registers[(@opcode & (0xF << 12)) >> 12]
      if @opcode & (1 << 22) == 0
        @bus.arm9_store32(address, data)
      else
        @bus.arm9_store8(address, data)
      end
    else
      if @opcode & (1 << 22) == 0
        data = @bus.arm9_load32(address)
      else
        data = @bus.arm9_load8(address)
      end
      @registers[(@opcode & (0xF << 12)) >> 12] = data
    end

    if @debug
      puts "ARM9: Single Data Transfer"
    end
  end

  def opcode_branch
    condition = (@opcode & (0xF << 28)) >> 28
    offset = (@opcode & 0xFFFFFF).to_i32
    offset = offset - (offset >> 23 << 24)
    # TODO: Link bit
    case condition
    when 0b0001
      # NE
      if @flag_Z == 0
        @pc = @pc + 4 + offset*4
      end
      @flag_Z = 0_u32
    when 0b1110 then @pc = @pc + 4 + offset*4
    else puts "DEBUG9: Invalid B condition, #{condition.to_s(16)}"
    end

    if @debug# && @pc != 0x2d0
      puts "ARM9: Branch"
    end
  end

  def opcode_halword_data_immediate
    condition = (@opcode & (0xF << 28)) >> 28
    offset = (@opcode & (0xF << 8)) >> 4 | (@opcode & 0xF)
    base_reg = @registers[(@opcode & (0xF << 16)) >> 16]
    # TODO: sh checks
    sh = (@opcode & (0b11 << 5)) >> 5
    case condition
    when 0b0001
      # NE
      if @flag_Z == 0
        cond = true
      else
        cond = false
      end
      @flag_Z = 0_u32
    when 0b1110
      # AL
      cond = true
    else puts "DEBUG9: Invalid opcode_halword_data_immediate condition, #{condition.to_s(16)}"
    end

    # TODO: writeback
    writeback = @opcode & (1 << 21)

    prepost = @opcode & (1 << 24)
    if prepost == 0
      writeback = 1
    end
    addr = base_reg
    if prepost != 0
      if @opcode & (1 << 23) == 0
        addr = base_reg - offset
      else
        addr = base_reg + offset
      end
    end

    if cond
      if @opcode & (1 << 20) == 0
        # Store to mem
        @bus.arm9_store16(addr, @registers[(@opcode & (0xF << 12)) >> 12])

      else
        # Load from mem
        @registers[(@opcode & (0xF << 12)) >> 12] = @bus.arm9_load16(addr).to_u32
      end
    end

    if prepost == 0
      if @opcode & (1 << 23) == 0
        addr = base_reg - offset
      else
        addr = base_reg + offset
      end
    end
    if writeback != 0
      @registers[(@opcode & (0xF << 16)) >> 16] = addr
    end

    if @debug
      puts "ARM9: Halfword Data Transfer"
    end
  end

  def opcode_block_data_transfer
    condition = (@opcode & (0xF << 28)) >> 28
    cond = false
    case condition
    when 0b0001
      # NE
      if @flag_Z == 0
        cond = true
      else
        cond = false
      end
      @flag_Z = 0_u32
    when 0b1110
      # AL
      cond = true
    else puts "DEBUG9: Invalid opcode_block_data_transfer condition, #{condition.to_s(16)}"
    end

    if cond
      basereg = @registers[(@opcode & (0xF << 16)) >> 16]
      loadstore = @opcode & (1 << 20)
      updown = @opcode & (1 << 23)
      (0...16).each do |i|
        if @opcode & (1 << i) != 0
          if loadstore == 0
            if updown == 0
              @bus.arm9_store32(basereg &- i*4, @registers[i])
            else
              @bus.arm9_store32(basereg &+ i*4, @registers[i])
            end
          else
            if updown == 0
              @registers[i] = @bus.arm9_load32(basereg - i*4)
            else
              @registers[i] = @bus.arm9_load32(basereg + i*4)
            end
          end
        end
      end
      if @debug #&& @pc != 0x2d4
        puts "ARM9: Block Data Transfer"
      end
    end
  end

end
