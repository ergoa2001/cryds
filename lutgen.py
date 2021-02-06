armlut = [""] * 4096

BX_OPCODE = 0b000100100001
BLX2_OPCODE = 0b000100100011
CLZ_OPCODE = 0b000101100001
QADD_OPCODE = 0b000100000101
QSUB_OPCODE = 0b000100100101

def isBitSet(data, bitpos):
    if data & (1 << bitpos) != 0:
        return True
    else:
        return False

def populate_arm_lut():
    for x in range(4096):
        if x & 0xF01 == 0xE00:
            armlut[x] = "->opcode_cop_data_operation"
        elif x & 0xF01 == 0xE01:
            armlut[x] = "->opcode_cop_reg_transfer"
        elif (x >> 9) == 0b110:
            armlut[x] = "->opcode_cop_data_transfer"
        elif x & 0xF00 == 0xF00:
            armlut[x] = "->opcode_swi"
        elif (x & 0xF8F) == 0x89 or ((x >> 4) == 0x10 and not isBitSet(x, 0) and isBitSet(x, 3)) or ((x >> 4) == 0x12 and not isBitSet(x, 0) and isBitSet(x, 1) and isBitSet(x, 3)) or ((x >> 4) == 0x12 and not isBitSet(x, 0) and not isBitSet(x, 1) and isBitSet(x, 3)) or ((x >> 4) == 0x14 and not isBitSet(x, 0) and isBitSet(x, 3)) or ((x >> 4) == 0x16 and not isBitSet(x, 0) and isBitSet(x, 3)):
            armlut[x] = "->opcode_multiply_long"
        elif (x & 0xFCF) == 0x9:
            armlut[x] = "->opcode_multiply"
        elif (x >> 8) == 0b1010:
            armlut[x] = "->opcode_branch"
        elif (x >> 8) == 0b1011:
            armlut[x] = "->opcode_branch_link"
        elif x == BX_OPCODE:
            armlut[x] = "->opcode_branch_exchange"
        elif x == BLX2_OPCODE:
            armlut[x] = "->opcode_blx2"
        elif x == CLZ_OPCODE:
            armlut[x] = "->opcode_clz"
        elif x == QADD_OPCODE:
            armlut[x] = "->opcode_qadd"
        elif x == QSUB_OPCODE:
            armlut[x] = "->opcode_qsub"
        elif ((x >> 7) == 0b00010 and (x & 0xF) == 0 and not isBitSet(x, 4)) or ((x >> 7) == 0b00110 and not isBitSet(x, 4)):
            armlut[x] = "->opcode_psrt_transfer"
        elif x & 0xFBF == 0x109:
            armlut[x] = "->opcode_swap"
        elif (x >> 9) == 0b010:
            armlut[x] = "->opcode_load_store_imm"
        elif (x >> 9) == 0b011:
            armlut[x] = "->opcode_load_store_shift"
        elif (x & 0b1001) == 0b1001 and (x >> 9) == 0:
            armlut[x] = "->opcode_load_store_misc"
        elif (x >> 9) == 0b100 and ((x >> 4) & 1) == 1:
            armlut[x] = "->opcode_ldm"
        elif (x >> 9) == 0b100:
            armlut[x] = "->opcode_stm"
        elif ((x >> 7) & 0x1F) == 0b00110 and ((x >> 4) & 3) == 0:
            armlut[x] = "->opcode_undefined"
        elif (x >> 9) == 0b001 and ((x >> 4) & 1 == 1):
            armlut[x] = "->opcode_data_processing_flags"
        elif (x >> 9) == 0b001:
            armlut[x] = "->opcode_data_processing_imm"
        elif (x >> 9) == 0 and (x & 1) == 0 and ((x >> 4) & 1 == 1):
            armlut[x] = "->opcode_data_processing_imm_shift_flags"
        elif (x >> 9) == 0 and (x & 1) == 0:
            armlut[x] = "->opcode_data_processing_imm_shift"
        elif (x >> 9) == 0 and ((x >> 4) & 1 == 1):
            armlut[x] = "->opcode_data_processing_reg_flag"
        elif (x >> 9) == 0:
            armlut[x] = "->opcode_data_processing_reg"
        else:
            armlut[x] = "->opcode_undefined"
    with open("armlut.txt", "w") as fp:
        fp.write(", ".join(armlut))

    print(armlut)

populate_arm_lut()
