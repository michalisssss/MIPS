library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MIPS_testbench is
end MIPS_testbench;

architecture testbench of MIPS_testbench is

	component MIPS port(
		reset: in std_logic;
		clock: in std_logic);
	end component;
	
	-- Constants
    constant CLOCK_PERIOD: time := 50 ns;

    -- Signals
    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
begin

    -- Instantiate the components
	MIPS: MIPS port map(reset => reset, clock => clock);

    -- Clock process
    CLK_process :process begin
		if now < CLOCK_PERIOD * 22 then -- 22 clock periods are enough to execute all the instructions 
			clock <= '0';
			wait for CLOCK_PERIOD/2;
			clock <= '1';
			wait for CLOCK_PERIOD/2;
		else
			wait;
		end if;
   end process;
 

   -- Stimulus process
   stim_proc: process begin		
		reset <= '1';
		wait for CLOCK_PERIOD/2;	
		reset <= '0';
		wait;
   end process;
	
end testbench;