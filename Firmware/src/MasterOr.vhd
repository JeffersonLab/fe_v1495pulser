library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity MasterOr is
	generic(
		BASE_ADDR		: std_logic_vector(15 downto 0);
		DELAY_DEFAULT	: std_logic_vector(11 downto 0)
	);
	port(
		RESET		: in std_logic;
		
		-------------------------
		-- VME Bridge Interface
		-------------------------
		LCLK		: in std_logic;
		ADDR		: in std_logic_vector(15 downto 0);
		DIN			: in std_logic_vector(31 downto 0);
		DOUT		: out std_logic_vector(31 downto 0);
		RD			: in std_logic;
		WR			: in std_logic;
		
		-------------------------
		-- Pulser I/O Signals
		-------------------------
		CLK			: in std_logic;
		INPUT		: in std_logic;
		OUTPUT		: out std_logic
	);
end MasterOr;

architecture Synthesis of MasterOr is
	component DelayLine_4k is
		port(
			CLK			: in std_logic;
			DELAY		: in std_logic_vector(11 downto 0);
			INPUT		: in std_logic;
			OUTPUT		: out std_logic
		);
	end component;

	constant A_DELAY			: std_logic_vector(15 downto 0) := x"0000" + BASE_ADDR;
	constant A_HIGH_CYCLES		: std_logic_vector(15 downto 0) := x"0004" + BASE_ADDR;
	
	constant DFT_DELAY			: std_logic_vector(11 downto 0) := DELAY_DEFAULT;
	constant DFT_HIGH_CYCLES	: std_logic_vector(7 downto 0) := conv_std_logic_vector(10, 8);
	
	signal DELAY				: std_logic_vector(11 downto 0);
	signal HIGH_CYCLES			: std_logic_vector(7 downto 0);
	signal INPUT_Q				: std_logic;
	signal INPUT_R				: std_logic;
	
	signal CNT					: std_logic_vector(7 downto 0);
	signal CNT_DONE				: std_logic;
	
	signal DELAY_IN				: std_logic;
	signal DELAY_OUT			: std_logic;
begin

	-------------------------
	-- VME Bridge Section
	-------------------------
	
	process(LCLK, RESET)
	begin
		if RESET = '1' then
			DELAY <= DFT_DELAY;
			HIGH_CYCLES <= DFT_HIGH_CYCLES;
		elsif rising_edge(LCLK) then
			if WR = '1' then
				case ADDR is
					when A_DELAY		=> DELAY <= DIN(11 downto 0);
					when A_HIGH_CYCLES	=> HIGH_CYCLES <= DIN(7 downto 0);
					when others			=> null;
				end case;
			end if;
		end if;
	end process;

	process(RD, ADDR, DELAY, HIGH_CYCLES)
	begin
		if RD = '1' then
			case ADDR is
				when A_DELAY		=> DOUT <= x"00000" & DELAY;
				when A_HIGH_CYCLES	=> DOUT <= x"000000" & HIGH_CYCLES;
				when others			=> DOUT <= x"00000000";
			end case;
		else
			DOUT <= x"00000000";
		end if;
	end process;

	-------------------------
	-- Master OR Logic Section
	-------------------------
	
	process(CLK)
	begin
		if rising_edge(CLK) then
			INPUT_Q <= INPUT;
			INPUT_R <= INPUT and not INPUT_Q;
		end if;
	end process;
	
	CNT_DONE <= '1' when CNT >= HIGH_CYCLES else '0';
	
	process(CLK)
	begin
		if rising_edge(CLK) then
			if CNT_DONE = '0' then
				CNT <= CNT + 1;
			elsif INPUT_R = '1' then
				CNT <= (others=>'0');
			end if;
		end if;
	end process;

	DELAY_IN <= not CNT_DONE;

	DelayLine_4k_inst: DelayLine_4k
		port map(
			CLK		=> CLK,
			DELAY	=> DELAY,
			INPUT	=> DELAY_IN,
			OUTPUT	=> OUTPUT
		);
	
end Synthesis;
