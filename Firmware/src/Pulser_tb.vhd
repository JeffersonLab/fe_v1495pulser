library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Pulser_tb is
end Pulser_tb;

architecture tb of Pulser_tb is
	component Pulser is
		generic(
			BASE_ADDR		: std_logic_vector(15 downto 0)
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
			START		: in std_logic;
			STOP		: in std_logic;
			STATUS		: out std_logic;
			OUTPUT		: out std_logic
		);
	end component;

	constant BASE_ADDR	: std_logic_vector(15 downto 0) := x"0000";

	signal RESET		: std_logic;
	signal LCLK			: std_logic;
	signal ADDR			: std_logic_vector(15 downto 0);
	signal DIN			: std_logic_vector(31 downto 0);
	signal DOUT			: std_logic_vector(31 downto 0);
	signal RD			: std_logic;
	signal WR			: std_logic;
	signal CLK			: std_logic;
	signal START		: std_logic;
	signal STOP			: std_logic;
	signal STATUS		: std_logic;
	signal OUTPUT		: std_logic;
begin

	Pulser_inst: Pulser
		generic map(
			BASE_ADDR	=> BASE_ADDR
		)
		port map(
			RESET		=> RESET,
			LCLK		=> LCLK,
			ADDR		=> ADDR,
			DIN			=> DIN,
			DOUT		=> DOUT,
			RD			=> RD,
			WR			=> WR,
			CLK			=> CLK,
			START		=> START,
			STOP		=> STOP,
			STATUS		=> STATUS,
			OUTPUT		=> OUTPUT
		);

	process
	begin
		LCLK <= '0';
		wait for 12.5 ns;
		LCLK <= '1';
		wait for 12.5 ns;
	end process;
	
	process
	begin
		RESET <= '1';
		ADDR <= x"0000";
		DIN <= x"00000000";
		RD <= '0';
		WR <= '0';
		wait for 100 ns;
		wait until rising_edge(LCLK);
		
		RESET <= '0';
		wait until rising_edge(LCLK);

		wait;
	end process;
	
	process
	begin
		CLK <= '0';
		wait for 5 ns;
		CLK <= '1';
		wait for 5 ns;
	end process;

	process
	begin
		START <= '0';
		STOP <= '0';
		wait for 1 us;
		wait until rising_edge(CLK);
		
		STOP <= '1';
		wait until rising_edge(CLK);
		STOP <= '0';
		
		wait for 1 us;
		START <= '1';
		wait until rising_edge(CLK);
		START <= '0';
		
		wait;
	end process;

end tb;
