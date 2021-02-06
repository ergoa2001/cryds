require "colorize"

class Arm9
  enum Modes
    ARM
    THUMB
  end

  @pc : UInt32
  @armlut : Array(Proc((Bool | UInt32 | Nil)) | Proc((UInt32 | Nil)) | Proc(Nil) | Proc(UInt32))
  def initialize(bus : Bus, debug : Bool)
    @running = true

    @bus = bus
    @pc = @bus.arm9_entry_address
    @prevpc

    @sp_usr = 0_u32
    @sp_fiq = 0_u32
    @sp_svc = 0_u32
    @sp_abt = 0_u32
    @sp_irq = 0_u32
    @sp_und = 0_u32
    @sp = 0_u32

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

    @mode = Modes::ARM

    @debug = debug
    @debug_args = Array(Array(String)).new
    @debug_args_temp = Array(String).new
    @debug_prev = Array(String).new

    @cond = true

    # CP15 regs
    @tcmitcmbvs = 0xFF_u32
    @tcmdtcmbvs = 0x27C0000_u32

    @armlut = [->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_multiply, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_multiply, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_multiply, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_multiply, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_multiply_long, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_multiply_long, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_multiply_long, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_multiply_long, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_multiply_long, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_multiply_long, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_multiply_long, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_multiply_long, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_psrt_transfer, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_qadd, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_multiply_long, ->opcode_swap, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_psrt_transfer, ->opcode_branch_exchange, ->opcode_data_processing_imm_shift, ->opcode_blx2, ->opcode_data_processing_imm_shift, ->opcode_qsub, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_psrt_transfer, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_multiply_long, ->opcode_swap, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_psrt_transfer, ->opcode_clz, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_multiply_long, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_data_processing_reg, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_data_processing_reg_flag, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm_shift_flags, ->opcode_load_store_misc, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_psrt_transfer, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_data_processing_imm_flags, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_imm, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_load_store_shift, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_stm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_ldm, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_branch_link, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_cop_data_operation, ->opcode_cop_reg_transfer, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi, ->opcode_swi]

  end

  def stop
    @running = false
  end

  def get_reg_pointer
    pointerof(@registers)
  end

  def get_sp_irq_pointer
    pointerof(@sp_irq)
  end

  def get_sp_usr_pointer
    pointerof(@sp_usr)
  end

  def get_debug_args_pointer
    pointerof(@debug_args)
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

  def reset_flags
    @flag_N = false
    @flag_Z = false
    @flag_C = false
    @flag_V = false
  end

  def set_logical_flags(answer)
    # V flag unaffected
    @flag_Z = answer == 0
    @flag_N = answer & (1 << 31) != 0
    # TODO: Carry flag
  end

  def set_arithmetic_flags(answer)
    @flag_V = answer & (1 << 31) != 0
    @flag_N = answer & (1 << 31) != 0
    # TODO: Carry flag
    @flag_Z = answer == 0
  end

  def run
    @pc = @registers[15]
    @opcode = @bus.arm9_get_opcode(@pc, @mode == Modes::ARM)
    @prevpc = @pc
    if @debug
      @debug_args_temp << "0x#{@pc.to_s(16)}"
    end
    if @debug_args.size > 300
      @debug_args.delete_at(0)
    end

    if @mode == Modes::ARM
      @pc += 4
      #puts "#{((@opcode >> 4) & 0xF).to_s(16)}, #{(((@opcode >> 16) & 0xFF0) >> 4).to_s(16)}"
      lut_index = (((@opcode >> 4) & 0xF) | ((@opcode >> 16) & 0xFF0))
      instruction = @armlut[lut_index]
      condition = (@opcode & (0xF << 28)) >> 28
      @cond = case condition
      when 0b0000 then @flag_Z ? true : false # EQ
      when 0b0001 then !@flag_Z ? true : false # NE
      #when 0b0101 then @flag_N ? true : false # ??
      #when 0b1010 then @flag_N == @flag_V
      when 0b1110 then true # AL
      else
        puts "DEBUG9: Invalid condition, #{condition.to_s(16)}"
        false
      end
      if @cond
        instruction.call
      end
    else
      @pc += 2
      decode_execute_thumb
    end
    @registers[15] = @pc
  end

  def running
    @running
  end

  def decode_execute_thumb
    op1 = (@opcode & (0xF << 8)) >> 8
    op2 = (@opcode & (0xF << 12)) >> 12
    if @opcode & 0b1110000000000000 == 0
      opcode_thumb_move_shifted_reg
    elsif @opcode & 0b1110000000000000 == 0b0110000000000000
      opcode_thumb_load_store_imm_offset
    elsif @opcode & 0b1110000000000000 == 0b0010000000000000
      opcode_thumb_move_compare_add_sub_imm
    elsif @opcode & 0b1111000000000000 == 0b1000000000000000
      opcode_thumb_lsh
    elsif @opcode & 0b1111111100000000 == 0b1011000000000000
      opcode_thumb_add_offset_sp
    elsif @opcode & 0b1111011000000000 == 0b1011010000000000
      opcode_thumb_push_pop_reg
    else
      puts "Unhandled THUMB opcode #{@opcode.to_s(2)}"
      @running = false
      #exit
    end
  end

  ############### OPCODES THUMB ###############
  # Most of these are just redirects to others#
  # Really need to clean the code up          #
  #############################################
  def opcode_thumb_add_offset_sp
    offset = @opcode & 0b1111111
    case offset & 0b11
    when 1 then offset <<= 2
    when 2 then offset <<= 1
    when 3 then offset <<= 2
    end
    if @opcode & (1 << 7) != 0
      offset *= -1
    end
    @sp &+= offset
  end

  def opcode_thumb_push_pop_reg
    pclr = @opcode & (1 << 8) != 0
    loadstore = @opcode & (1 << 11) != 0
    regrange = pclr ? (0...7) : (0...8)
    regrange.each do |i|
      if @opcode & (1 << i) != 0

        if loadstore
          if i = 8
            i = 15
          end
          @registers[i] = @bus.arm9_load32(@sp)
          @sp += 4
        else
          if i = 8
            i = 14
          end
          data = @registers[i]
          @bus.arm9_store32(@sp, data)
          @sp -= 4
        end
      end
    end
  end

  def opcode_thumb_load_store_imm_offset
    word = @opcode & (1 << 12) == 0
    loadstore = @opcode & (1 << 11) != 0
    offset = (@opcode & (0b11111 << 6)) >> 6
    basereg = (@opcode & 0b111000) >> 3
    sourcedestreg = @opcode & 0b111
    address = @registers[basereg] &+ offset

    if loadstore
      # Load
      if word
        data = @bus.arm9_load32(address)
      else
        data = @bus.arm9_load8(address)
      end
      @registers[sourcedestreg] = data
    else
      # Store
      data = @registers[sourcedestreg]
      if word
        @bus.arm9_store32(address, data)
      else
        @bus.arm9_store8(address, data)
      end
    end

  end

  def opcode_thumb_move_compare_add_sub_imm
    op = (@opcode & (0b11 << 11)) >> 11
    sourcedestreg = (@opcode & (0b111 << 8)) >> 8
    offset = @opcode & 0xFF
    case op
    when 0
      # MOV
      @registers[sourcedestreg] = offset
    when 1
      # CMP
      if @registers[sourcedestreg] &- offset == 0
        @flag_Z = true
      else
        @flag_Z = false
      end
    when 2
      # ADD
      @registers[sourcedestreg] &+= offset
      if  @registers[sourcedestreg] == 0
        @flag_Z = true
      else
        @flag_Z = false
      end
    when 3
      # SUB
      @registers[sourcedestreg] &-= offset
      if  @registers[sourcedestreg] == 0
        @flag_Z = true
      else
        @flag_Z = false
      end
    else
      puts "Unhandled thumb_move_compare_add_sub_imm op #{op}"
    end
  end

  def opcode_thumb_move_shifted_reg
    op = (@opcode & (0b11 << 11)) >> 11
    offset = (@opcode & (0b11111 << 6)) >> 6
    sourcereg = (@opcode & 0b111000) >> 3
    destreg = @opcode & 0b111

    case op
    when 0
      @registers[destreg] = @registers[sourcereg] << offset
    when 1
      @registers[destreg] = @registers[sourcereg] >> offset
    when 2
      msb = @registers[sourcereg] & 0b1000000000000000
      @registers[destreg] = (@registers[sourcereg] >> offset) | msb
    else
      puts "Unhandled move shifted reg op #{op}"
    end
  end

  def opcode_thumb_lsh
    loadstore = @opcode & (1 << 11) != 0
    offset = (@opcode & (0b11111 << 6)) >> 6
    basereg = (@opcode & 0b111000) >> 3
    basevalue = @registers[basereg]
    sourcedestreg = @opcode & 0b111

    address = basevalue &+ offset

    if loadstore
      data = @bus.arm9_load16(address).to_u32
      @registers[sourcedestreg] = data
    else
      data = @registers[sourcedestreg] & 0xFFFF
      @bus.arm9_store16(address, data)
    end
  end

  ################ OPCODES ARM ################

  def opcode_data_processing_imm_shift
    operation = (@opcode & (0b1111 << 21)) >> 21
    op1 = @registers[(@opcode & (0xF << 16)) >> 16]
    change_flags = (@opcode & (1 << 20)) != 0
    if @opcode & (1 << 25) != 0
      rot = ((@opcode & (0xF << 8)) >> 8)*2
      op2 = ((@opcode & 0xFF) >> rot) | ((@opcode & 0xFF) << (32 - rot))
    else
      shift = ((@opcode & 0xFF0) >> 4)
      shiftamount = shift & 1 == 0 ? (shift & 0b11111000) >> 3 : @registers[(shift & 0b11111000) >> 3] & 0xFF
      reg = @opcode & 0xF
      case (shift & 0b110) >> 1
      when 0b00
        op2 = @registers[reg] << shiftamount
      when 0b01
        if shiftamount == 0
          shiftamount = 32
        end
        op2 = @registers[reg] >> shiftamount
      else
        op2 = 0_u32
        puts "DEBUG9: Unimplemented data processing shift"
      end
      if reg == 15
         op2 = @registers[reg] + 8
      end
    end
    destination = (@opcode & (0xF << 12)) >> 12

    case operation
    when 0b0000 # AND
      answer = op1 & op2
      @registers[destination] = answer
      if change_flags
        set_logical_flags(answer)
      end
    when 0b0001 # EOR
      answer = op1 ^ op2
      @registers[destination] = answer
      set_logical_flags(answer)
    when 0b0010 # SUB
      answer = op1 &- op2
      @registers[destination] = answer
      if change_flags
        @flag_Z = answer == 0
      end
    #elsif operation == 0b0011
    when 0b0011 # RSB
      answer = op2 &- op1
      @registers[destination] = answer
    when 0b0100 # ADD
      answer = op1 &+ op2
      @registers[destination] = answer
      # TODO: FLAGS
      if change_flags
        @flag_N = answer & (1 << 31) != 0
        @flag_Z = answer == 0
      end
    when 0b0101 # ADC
      answer = op1 &+ op2
      if @flag_C
        answer += 1
      end
      @registers[destination] = answer
    when 0b0110 # SBC
      bit = @flag_C ? 1_u32 : 0_u32
      @registers[(@opcode & (0xF << 12)) >> 12] = op1 - op2 + bit - 1
    when 0b0111 # RSC
      answer = op2 - op1 - 1
      if @flag_C
        answer += 1
      end
    when 0b1000 # TST
      answer = op1 & op2
      if change_flags
        set_logical_flags(answer)
      end
    when 0b1001 # TEQ
      answer = op1 ^ op2
      if change_flags
        set_logical_flags(answer)
      end
    when 0b1010 # CMP
      answer = op1 &- op2
      @flag_Z = answer == 0
    when 0b1011 # CMN
      answer = op1 &+ op2
    when 0b1100 # ORR
      answer = op1 | op2
      @registers[destination] = answer
      if change_flags
        set_logical_flags(answer)
      end
    when 0b1101 # MOV
      @registers[destination] = op2
      if destination == 15
        @pc = op2
      end
      if change_flags
        set_logical_flags(op2)
      end
    when 0b1110 # BIC
      answer = op1 & ~op2
      @registers[destination] = answer
      if change_flags# && destination != 15
        set_logical_flags(answer)
      end
    when 0b1111 # MVN
      answer = ~op2
      @registers[destination] = answer
    else
      puts "DEBUG9: missing opcode_dataprocessing #{operation.to_s(2)}"
    end
  end

  def opcode_data_processing_imm_shift_flags
    opcode_data_processing_imm_shift
  end

  def opcode_data_processing_reg
    puts "Unhandled opcode_data_processing_reg"
  end

  def opcode_data_processing_reg_flag
    puts "Unhandled opcode_data_processing_reg_flag"
  end

  def opcode_load_store_misc # fix pls
    condition = (@opcode & (0xF << 28)) >> 28
    offset = (@opcode & (0xF << 8)) >> 4 | (@opcode & 0xF)
    base_reg = @registers[(@opcode & (0xF << 16)) >> 16]
    # TODO: sh checks
    sh = (@opcode & (0b11 << 5)) >> 5

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

    if @opcode & (1 << 20) == 0
      # Store to mem
      @bus.arm9_store16(addr, @registers[(@opcode & (0xF << 12)) >> 12])

      if @debug
        @debug_args_temp << "STRH"
        @debug_args_temp << addr.to_s(16)
        @debug_args_temp << @registers[(@opcode & (0xF << 12)) >> 12].to_s(16)
      end

    else
      # Load from mem
      data = @bus.arm9_load16(addr).to_u32
      @registers[(@opcode & (0xF << 12)) >> 12] = data

      if @debug
        @debug_args_temp << "LDRH"
        @debug_args_temp << ((@opcode & (0xF << 12)) >> 12).to_s(16)
        @debug_args_temp << data.to_s(16)
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

  def opcode_psrt_transfer
    if @opcode & 0b00001111101111110000111111111111 == 0b00000001000011110000000000000000 # MRS
      puts "Unhandled MRS"
    elsif @opcode & 0b00001111101111111111111111110000 == 0b00000001001010011111000000000000 # MSR, register to PSR
      dest_CPSR = @opcode & (1 << 22) == 0
      reg = @opcode & 0b1111
      data = @registers[reg]
      if dest_CPSR
        @cpsr = data
      else
        @spsr_irq = data
      end
    elsif @opcode & 0b00001101101111111111000000000000 == 0b00000001001010001111000000000000 # MSR reg or imm to PSR flag bits only
      puts "Unhandled MSR2"
    end
  end

  def opcode_qadd
    puts "Unhandled opcode_qadd"
  end

  def opcode_swap
    puts "Unhandled opcode_swap"
  end

  def opcode_blx2
    puts "Unhandled opcode_blx2"
  end

  def opcode_qsub
    puts "Unhandled opcode_qsub"
  end

  def opcode_clz
    puts "Unhandled opcode_clz"
  end

  def opcode_data_processing_imm
    opcode_data_processing_imm_shift
  end

  def opcode_data_processing_imm_flags
    opcode_data_processing_imm_shift
  end

  def opcode_load_store_imm
    if @opcode & (1 << 25) == 0
      # Immediate offset
      offset = @opcode & 0xFFF
    else
      shift = (@opcode & 0xFF0) >> 4
      if shift & 1 == 0
        shiftamount = (shift & 0b11111000) >> 3
      else
        shiftamount = @registers[(shift & 0b11110000) >> 4] & 0xFF
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
      base_reg += 8
    end
    storemem = @opcode & (1 << 20) == 0
    writeback = @opcode & (1 << 21) != 0
    datasize = @opcode & (1 << 22) == 0

    # TODO: write-back bit
    prepost = @opcode & (1 << 24) != 0
    add_offset = @opcode & (1 << 23) != 0
    address = base_reg
    if prepost
      if add_offset
        address += offset
      else
        address -= offset
      end
    end
    #puts "#{offset.to_s(16)}, pre_add #{prepost}, add #{add_offset}, writeback #{writeback}"


    if writeback && prepost
      @registers[(@opcode & (0xF << 16)) >> 16] = address
    end

    if storemem
      reg = (@opcode & (0xF << 12)) >> 12
      data = @registers[(@opcode & (0xF << 12)) >> 12]
      if reg == 15
        data += 12
      end
      if datasize
        @bus.arm9_store32(address, data)
      else
        @bus.arm9_store8(address, data)
      end
    else
      if datasize
        data = @bus.arm9_load32(address)
      else
        data = @bus.arm9_load8(address)
      end
      reg = (@opcode & (0xF << 12)) >> 12
      @debug_args_temp << reg.to_s
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
        if reg == 15
          @pc = data
        end
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

  def opcode_load_store_shift
    puts "Unhandled opcode_load_store_shift"
  end

  def opcode_stm
    base_addr = @registers[(@opcode & (0xF << 16)) >> 16]
    store = @opcode & (1 << 20) == 0
    writeback = @opcode & (1 << 21) != 0
    # TODO: PSR & force user bit
    up = @opcode & (1 << 23) != 0
    pre = @opcode & (1 << 24) != 0

    regs = Array(UInt8).new
    (0_u8...16_u8).each do |i|
      if @opcode & (1 << i) != 0
        regs << i
      end
    end

    if store
      if pre
        if up
          base_addr &+= 4
        else
          base_addr &-= 4
        end
      end
      if !up
        base_addr &-= 4*(regs.size - 1)
      end
      regs.each do |reg|
        @bus.arm9_store32(base_addr, @registers[reg])
        base_addr &+= 4
      end
    else
      if pre
        if up
          base_addr &+= 4
        else
          base_addr &-= 4
        end
      end
      if !up
        base_addr &-= 4*(regs.size - 1)
      end
      regs.each do |reg|
        @registers[reg] = @bus.arm9_load32(base_addr)
        base_addr &+= 4
      end
    end

    if !pre || (pre && writeback)
      @registers[(@opcode & (0xF << 16)) >> 16] = base_addr
    end

  end

  def opcode_ldm
    opcode_stm
  end

  def opcode_branch_link
    offset = (@opcode & 0xFFFFFF).to_i32
    offset = offset - ((offset >> 23) << 24)
    linkbit = @opcode & (1 << 24) != 0
    if linkbit
      @registers[14] = @pc
    end
    @pc = @pc + 4 + offset*4
  end

  def opcode_cop_data_transfer
    puts "Unhandled opcode_cop_data_transfer"
  end

  def opcode_cop_data_operation
    puts "Unhandled opcode_cop_data_operation"
  end

  def opcode_swi
    puts "Unhandled opcode_swi"
  end

  def opcode_multiply
    puts "Unhandled opcode_multiply"
  end

  def opcode_multiply_long
    puts "Unhandled opcode_multiply_long"
  end

  def opcode_branch_exchange
    reg = @opcode & 0xF
    val = @registers[reg]
    @pc = val
    @registers[15] = @pc
    if val & 1 == 1
      @mode = Modes::THUMB
      puts "Continuing on THUMB"
    else
      @mode = Modes::ARM
      puts "Continuing on ARM"
    end
  end

  def opcode_branch
    offset = (@opcode & 0xFFFFFF).to_i32
    offset = offset - ((offset >> 23) << 24)
    linkbit = @opcode & (1 << 24) != 0
    if linkbit
      @registers[14] = @pc
    end
    @pc = @pc + 4 + offset*4
  end

  def opcode_cop_reg_transfer
    puts "Unhandled opcode_cop_reg_transfer"
  end
end
