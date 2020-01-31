library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registers is
    generic(BIT_WIDTH : integer := 32); --Set Bit Width
  port (
    clk         :   in      std_logic;
    reg_sel     :   in      std_logic_vector(7 downto 0);   --Regiser Selection
    data        :   inout   std_logic_vector(BIT_WIDTH-1 downto 0); 
    rd_wr       :   in      std_logic;  --Read(0) and Write(1)
    ready       :   in      std_logic   --Ready to input/output from CPU (1=Ready)
  ) ;
end registers;

architecture behavior of registers is

    --Register Declaration
    type register_array is array (31 downto 0) of std_logic_vector(BIT_WIDTH-1 downto 0);
    
    --Signal Declarations
    signal data_buffer  :   std_logic_vector(BIT_WIDTH-1 downto 0);
    signal reg          :   register_array;

begin

    --Buffers
    data <= data_buffer;

    --Register 0 must always equal 0
    reg(0) <= (others=>'0');

    --********************************************
    --Main Process
    --When rising edge and ready is high we either write data to the register
    --or read data from the register and provide it to the CPU
    --********************************************
    process(clk)
    begin
        if rising_edge(clk) and ready='1' then
            if rd_wr='0' then --Read
                data_buffer <= reg(reg_sel);
            elsif rd_wr='1' then --Write
                if not(reg_sel = x"00") then
                    reg(reg_sel) <= data_buffer;
                end if;
            end if;
        end if;
    end process;

end behavior ; -- behavior