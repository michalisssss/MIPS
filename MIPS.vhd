--ProgramCounter
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ProgramCounter is port(
	PCin: in std_logic_vector(31 downto 0);
	PCout: out std_logic_vector(31 downto 0);
	clock, reset: in std_logic);
end ProgramCounter;

architecture behavioral of ProgramCounter is
begin
	process (clock, reset) begin
		if reset = '1' then
			PCout <= (others => '0'); --resetting PC
		elsif rising_edge(clock) then
			PCout <= PCin; -- where PCin is PC+1
		end if;
	end process;
end behavioral;



--ANDgate
library ieee;
use ieee.std_logic_1164.all;

entity ANDgate is port(
	ANDin1, ANDin2: in std_logic;
	ANDout: out std_logic);
end ANDgate;

architecture dataflow of ANDgate is
begin
	ANDout <= ANDin1 and ANDin2;
end dataflow;



--MUX32
library ieee;
use ieee.std_logic_1164.all;

entity MUX32 is port(
	MUXin1, MUXin2: in std_logic_vector(31 downto 0);
	MUXout: out std_logic_vector(31 downto 0);
	en: in std_logic);
end MUX32;

architecture dataflow of MUX32 is
begin
	MUXout <= MUXin1 when en = '0' else MUXin2;
end dataflow;



--MUX5
library ieee;
use ieee.std_logic_1164.all;

entity MUX5 is port(
	MUXin1, MUXin2: in std_logic_vector(4 downto 0);
	MUXout: out std_logic_vector(4 downto 0);
	en: in std_logic);
end MUX5;

architecture dataflow of MUX5 is
begin
	MUXout <= MUXin1 when en='0' else MUXin2;
end dataflow;



--FullAdder
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FullAdder is port (
        FAin1, FAin2: in std_logic_vector(31 downto 0);
        Cin: in std_logic_vector(0 downto 0);--must be a vector or else there is an error in conversion below
        Cout: out std_logic;
        Sum: out std_logic_vector(31 downto 0));
end FullAdder;

architecture dataflow of FullAdder is
    signal tmp: std_logic_vector(32 downto 0);
begin
    tmp <= std_logic_vector(to_signed( to_integer(signed(FAin1)) + to_integer(signed(FAin2)) + to_integer(signed(Cin)), 33)); --TL;DR signed addition
    -- the inputs are converted to signed integer values and then the result is reconverted 33-bit singed integer representation which is assigned as a logic vector
    Cout <= tmp(32);
    Sum <= tmp(31 downto 0);
end dataflow;



--SignExtender
library ieee;
use ieee.std_logic_1164.all;

entity SignExtender is port(
	SignIn: in std_logic_vector(15 downto 0);
	SignOut: out std_logic_vector(31 downto 0));
end SignExtender;

architecture dataflow of SignExtender is
	signal ones: std_logic_vector(15 downto 0) := (others => '1');
	signal zeros: std_logic_vector(15 downto 0) := (others => '0');
begin
	SignOut <= ones & SignIn when SignIn(15) = '1'  -- adding 16 '1' bits
		else zeros & SignIn when SignIn(15) = '0';  -- adding 16 '0' bits
end dataflow;



--InstructionMemory
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity InstructionMemory is port(
	IMin: in std_logic_vector(31 downto 0);
	IMout: out std_logic_vector(31 downto 0));
end InstructionMemory;

architecture behavioral of InstructionMemory is
	type IM_array is array(0 to 15) of std_logic_vector(31 downto 0); -- 16 slots of 32 bits each
	signal commands: IM_array:=(X"20000000", -- addi $0, $0, 0
								X"20420000", -- addi $2, $2, 0
								X"20820000", -- addi $2, $4, 0
								X"20030001", -- addi $3, $0, 1
								X"20050003", -- addi $5, $0, 3
								X"00603020", -- L1: add $6, $3, $0
								X"AC860000", -- sw $6, 0($4)
								X"20630001", -- addi $3, $3, 1
								X"20840001", -- addi $4, $4, 1
								X"20A5FFFF", -- addi $5, $5, -1
								X"14A0FFFA", -- bne $5,$0,L1
								X"00000000", -- slot padding
								X"00000000", -- slot padding
								X"00000000", -- slot padding
								X"00000000", -- slot padding
								X"00000000");-- slot padding

begin

	IMout <= commands(to_integer(unsigned(IMin))); --assigning a value (instruction) from the commands array to the signal IMout based on the value of IMin

end behavioral;



--DataMemory
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DataMemory is port(
	clock: in std_logic;
	DMin: in std_logic_vector(31 downto 0);
	WriteData:  in std_logic_vector(31 downto 0);
	MemWrite: in std_logic;
	MemRead: in std_logic;
	DMout: out std_logic_vector(31 downto 0);
	reset: in std_logic);
end entity;

architecture dataflow of DataMemory is
	type DM_array is array(0 to 15) of std_logic_vector(31 downto 0); --memory storage of 16 elements that fit 32 bit each
	signal address: integer:= 0;
	signal RAM: DM_array := (others => (others => '0')); --initialization of array RAM with 0
begin
		address <= to_integer(unsigned(DMin)) when (to_integer(unsigned(DMin)) <= 15) else 0;
		
		RAM(address) <= WriteData when (MemWrite = '1' and reset = '0' and rising_edge(clock));
		
		DMout <= RAM(address) when (reset = '0' and MemRead = '1') else x"00000000"; --DMout becomes the value stored in the address	
		
end dataflow;



--ControlUnit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ControlUnit is port(
	clock: in std_logic;
	OPcode: in std_logic_vector(5 downto 0);
	RegWrite: out std_logic := '0';
	ALUsrc: out std_logic;
	ALUop: out std_logic_vector(2 downto 0);
	MemWrite: out std_logic;
	MemRead: out std_logic;
	RegDst: out std_logic;
	MemToReg: out std_logic;
	Branch: out std_logic);
end ControlUnit;

architecture dataflow of ControlUnit is
begin
	with OPcode select
		RegWrite <=
			('1' and clock) when "100011", --load
			('1' and clock) when "000000", --arithmetic
			('1' and clock) when "001000", --addi
			'0' when others;
	
	with OPcode select
		ALUsrc <=
			'1' after 2 ns when "100011", --load
			'1' after 2 ns when "101011", --store
			'1' after 2 ns when "001000", --addi
			'0' when others;
	
	with OPcode select
		ALUop <=
			"000" after 2 ns when "000000", --arithmetic
			"001" after 2 ns when "100011", --load
			"001" after 2 ns when "101011", --store
			"011" after 2 ns when "000101", --bne
			"100" after 2 ns when "001000", --addi
			"111" when others;
		
	with OPcode select
		MemWrite <=
			'1' after 10 ns when "101011", --store
			'0' when others;
	
	with OPcode select
		MemRead <=
			'1' after 2 ns when "100011", --read
			'0' when others;
			
	with OPcode select
		MemToReg <=
			'1' after 2 ns when "100011", --read
			'0' when others;
	
	with OPcode select
		RegDst <=
			'0' when "100011", --load
			'0' when "001000", --addi
			'1' when others;
	
	with OPcode select
		Branch <=
			'1' when "000101", --bne
			'0' when others;
		
end dataflow; 



--ALUcontrolUnit
library ieee;
use ieee.std_logic_1164.all;

entity ALUcontrolUnit is port(
	ALUop: in std_logic_vector(2 downto 0);
	Funct: in std_logic_vector(5 downto 0);
	ALUcontrolUnitOut: out std_logic_vector(3 downto 0));
end ALUcontrolUnit;

architecture dataflow of ALUcontrolUnit is
	
	signal tmpFunct: std_logic_vector(3 downto 0) := (others => '0');
	signal tmpALUop: std_logic_vector(3 downto 0) := (others => '0');
begin							 
	with Funct select
		tmpFunct <=
			"0001" when "100000", --add/sub
			"1111" when others;
			
		with ALUop select
			tmpALUop <=
				"0001" when "001", --store/load
				"1011" when "011", --bne
				"1101" when "100", --addi
				"1111" when others;
				
		with ALUop select
			ALUcontrolUnitOut <=
				tmpFunct when "000",
				tmpALUop when others;
end dataflow;



--ALU
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is port(
		ALUin1, ALUin2: in std_logic_vector(31 downto 0);
		op: in std_logic_vector(3 downto 0);
		ALUout: out std_logic_vector(31 downto 0);
		Zero: out std_logic);
end ALU;

architecture dataflow of ALU is
	
	component FullAdder port(
		FAin1, FAin2: in std_logic_vector(31 downto 0);
		Cin: in std_logic_vector(0 downto 0);
		Cout: out std_logic;
		Sum: out std_logic_vector(31 downto 0));
	end component;
	
	signal Cout: std_logic;
	signal FAout: std_logic_vector(31 downto 0);
	signal X: std_logic_vector(31 downto 0) := (others => 'X');
	
begin
	FA_ALU: FullAdder port map( FAin1 => ALUin1, FAin2 => ALUin2, Cin => "0", Sum => FAout, Cout => Cout);
	
	with op select
		ALUout <=
			FAout when "0001", --sum
			FAout when "1101", --addi
			X when others;
			
	Zero <= '1' when ( (ALUin1 /= ALUin2) and (op = "1011") ) else '0';
	
end dataflow;



--RegisterFile
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegisterFile is port (
		clock: in std_logic;
        RegIn1: in std_logic_vector(4 downto 0);
        RegIn2: in std_logic_vector(4 downto 0);
        RegWriteIn: in std_logic_vector(4 downto 0);
        DataWriteIn: in std_logic_vector(31 downto 0);
        RegWrite: in std_logic;
        RegOut1: out std_logic_vector(31 downto 0);
        RegOut2: out std_logic_vector(31 downto 0));
end RegisterFile;

architecture behavioral of RegisterFile is
    type RF_ARRAY is array(0 to 15) of std_logic_vector(31 downto 0);
	
	signal X: std_logic_vector(31 downto 0) := (others => 'X');
    signal reg: RF_ARRAY := (others => (others => '0'));
	signal RegWriteDelayed: std_logic;
begin
	process (clock) begin
		RegOut1 <= reg(to_integer(unsigned(RegIn1)));
		RegOut2 <= reg(to_integer(unsigned(RegIn2)));
		RegWriteDelayed <= transport RegWrite after 1 ns;	
		if (rising_edge(clock) and RegWriteDelayed = '1' and DataWriteIn /= X) then			
			reg(to_integer(unsigned(RegWriteIn))) <= DataWriteIn;
		end if;
	end process;
end behavioral;



--MIPS
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MIPS is port(
	reset: in std_logic;
	clock: in std_logic);
end MIPS;

architecture structural of MIPS is

	component ALU port(
		ALUin1, ALUin2: in std_logic_vector(31 downto 0);
		op: in std_logic_vector(3 downto 0);
		ALUout: out std_logic_vector(31 downto 0);
		Zero: out std_logic);
	end component;
	
	component RegisterFile port(
		clock: in std_logic;
		RegIn1: in std_logic_vector(4 downto 0);
		RegIn2: in std_logic_vector(4 downto 0);
		RegWriteIn: in std_logic_vector(4 downto 0);
		DataWriteIn: in std_logic_vector(31 downto 0);
		RegWrite: in std_logic;
		RegOut1: out std_logic_vector(31 downto 0);
		RegOut2: out std_logic_vector(31 downto 0));
	end component;

	component DataMemory port(
		clock: in std_logic;
		DMin: in std_logic_vector(31 downto 0);
		WriteData:  in std_logic_vector(31 downto 0);
		MemWrite: in std_logic;
		MemRead: in std_logic;
		DMout: out std_logic_vector(31 downto 0);
		reset: in std_logic);
	end component;

	component InstructionMemory port(
		IMin: in std_logic_vector(31 downto 0);
		IMout: out std_logic_vector(31 downto 0));
	end component;

	component ControlUnit port(
		clock: in std_logic;
		OPcode: in std_logic_vector(5 downto 0);
		RegWrite: out std_logic;
		ALUsrc: out std_logic;
		ALUop: out std_logic_vector(2 downto 0);
		MemWrite: out std_logic;
		MemRead: out std_logic;
		RegDst: out std_logic;
		MemToReg: out std_logic;
		Branch: out std_logic);
	end component;

	component ALUcontrolUnit port(
		ALUop: in std_logic_vector(2 downto 0);
		Funct: in std_logic_vector(5 downto 0);
		ALUcontrolUnitOut: out std_logic_vector(3 downto 0));
	end component;

	component ProgramCounter port(
		PCin: in std_logic_vector(31 downto 0);
		PCout: out std_logic_vector(31 downto 0);
		clock, reset: in std_logic);
	end component;

	component MUX5 port(
		MUXin1, MUXin2: in std_logic_vector(4 downto 0);
		MUXout: out std_logic_vector(4 downto 0);
		en: in std_logic);
	end component;

	component SignExtender port(
		SignIn: in std_logic_vector(15 downto 0);
		SignOut: out std_logic_vector(31 downto 0));
	end component;

	component MUX32 port(
		MUXin1, MUXin2: in std_logic_vector(31 downto 0);
		MUXout: out std_logic_vector(31 downto 0);
		en: in std_logic);
	end component;

	component ANDgate is port(
		ANDin1, ANDin2: in std_logic;
		ANDout: out std_logic);
	end component;
	
	component FullAdder port(
		FAin1, FAin2: in std_logic_vector(31 downto 0);
		Cin: in std_logic_vector(0 downto 0);
		Cout: out std_logic;
		Sum: out std_logic_vector(31 downto 0));
	end component;

--Control Unit signals
signal RegDst: std_logic;
signal Branch: std_logic;
signal MemRead: std_logic;
signal MemToReg: std_logic;
signal ALUop: std_logic_vector(2 downto 0);
signal MemWrite: std_logic;
signal ALUSrc: std_logic;
signal RegWrite: std_logic;
signal Zero: std_logic;
signal BranchOut: std_logic; --output of Branch/AND gate

--Program Counter signals
signal PCtoFAorIM: std_logic_vector(31 downto 0); -- PC output towards FullAdder or InstructionMemory
signal number1: std_logic_vector(31 downto 0); --integer number 1
signal FAplusplusOut: std_logic_vector(31 downto 0); -- output of FullAdder + 1
signal FA2toMUX: std_logic_vector(31 downto 0); --FA2 to MUX
signal MUXtoPC: std_logic_vector(31 downto 0); -- MUX to PC

-- others
signal IMoutput: std_logic_vector(31 downto 0); -- InstructionMemory output
signal MUXtoReg: std_logic_vector(4 downto 0); -- MUX to RegisterFile
signal ExtendedSign: std_logic_vector(31 downto 0); -- SignExtension to Adder (Shifter doesnt exist)

signal RegOut1: std_logic_vector(31 downto 0); -- RegisterFile to ALU
signal RegOut2: std_logic_vector(31 downto 0); -- RegisterFile to MUX
signal MUXtoALU: std_logic_vector(31 downto 0); -- MUX to ALU
signal ALUcontrolUnitToALU: std_logic_vector(3 downto 0);-- ALUcontrolUnit to ALU
signal ALUout: std_logic_vector(31 downto 0); -- ALU output towards DataMemory or MUX	
signal DataWriteIn: std_logic_vector(31 downto 0); -- RegisterFile output towards DataMemory
signal DMout: std_logic_vector(31 downto 0); --DataMemory to MUX


begin

	number1 <= std_logic_vector(to_unsigned(1, 32));
	FA: FullAdder port map (FAin1 => PCtoFAorIM, FAin2 => number1, Cin => "0", Sum => FAplusplusOut); --Cin is String (0 downto 0)
	
	FA2: FullAdder port map(FAin1 => FAplusplusOut, FAin2 => ExtendedSign, Cin => "0", Sum => FA2toMUX); --Cin is String (0 downt 0)
	
	PC: ProgramCounter port map(PCin => MUXtoPC, PCout => PCtoFAorIM, clock => clock, reset => reset);
	
	IM: InstructionMemory port map(IMin => PCtoFAorIM, IMout => IMoutput);

	MUX_RF: MUX5 port map(MUXin1 => IMoutput(20 downto 16), MUXin2 => IMoutput(15 downto 11), MUXout => MUXtoReg, en => RegDst);
	
	RF: RegisterFile port map(clock => clock, RegIn1 => IMoutput(25 downto 21), RegIn2 => IMoutput(20 downto 16), RegWriteIn => MUXtoReg, DataWriteIn => DataWriteIn, RegWrite => RegWrite, RegOut1 => RegOut1, RegOut2 => RegOut2);
	
	CU: ControlUnit port map(clock => clock, OPcode => IMoutput(31 downto 26), RegWrite => RegWrite, ALUsrc => ALUSrc, ALUop => ALUop, MemWrite => MemWrite, MemRead => MemRead, RegDst => RegDst, MemToReg => MemToReg, Branch => Branch);
	
	ALU_CU: ALUcontrolUnit port map(ALUop => ALUop, Funct => IMoutput(5 downto 0), ALUcontrolUnitOut => ALUcontrolUnitToALU);
	
	S_EXT: SignExtender port map(SignIn => IMoutput(15 downto 0), SignOut => ExtendedSign);
		
	MUX_ALU: MUX32 port map(MUXin1 => RegOut2, MUXin2 => ExtendedSign, MUXout => MUXtoALU, en => ALUSrc);
	
	A_LU: ALU port map(ALUin1 => RegOut1, ALUin2 => MUXtoALU, op => ALUcontrolUnitToALU, ALUout => ALUout, Zero => Zero);
	
	DM: DataMemory port map(clock => clock, DMin => ALUout, WriteData => RegOut2, MemWrite => MemWrite, MemRead => MemRead, DMout => DMout, reset => reset);
	
	MUX_DM: MUX32 port map(MUXin1 => ALUout, MUXin2 => DMout, MUXout => DataWriteIn, en => MemToReg);
	
	BRNCH: ANDgate port map(ANDin1 => Branch, ANDin2 => Zero, ANDout => BranchOut);
	
	MUX_BRNCH: MUX32 port map(MUXin1 => FAplusplusOut, MUXin2 => FA2toMUX, MUXout => MUXtoPC, en => BranchOut);
	
end structural;
