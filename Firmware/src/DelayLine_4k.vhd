library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity DelayLine_4k is
	port(
		CLK			: in std_logic;
		DELAY		: in std_logic_vector(11 downto 0);
		INPUT		: in std_logic;
		OUTPUT		: out std_logic
	);
end DelayLine_4k;

architecture Synthesis of DelayLine_4k is
	component Dpram_4k_1b is
		port(
			clock		: in std_logic := '1';
			data		: in std_logic_vector(0 downto 0);
			rdaddress	: in std_logic_vector(11 downto 0);
			wraddress	: in std_logic_vector(11 downto 0);
			wren		: in std_logic  := '0';
			q			: out std_logic_vector(0 downto 0)
		);
	end component;
	
	signal RD_ADDR		: std_logic_vector(11 downto 0);
	signal WR_ADDR		: std_logic_vector(11 downto 0);
begin

	process(CLK)
	begin
		if rising_edge(CLK) then
			RD_ADDR <= RD_ADDR + 1;
			WR_ADDR <= RD_ADDR + 3 + DELAY;
		end if;
	end process;

	Dpram_4k_1b_inst: Dpram_4k_1b
		port map(
			clock		=> CLK,
			data(0)		=> INPUT,
			rdaddress	=> RD_ADDR,
			wraddress	=> WR_ADDR,
			wren		=> '1',
			q(0)		=> OUTPUT
		);

end Synthesis;
