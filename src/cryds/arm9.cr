require "colorize"


class Arm9
  @pc : UInt32
  def initialize(bus : Bus, debug : Bool)
    @running = true

    @bus = bus
    @pc = @bus.arm9_rom_offset
    @prevpc

    @sp_usr = 0_u32
    @sp_fiq = 0_u32
    @sp_svc = 0_u32
    @sp_abt = 0_u32
    @sp_irq = 0_u32
    @sp_und = 0_u32

    @lr_usr = 0_u16
    @lr_fiq = 0_u16
    @lr_svc = 0_u16
    @lr_abt = 0_u16
    @lr_irq = 0_u16
    @lr_und = 0_u16

    @opcode = 0_u32

    @registers = Array(UInt32).new(16, 0_u8)
    @registers[15] = @pc

    @flag_N = false
    @flag_Z = false
    @flag_C = false
    @flag_V = false
    @cpsr = 0_u32

    @spsr_fiq = 0_u32
    @spsr_svc = 0_u32
    @spsr_abt = 0_u32
    @spsr_irq = 0_u32
    @spsr_und = 0_u32

    @debug = debug
    @debug_args = Array(String).new()
    @debug_prev = ""

  end

  def getRegs
    temp = @registers
    temp << @sp_irq.to_u32
    temp << @sp_usr.to_u32
    temp
  end

  def toggleDebug
    @debug = !@debug
  end

  def run

    if @debug
      @debug_args = Array(String).new()
    end

    @pc = @registers[15]

    @opcode = @bus.arm9_load32(@pc.to_i32 * -1)
    @prevpc = @pc
    @pc += 4

    # Not needed, but easier to find opcode from http://imrannazar.com/ARM-Opcode-Map
    op1 = (@opcode & 0xF0) >> 4
    op2 = (@opcode & (0xFF << 20)) >> 20

    if @opcode & 0b1111111111111111111111110000 == 0b0001001011111111111100010000
      opcode_branch_exchange
    elsif @opcode & 0xC000000 == 0 && @opcode & 0xF0 != 0x90 && @opcode & 0xE400090 != 0x400090 # Funny magic numbers to select the right opcode, hopefully
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
      opcode_halfword_data_immediate
    elsif @opcode & 0xC000000 == 0x4000000 && @opcode & 0x2000010 != 0x2000010
      opcode_single_data_transfer

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
      #puts "DEBUG9: pcode #{@opcode.to_s(16)} bits4-7 #{op1.to_s(16)}, bits20-27 #{op2.to_s(16)}"
      #puts "DEBUG9: #{@debug_args}"
      if @debug_args[0] != @debug_prev
        puts "DEBUG9: #{@debug_args}"
      end
      @debug_prev = @debug_args[0]
    end

    @registers[15] = @pc
  end

  def running
    @running
  end

  ################ OPCODES ################

  def opcode_data_processing

    operation = (@opcode & (0b1111 << 21)) >> 21
    op1 = @registers[(@opcode & (0xF << 16)) >> 16]
    change_flags = (@opcode & 1) << 20 != 0
    if @opcode & (1 << 25) != 0
      rot = ((@opcode & (0xF << 8)) >> 8)*2
      op2 = ((@opcode & 0xFF) >> rot) | ((@opcode & 0xFF) << (32 - rot))
    else
      shift = ((@opcode & 0xFF0) >> 4)
      if shift & 1 == 0
        shiftamount = (shift & 0b11111000) >> 3
      else
        shiftamount = @registers[(shift & 0b11111000) >> 3] & 0xFF
      end
      case (shift & 0b110) >> 1
      when 0b00 then op2 = @registers[@opcode & 0xF] << shiftamount
      when 0b01 then op2 = @registers[@opcode & 0xF] >> shiftamount
      else
        op2 = 0_u32
        puts "DEBUG9: Unimplemented data processing shift"
      end
    end

    # Condition check
    cond = true
    condition = (@opcode & (0xF << 28)) >> 28
    case condition
    when 0b0000
      if !@flag_Z
        cond = false
      end
    when 0b0001
      # NE
      if @flag_Z
        cond = false
      end
    when 0b0101 then cond = true
    when 0b1110 # AL
    else puts "DEBUG9: Invalid opcode_data_processing condition, #{condition.to_s(16)}"
    end

    if cond
      # check for MRS/MSR
      if @opcode & 0b00001111101111110000111111111111 == 0b00000001000011110000000000000000 # MRS
        if @debug
          @debug_args << "MRS"
        end
      elsif @opcode & 0b00001111101111111111111111110000 == 0b00000001001010011111000000000000 # MSR, register to PSR
        if @opcode & (1 << 22) == 0
          dest_CPSR = true
        else
          dest_CPSR = false
        end
        reg = @opcode & 0b1111
        data = @registers[reg]
        if dest_CPSR
          @cpsr = data
        else
          @spsr_irq = data
        end
        if @debug
          @debug_args << "MSR"
          if dest_CPSR
            @debug_args << "cpsr"
          else
            @debug_args << "spsr"
          end
          @debug_args << "r#{reg}"
          @debug_args << data.to_s(16)
        end
      elsif @opcode & 0b00001101101111111111000000000000 == 0b00000001001010001111000000000000 # MSR reg or imm to PSR flag bits only
        if @debug
          @debug_args << "MSR2"
        end
      else
        case operation
        when 0b0000 # AND
          answer = @registers[(@opcode & (0xF << 16)) >> 16] & op2
          @registers[(@opcode & (0xF << 12)) >> 12] = answer
          if change_flags
            if answer == 0
              @flag_Z = true
            else
              @flag_Z = false
            end
          end
          if @debug
            @debug_args << "AND"
          end
        #elsif operation == 0b0001
        when 0b0010 # SUB
          answer = op1 &- op2
          @registers[(@opcode & (0xF << 12)) >> 12] = answer
          if answer == 0
            @flag_Z = true
          else
            @flag_Z = false
          end

          if @debug# && @pc != 0x2d8
            @debug_args << "SUB"
          end
        #elsif operation == 0b0011
        when 0b0100 # ADD
          answer = op1 &+ op2
          @registers[(@opcode & (0xF << 12)) >> 12] = answer
          if change_flags
            if answer & (1 << 31) != 0
              @flag_N = true
            else
              @flag_N = false
            end
            if answer == 0
              @flag_Z = true
            else
              @flag_Z = false
            end
          end
          if @debug
            @debug_args << "ADD"
          end
        #elsif operation == 0b0100

        #elsif operation == 0b0101
        when 0b0110 # SBC
          bit = @flag_C ? 1_u32 : 0_u32
          @registers[(@opcode & (0xF << 12)) >> 12] = op1 - op2 + bit - 1

          if @debug
            @debug_args << "SBC"
          end
        #elsif operation == 0b0111

        #elsif operation == 0b1000
      when 0b1001 # TEQ
          answer = op1 ^ op2
          if answer == 0
            @flag_Z = true
          else
            @flag_Z = false
          end

          if @debug
            @debug_args << "TEQ"
          end

        when 0b1010 # CMP
          answer = op1 &- op2
          if answer == 0
            @flag_Z = true
          else
            @flag_Z = false
          end

          if @debug
            @debug_args << "CMP"
          end
        #elsif operation == 0b1011

        #elsif operation == 0b1100
        when 0b1100 # ORR
          answer = op1 | op2
          @registers[(@opcode & (0xF << 12)) >> 12] = answer
          if answer == 0
            @flag_Z = true
          else
            @flag_Z = false
          end
          if answer & 1 << 31 != 0
            @flag_N = true
          else
            @flag_N = false
          end
        when 0b1101 # MOV
          reg = (@opcode & (0xF << 12)) >> 12
          @registers[reg] = op2
          if change_flags
            if op2 == 0
              @flag_Z = 1
            end
            if op2 & 1 << 31 != 0
              @flag_N = true
            else
              @flag_N = false
            end
          end
          if @debug
            @debug_args << "MOV"
            @debug_args << reg.to_s
          end
        when 0b1110
          answer = op1 & ~op2
          reg = (@opcode & (0xF << 12)) >> 12
          @registers[reg] = answer
          if answer == 0
            @flag_Z = true
          else
            @flag_Z = false
          end

          if @debug
            @debug_args << "BIC"
            @debug_args << op1.to_s(16)
            @debug_args << (~op2).to_s(16)
            @debug_args << reg.to_s
          end
        #elsif operation == 0b1110

        #elsif operation == 0b1111

        else
          puts "DEBUG9: missing opcode_dataprocessing #{operation.to_s(2)}"
        end
      end

      if @debug
        @debug_args << op1.to_s(16)
        @debug_args << op2.to_s(16)
      end
    else
      if @debug
        @debug_args << "nul"
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
      shift = ((@opcode & 0xFF0) >> 4)
      if shift & 1 == 0
        shiftamount = (shift & 0b11111000) >> 3
      else
        shiftamount = @registers[(shift & 0b11111000) >> 3] & 0xFF
      end
      case (shift & 0b110) >> 1
      when 0b00 then offset = @registers[@opcode & 0xF] << shiftamount
      when 0b01 then offset = @registers[@opcode & 0xF] >> shiftamount
      else
        offset = 0_u32
        puts "DEBUG9: Unimplemented data processing shift"
      end
    end

    base_reg = @registers[(@opcode & (0xF << 16)) >> 16]
    if (@opcode & (0xF << 16)) >> 16 == 15
      base_reg -= 8
    end
    # TODO: pre/post add
    # TODO: write-back bit
    prepost = @opcode & (1 << 24) != 0
    add_offset = @opcode & (1 << 23) != 0
    address = base_reg
    if prepost
      if add_offset
        address = base_reg + offset
      else
        #puts "adding #{base_reg.to_s(16)}, #{offset.to_s(16)}, reg #{(@opcode & (0xF << 16)) >> 16}"
        address = base_reg - offset
      end
    end
    storemem = @opcode & (1 << 20) == 0
    datasize = @opcode & (1 << 22) == 0
    if storemem
      data = @registers[(@opcode & (0xF << 12)) >> 12]
      if datasize
        @bus.arm9_store32(address, data)
        if @debug
          @debug_args << "STR"
          @debug_args << address.to_s(16)
          @debug_args << data.to_s(16)
        end
      else
        @bus.arm9_store8(address, data)
        if @debug
          @debug_args << "STRB"
          @debug_args << address.to_s(16)
          @debug_args << data.to_s(16)
        end
      end
    else
      if datasize
        data = @bus.arm9_load32(address)
        #if @debug
          @debug_args << "LDR"
          @debug_args << address.to_s(16)
          @debug_args << data.to_s(16)
        #end
      else
        data = @bus.arm9_load8(address)
        if @debug
          @debug_args << "LDRB"
          @debug_args << address.to_s(16)
          @debug_args << data.to_s(16)
        end
      end
      reg = (@opcode & (0xF << 12)) >> 12
      @debug_args << reg.to_s
      if reg == 13
        mode = @cpsr & 0b11111
        case mode
        when 0b10000 then puts "Unhandled User mode ldr".colorize(:red)
        when 0b10001 then puts "Unhandled FIQ mode ldr".colorize(:red)
        when 0b10010 then @sp_irq = data
        when 0b10011 then puts "Unhandled SWI mode ldr".colorize(:red)
        when 0b10111 then puts "Unhandled Abort mode ldr".colorize(:red)
        when 0b11011 then puts "Unhandled Undefined mode ldr".colorize(:red)
        when 0b11111 then @sp_usr = data
        end
        # setting SP, depends on mode
      else
        @registers[reg] = data
      end

    end

    if !prepost
      if add_offset
        @registers[(@opcode & (0xF << 16)) >> 16] = base_reg + offset
      else
        @registers[(@opcode & (0xF << 16)) >> 16] = base_reg - offset
      end
    end
  end

  def opcode_branch
    if @debug# && @pc != 0x2d0
      @debug_args << "Branch"
    end

    condition = (@opcode & (0xF << 28)) >> 28
    offset = (@opcode & 0xFFFFFF).to_i32
    offset = offset - (offset >> 23 << 24)
    # TODO: Link bit
    linkbit = @opcode & (1 << 24) != 0
    if linkbit
      @registers[14] = @pc
    end
    case condition
    when 0b0000
      if @flag_Z
        @pc = @pc + 4 + offset*4
        @debug_args << "EQ"
      end
      @flag_Z = false
    when 0b0001
      # NE
      if !@flag_Z
        @pc = @pc + 4 + offset*4
        @debug_args << "NE"
      end
      @flag_Z = false
    when 0b1110
      @pc = @pc + 4 + offset*4
      @debug_args << "AL"
    else puts "DEBUG9: Invalid B condition, #{condition.to_s(16)}"
    end


  end

  def opcode_halfword_data_immediate

    condition = (@opcode & (0xF << 28)) >> 28
    offset = (@opcode & (0xF << 8)) >> 4 | (@opcode & 0xF)
    base_reg = @registers[(@opcode & (0xF << 16)) >> 16]
    # TODO: sh checks
    sh = (@opcode & (0b11 << 5)) >> 5
    case condition
    when 0b0001
      # NE
      if !@flag_Z
        cond = true
      else
        cond = false
      end
      @flag_Z = false
    when 0b1110
      # AL
      cond = true
    else puts "DEBUG9: Invalid opcode_halfword_data_immediate condition, #{condition.to_s(16)}"
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

        if @debug
          @debug_args << "STRH"
          @debug_args << addr.to_s(16)
          @debug_args << @registers[(@opcode & (0xF << 12)) >> 12].to_s(16)
        end

      else
        # Load from mem
        data = @bus.arm9_load16(addr).to_u32
        @registers[(@opcode & (0xF << 12)) >> 12] = data

        if @debug
          @debug_args << "LDRH"
          @debug_args << ((@opcode & (0xF << 12)) >> 12).to_s(16)
          @debug_args << data.to_s(16)
        end
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


  end

  def opcode_block_data_transfer
    condition = (@opcode & (0xF << 28)) >> 28
    cond = false
    case condition
    when 0b0001
      # NE
      if !@flag_Z
        cond = true
      else
        cond = false
      end
      @flag_Z = false
    when 0b1110
      # AL
      cond = true
    else puts "DEBUG9: Invalid opcode_block_data_transfer condition, #{condition.to_s(2)}"
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
    end
    if @debug #&& @pc != 0x2d4
      @debug_args << "Block Data Transfer"
    end
  end

  def opcode_branch_exchange
    condition = (@opcode & (0xF << 28)) >> 28
    if @debug
      @debug_args << "BX"
    end
    case condition
    when 0b0000
      if @flag_Z
        cond = true
      else
        cond = false
      end
      if @debug
        @debug_args << "eq"
      end
    when 0b1110 then cond = true
    else puts "Unhandled bx condition #{condition.to_s(2)}".colorize(:red)
    end

    if cond
      reg = @opcode & 0xF
      val = @registers[reg]
      @pc = val
      @registers[15] = @pc
      if val & 1 == 1
        puts "Continuing on THUMB"
      else
        puts "Continuing on ARM"
      end
      if @debug
        @debug_args << "r#{reg}"
        @debug_args << "new pc 0x#{@pc.to_s(16)}"
      end
    end

  end

end
