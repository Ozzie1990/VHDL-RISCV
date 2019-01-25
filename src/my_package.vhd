library ieee;
use ieee.std_logic_1164.all;

package my_package is 

    type to_cpu_from_inst_dcdr is record
        instr       : out   std_logic_vector(31 downto 0);  --Instruction
        op_code     : out   std_logic_vector(4 downto 0);   --Operation Code Out
        rd          : out   std_logic_vector(4 downto 0);   --RD Data
        rs1, rs2    : out   std_logic_vector(4 downto 0);   --RS1 (or ZIMM) & RS2 (or SHAMT)
        csr         : out   std_logic_vector(11 downto 0);
        succ        : out   std_logic_vector(3 downto 0);
        pred        : out   std_logic_vector(3 downto 0);
        immediate   : out   std_logic_vector(31 downto 0);
    end record
end my_package