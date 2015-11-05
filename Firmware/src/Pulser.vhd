library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Pulser is
	generic(
		BASE_ADDR		: std_logic_vector(15 downto 0)
	);
	port(
		RESET			: in std_logic;
		
		-------------------------
		-- VME Bridge Interface
		-------------------------
		LCLK			: in std_logic;
		ADDR			: in std_logic_vector(15 downto 0);
		DIN			: in std_logic_vector(31 downto 0);
		DOUT			: out std_logic_vector(31 downto 0);
		RD				: in std_logic;
		WR				: in std_logic;
		
		-------------------------
		-- Pulser I/O Signals
		-------------------------
		CLK			: in std_logic;
		START			: in std_logic;
		STOP			: in std_logic;
		STATUS		: out std_logic;
		OUTPUT		: out std_logic
	);
end Pulser;

architecture Synthesis of Pulser is
	constant A_PERIOD				: std_logic_vector(15 downto 0) := x"0000" + BASE_ADDR;
	constant A_HIGH_CYCLES		: std_logic_vector(15 downto 0) := x"0004" + BASE_ADDR;
	constant A_NPULSES			: std_logic_vector(15 downto 0) := x"0008" + BASE_ADDR;
	
	constant DFT_PERIOD			: std_logic_vector(31 downto 0) := conv_std_logic_vector(100, 32);
	constant DFT_HIGH_CYCLES	: std_logic_vector(7 downto 0) := conv_std_logic_vector(10, 8);
	constant DFT_NPULSES			: std_logic_vector(31 downto 0) := x"0000000A";

	signal COUNT					: std_logic_vector(31 downto 0);
	signal COUNT_DONE				: std_logic;
	signal START_Q					: std_logic;
	signal STOP_Q					: std_logic;
	signal PULSER_COUNT			: std_logic_vector(31 downto 0);
	signal PULSER_DONE			: std_logic;
	signal PULSER_OUTPUT			: std_logic;
	signal PERIOD					: std_logic_vector(31 downto 0);
	signal HIGH_CYCLES			: std_logic_vector(7 downto 0);
	signal NPULSES					: std_logic_vector(31 downto 0);
	signal ENABLED					: std_logic;
begin

	-------------------------
	-- VME Bridge Section
	-------------------------
	
	process(LCLK, RESET)
	begin
		if RESET = '1' then
			PERIOD <= DFT_PERIOD;
			HIGH_CYCLES <= DFT_HIGH_CYCLES;
			NPULSES <= DFT_NPULSES;
		elsif rising_edge(LCLK) then
			if WR = '1' then
				case ADDR is
					when A_PERIOD			=> PERIOD <= DIN;
					when A_HIGH_CYCLES	=> HIGH_CYCLES(7 downto 0) <= DIN(7 downto 0);
					when A_NPULSES			=> NPULSES <= DIN;
					when others				=> null;
				end case;
			end if;
		end if;
	end process;

	process(RD, ADDR, PERIOD, HIGH_CYCLES, NPULSES)
	begin
		if RD = '1' then
			case ADDR is
				when A_PERIOD			=> DOUT <= PERIOD;
				when A_HIGH_CYCLES	=> DOUT <= x"000000" & HIGH_CYCLES;
				when A_NPULSES			=> DOUT <= NPULSES;
				when others				=> DOUT <= x"00000000";
			end case;
		else
			DOUT <= x"00000000";
		end if;
	end process;

	-------------------------
	-- Pulser Section
	-------------------------

	process(CLK)
	begin
		if rising_edge(CLK) then
			START_Q <= START;
			STOP_Q <= STOP;
			STATUS <= ENABLED;
		end if;
	end process;
	
	process(RESET, CLK)
	begin
		if RESET = '1' then
			ENABLED <= '1';
		elsif rising_edge(CLK) then
			if START_Q = '1' then
				ENABLED <= '1';
			elsif (STOP_Q = '1') or (PULSER_DONE = '1') then
				ENABLED <= '0';
			end if;
		end if;
	end process;

	PULSER_DONE <= '1' when NPULSES = x"00000000" else
	               '0' when NPULSES = x"FFFFFFFF" else
	               '1' when PULSER_COUNT >= NPULSES else
	               '0';

	process(CLK)
	begin
		if rising_edge(CLK) then
			if START_Q = '1' then
				PULSER_COUNT <= (others=>'0');
			elsif (COUNT_DONE = '1') and (PULSER_DONE = '0') then
				PULSER_COUNT <= PULSER_COUNT + 1;
			end if;
		end if;
	end process;

	COUNT_DONE <= '1' when COUNT >= PERIOD else '0';

	process(CLK)
	begin
		if rising_edge(CLK) then
			if (START_Q = '1') or (COUNT_DONE = '1') then
				COUNT <= (others=>'0');
			else
				COUNT <= COUNT + 1;
			end if;
		end if;
	end process;
	
	process(CLK)
	begin
		if rising_edge(CLK) then
			if (ENABLED = '0') or (COUNT >= (x"000000"&HIGH_CYCLES)) or (PULSER_DONE = '1') then
				OUTPUT <= '0';
			else
				OUTPUT <= '1';
			end if;
		end if;
	end process;

end Synthesis;
