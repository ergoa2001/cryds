
# TODO: copy code from arm9 and make this atleast a little nicer

class Arm7
  @pc : UInt32
  def initialize(bus : Bus)
    @running = true

    @bus = bus
    @pc = @bus.arm7_rom_offset
    @sp = 0_u16

    @opcode = 0_u32

    @registers = Array(UInt32).new(16, 0_u8)

    @registers[15] = @pc

    @debug = false
  end

  def getRegs
    @registers
  end

  def getRegPointer
    pointerof(@registers)
  end

  def run
    @pc = @registers[15]
    @opcode = @bus.arm7_load32(@pc.to_i32 * -1)
    @pc += 4

    op1 = (@opcode & 0xF0) >> 4
    op2 = (@opcode & (0xFF << 20)) >> 20

    case op2
    when 0xAF then opcode_b
    else
      #puts "DEBUG7: Invalid opcode #{@opcode.to_s(16)} (#{op1.to_s(16)}, #{op2.to_s(16)})"
      #@running = false
    end

    if @debug
      puts "DEBUG7: opcode #{@opcode.to_s(16)} bits4-7 #{op1.to_s(16)}, bits20-27 #{op2.to_s(16)}"
    end

    @registers[15] = @pc
  end

  def running
    @running
  end

  ######## OPCODES ########

  # TODO: all of arm7 is bad, even arm9 is bad, everything is bad. fix pls

  def opcode_b
    condition = (@opcode & (0xF << 28)) >> 28
    offset = (@opcode & 0xFFFFFF).to_i32
    offset = offset - (offset >> 23 << 24)
    # TODO: Link bit
    case condition
    when 0xE then @pc = @pc + 4 + offset*4
    else puts "DEBUG7: Invalid B condition"
    end


    #puts "0xAF opcode, condition #{condition.to_s(16)}, offset #{offset.to_s(16)}"
  end
end
