library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instuction_decoder is
  port (
    clk         : in    std_logic;
    data_in     : in    std_logic_vector(31 downto 0);  --Data In (32 bits)
    instr       : out   std_logic_vector(31 downto 0);  --Instruction
    op_code     : out   std_logic_vector(4 downto 0);   --Operation Code Out
    rd          : out   std_logic_vector(4 downto 0);   --RD Data
    rs1, rs2    : out   std_logic_vector(4 downto 0);   --RS1 (or ZIMM) & RS2 (or SHAMT)
    csr         : out   std_logic_vector(11 downto 0);
    succ        : out   std_logic_vector(3 downto 0);
    pred        : out   std_logic_vector(3 downto 0);
    immediate   : out   std_logic_vector(31 downto 0) 
  ) ;
end instuction_decoder;

architecture behavior of instruct_decorder is

  --Op Code
  constant INT_REG_IMMED    : std_logic_vector(4 downto 0) := "00100";
  constant INT_REG          : std_logic_vector(4 downto 0) := "01100";
  constant BRANCH           : std_logic_vector(4 downto 0) := "11000";
  constant LOAD             : std_logic_vector(4 downto 0) := "00000";
  constant STORE            : std_logic_vector(4 downto 0) := "01000";
  constant FENCE            : std_logic_vector(4 downto 0) := "00011";
  constant LUI              : std_logic_vector(4 downto 0) := "01101";
  constant AUIPC            : std_logic_vector(4 downto 0) := "00101";
  constant JAL              : std_logic_vector(4 downto 0) := "11011";
  constant JALR             : std_logic_vector(4 downto 0) := "11001";
  constant FENCE            : std_logic_vector(4 downto 0) := "00011";
  constant FENCEI           : std_logic_vector(4 downto 0) := "00011";
  constant CONDITIONAL      : std_logic_vector(4 downto 0) := "11100";

  --Functions--
  --Branch
  constant BEQ      : std_logic_vector(3 downto 0) := "0000";
  constant BNE      : std_logic_vector(3 downto 0) := "0001";
  constant BLT      : std_logic_vector(3 downto 0) := "0100";
  constant BGE      : std_logic_vector(3 downto 0) := "0101";
  constant BLTU     : std_logic_vector(3 downto 0) := "0110";
  constant BGEU     : std_logic_vector(3 downto 0) := "0111";

  --Load
  constant LB       : std_logic_vector(3 downto 0) := "0000";
  constant LH       : std_logic_vector(3 downto 0) := "0001";
  constant LW       : std_logic_vector(3 downto 0) := "0010";
  constant LBU      : std_logic_vector(3 downto 0) := "0100";
  constant LHU      : std_logic_vector(3 downto 0) := "0101";

  --Store
  constant SB       : std_logic_vector(3 downto 0) := "0000";
  constant SH       : std_logic_vector(3 downto 0) := "0001";
  constant SW       : std_logic_vector(3 downto 0) := "0010";

  --Instruction Register: Immediate
  constant ADDI     : std_logic_vector(3 downto 0) := "0000";
  constant SLTI     : std_logic_vector(3 downto 0) := "0010";
  constant SLTIU    : std_logic_vector(3 downto 0) := "0011";
  constant XORI     : std_logic_vector(3 downto 0) := "0100";
  constant ORI      : std_logic_vector(3 downto 0) := "0110";
  constant ANDI     : std_logic_vector(3 downto 0) := "0111";
  constant SLLI     : std_logic_vector(3 downto 0) := "0001";
  constant SRLI     : std_logic_vector(3 downto 0) := "0101";
  constant SRAI     : std_logic_vector(3 downto 0) := "1101";

  --Instruction Register
  constant ADD      : std_logic_vector(3 downto 0) := "0000";
  constant SUB      : std_logic_vector(3 downto 0) := "1000";
  constant SLL_A    : std_logic_vector(3 downto 0) := "0001";
  constant SLT      : std_logic_vector(3 downto 0) := "0010";
  constant SLTU     : std_logic_vector(3 downto 0) := "0011";
  constant XOR_A    : std_logic_vector(3 downto 0) := "0100";
  constant SRL_A    : std_logic_vector(3 downto 0) := "0101";
  constant SRA_A    : std_logic_vector(3 downto 0) := "0101";
  constant OR_A     : std_logic_vector(3 downto 0) := "0110";
  constant AND_A    : std_logic_vector(3 downto 0) := "0111";

  --Fence
  constant FENCE    : std_logic_vector(3 downto 0) := "0000";
  constant FENCEI   : std_logic_vector(3 downto 0) := "0001";

  --E?
  constant ECALL    : std_logic_vector(3 downto 0) := "0000";
  constant EBREAK   : std_logic_vector(3 downto 0) := "1000";

  --Conditional
  constant CSRRW    : std_logic_vector(3 downto 0) := "0001";
  constant CSRRS    : std_logic_vector(3 downto 0) := "0010";
  constant CSRRC    : std_logic_vector(3 downto 0) := "0011";
  constant CSRRWI   : std_logic_vector(3 downto 0) := "0101";
  constant CSRRSI   : std_logic_vector(3 downto 0) := "0110";
  constant CSRRCI   : std_logic_vector(3 downto 0) := "0111";

  --Signal
  signal s_op_code  : std_logic_vector(4 downto 0);
  signal s_data_in  : std_logic_vector(31 downto 0);
  signal s_func     : std_logic_vector(2 downto 0);
  signal s_data_out : std_logic_vector(31 downto 0);
  signal s_rs1      : std_logic_vector(4 downto 0);
  signal s_command  : std_logic_vector(31 downto 0);

begin

  s_op_code <= op_code(6 downto 2);
  s_func <= op_code(14 downto 12);
  instr <= s_command;

  process(clk)
  begin
    if rising_edge(clk) then
      case( s_op_code ) is

        --*****************************
        --BRANCH Instruction
        --*****************************
        when BRANCH =>
          case( op_code(30) & s_func ) is 
            s_rs1 <= s_data_in(19 downto 15);
            
        --*****************************
        --LOAD Instruction
        --*****************************
        when LOAD =>
          
          case( op_code(30) & s_func ) is
          
            when LB =>
              s_command <= std_logic_vector(unsigned(10));

            when LH =>
              s_command <= std_logic_vector(unsigned(11));

            when LW =>
              s_command <= std_logic_vector(unsigned(12));

            when LBU =>
              s_command <= std_logic_vector(unsigned(13));

            when LHU =>
              s_command <= std_logic_vector(unsigned(14));

            when others =>
              s_command <= 0x"FFFFFFFF";
          
          end case ;
        --*****************************

        --*****************************
        --STORE Instruction
        --*****************************
        when STORE =>
          
          case( op_code(30) & s_func ) is
          
            when SB =>
              s_command <= std_logic_vector(unsigned(15));

            when SH =>
              s_command <= std_logic_vector(unsigned(16));

            when SW =>
              s_command <= std_logic_vector(unsigned(17));
          
            when others =>
              s_command <= 0x"FFFFFFFF";

          end case ;
          --*****************************

          --*****************************
          --Integer IMMEDIATE Instruction
          --*****************************
          when INT_REG_IMMED =>

            case( op_code(30) & s_func ) is
            
              when ADDI =>
                s_command <= std_logic_vector(unsigned(18));

              when SLTI =>
                s_command <= std_logic_vector(unsigned(19));

              when SLTIU =>
                s_command <= std_logic_vector(unsigned(20));

              when XORI =>
                s_command <= std_logic_vector(unsigned(21));

              when ORI =>
                s_command <= std_logic_vector(unsigned(22));

              when ANDI =>
                s_command <= std_logic_vector(unsigned(23));

              when SLLI =>
                s_command <= std_logic_vector(unsigned(24));

              when SRLI =>
                s_command <= std_logic_vector(unsigned(25));

              when SRAI =>
                s_command <= std_logic_vector(unsigned(26));
            
              when others =>
                s_command <= 0x"FFFFFFFF";

            end case ;
          ---*****************************

          --*****************************
          --Integer Instruction
          --*****************************
          when INT_REG=>

            case( op_code(30) & s_func ) is
            
              when ADD =>
                s_command <= std_logic_vector(unsigned(27));

              when SUB =>
                s_command <= std_logic_vector(unsigned(28));
              
              when SLL_A =>
                s_command <= std_logic_vector(unsigned(29));

              when SLT =>
                s_command <= std_logic_vector(unsigned(30));

              when SLTU =>
                s_command <= std_logic_vector(unsigned(31));

              when XOR_A =>
                s_command <= std_logic_vector(unsigned(32));

              when SRL_A =>
                s_command <= std_logic_vector(unsigned(33));

              when SRA_A =>
                s_command <= std_logic_vector(unsigned(34));

              when OR_A =>
                s_command <= std_logic_vector(unsigned(35));

              when AND_A =>
                s_command <= std_logic_vector(unsigned(36));
            
              when others =>
                s_command <= 0x"FFFFFFFF";
            
            end case ;
          ---*****************************
          when FENCE =>

          when LUI =>

          when AUIPC =>

          when JAL =>

          when JALR =>

          when FENCE =>

          when FENCEI =>

          when CONDITIONAL =>
          when others =>
        
        end case ;
    
      when others =>
    
    end case ;
  end process;
end behavior ; -- behavior