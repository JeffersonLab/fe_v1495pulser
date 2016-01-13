library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

entity V1495Pulser IS
	port(
		-- Front Panel Ports
		A        : IN     std_logic_vector (31 DOWNTO 0);  -- In A (32 x LVDS/ECL)
		B        : IN     std_logic_vector (31 DOWNTO 0);  -- In B (32 x LVDS/ECL)
		C        : OUT    std_logic_vector (31 DOWNTO 0);  -- Out C (32 x LVDS)
		D        : INOUT  std_logic_vector (31 DOWNTO 0);  -- In/Out D (I/O Expansion)
		E        : INOUT  std_logic_vector (31 DOWNTO 0);  -- In/Out E (I/O Expansion)
		F        : INOUT  std_logic_vector (31 DOWNTO 0);  -- In/Out F (I/O Expansion)
		GIN      : IN     std_logic_vector (1 DOWNTO 0);   -- In G - LEMO (2 x NIM/TTL)
		GOUT     : OUT    std_logic_vector (1 DOWNTO 0);   -- Out G - LEMO (2 x NIM/TTL)
		-- Port Output Enable (0=Output, 1=Input)
		nOED     : OUT    std_logic;                       -- Output Enable Port D (only for A395D)
		nOEE     : OUT    std_logic;                       -- Output Enable Port E (only for A395D)
		nOEF     : OUT    std_logic;                       -- Output Enable Port F (only for A395D)
		nOEG     : OUT    std_logic;                       -- Output Enable Port G
		-- Port Level Select (0=NIM, 1=TTL)
		SELD     : OUT    std_logic;                       -- Output Level Select Port D (only for A395D)
		SELE     : OUT    std_logic;                       -- Output Level Select Port E (only for A395D)
		SELF     : OUT    std_logic;                       -- Output Level Select Port F (only for A395D)
		SELG     : OUT    std_logic;                       -- Output Level Select Port G

		-- Expansion Mezzanine Identifier:
		-- 000 : A395A (32 x IN LVDS/ECL)
		-- 001 : A395B (32 x OUT LVDS)
		-- 010 : A395C (32 x OUT ECL)
		-- 011 : A395D (8  x IN/OUT NIM/TTL)
		IDD      : IN     std_logic_vector (2 DOWNTO 0);   -- Slot D
		IDE      : IN     std_logic_vector (2 DOWNTO 0);   -- Slot E
		IDF      : IN     std_logic_vector (2 DOWNTO 0);   -- Slot F

		-- LED drivers
		nLEDG		: OUT    std_logic;                       -- Green (active low)
		nLEDR		: OUT    std_logic;                       -- Red (active low)

		-- Spare
		SPARE		: INOUT  std_logic_vector (11 DOWNTO 0);

		-- Local Bus in/out signals
		nLBRES	: IN     std_logic;
		nBLAST	: IN     std_logic;
		WnR		: IN     std_logic;
		nADS		: IN     std_logic;
		LCLK		: IN     std_logic;
		nREADY	: OUT    std_logic;
		nINT		: OUT    std_logic;
		LAD		: INOUT  std_logic_vector (15 DOWNTO 0)
	);
end V1495Pulser;


architecture Synthesis of V1495Pulser is
	component UserBus32bit is
		port(
			CLK			: in std_logic;
			nLBRES		: in std_logic;
			nBLAST		: in std_logic;
			WnR			: in std_logic;
			nADS			: in std_logic;
			nREADY		: out std_logic;
			nINT			: out std_logic;
			LAD			: inout std_logic_vector(15 downto 0);
			
			USER_DIN		: out std_logic_vector(31 downto 0);
			USER_DOUT	: in std_logic_vector(31 downto 0);
			USER_ADDR	: out std_logic_vector(15 downto 0);
			USER_RD		: out std_logic;
			USER_WR		: out std_logic
		);
	end component;

	component Pulser is
		generic(
			BASE_ADDR	: std_logic_vector(15 downto 0)
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
	end component;

	component MasterOr is
		generic(
			BASE_ADDR		: std_logic_vector(15 downto 0);
			DELAY_DEFAULT	: std_logic_vector(11 downto 0)
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
			INPUT			: in std_logic;
			OUTPUT		: out std_logic
		);
	end component;

	component PLLBlock
		port(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0				: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC 
		);
	end component;
	
	constant PULSER_NUM					: integer := 56;
	
	type slv32_array is array(natural range <>) of std_logic_vector(31 downto 0);
	type pulser_array is array(natural range <>) of std_logic_vector(PULSER_NUM-1 downto 0);
	type int_array is array(natural range <>) of integer;
	
	constant NIM_IO_MAP					: int_array(0 to 7) := (0, 16, 1, 17, 12, 28, 13, 29);
	
	constant A_PULSER_ID					: std_logic_vector(15 downto 0) := x"1000";
	constant A_FIRMWARE_REV				: std_logic_vector(15 downto 0) := x"1004";
	constant A_BOARDID					: std_logic_vector(15 downto 0) := x"1008";
	constant A_JUMPERS					: std_logic_vector(15 downto 0) := x"100C";
	constant A_PULSER_STATUS_H			: std_logic_vector(15 downto 0) := x"1010";
	constant A_PULSER_STATUS_L			: std_logic_vector(15 downto 0) := x"1014";
	constant A_PULSER_START_MASK_H	: std_logic_vector(15 downto 0) := x"1018";
	constant A_PULSER_START_MASK_L	: std_logic_vector(15 downto 0) := x"101C";
	constant A_PULSER_STOP_MASK_H		: std_logic_vector(15 downto 0) := x"1020";
	constant A_PULSER_STOP_MASK_L		: std_logic_vector(15 downto 0) := x"1024";
	constant A_PULSER_GIN_MASK_H		: std_logic_vector(15 downto 0) := x"1028";
	constant A_PULSER_GIN_MASK_L		: std_logic_vector(15 downto 0) := x"102C";
	constant A_PULSER_START_STOP		: std_logic_vector(15 downto 0) := x"1030";
	constant A_NIMTTL						: std_logic_vector(15 downto 0) := x"1034";


	signal USER_DOUT_MUX					: slv32_array(58 downto 0);

	signal JUMPER							: std_logic_vector(5 downto 0);

	signal PULSER_START					: std_logic_vector(PULSER_NUM-1 downto 0);
	signal PULSER_STOP					: std_logic_vector(PULSER_NUM-1 downto 0);
	signal PULSER_STATUS					: std_logic_vector(PULSER_NUM-1 downto 0);
	signal PULSER_OUTPUT					: std_logic_vector(PULSER_NUM-1 downto 0);
	signal PULSER_OUTPUT_Q				: pulser_array(8 downto 0);
	signal PULSER_START_MASK			: std_logic_vector(PULSER_NUM-1 downto 0);
	signal PULSER_STOP_MASK				: std_logic_vector(PULSER_NUM-1 downto 0);
	signal PULSER_GIN_MASK				: std_logic_vector(PULSER_NUM-1 downto 0);
	signal PULSER_START_LCLK			: std_logic;
	signal PULSER_STOP_LCLK				: std_logic;
	signal PULSER_OR						: std_logic_vector(3 downto 0);
	signal PULSER_MOR_MASK				: std_logic_vector(PULSER_NUM-1 downto 0);

	signal PULSER_START_PLLCLK			: std_logic_vector(3 downto 0);
	signal PULSER_STOP_PLLCLK			: std_logic_vector(3 downto 0);
	signal PULSER_START_R				: std_logic;
	signal PULSER_STOP_R					: std_logic;

	signal SYS_RESET						: std_logic;
	signal PLL_LOCK						: std_logic;
	signal PLLCLK							: std_logic;
	signal HEART_BEAT_CNT				: std_logic_vector(25 downto 0) := (others=>'0');

	signal USER_DIN						: std_logic_vector(31 downto 0);
	signal USER_DOUT						: std_logic_vector(31 downto 0);
	signal USER_ADDR						: std_logic_vector(15 downto 0);
	signal USER_RD							: std_logic;
	signal USER_WR							: std_logic;
	signal USER_WR_BRIDGE				: std_logic;
	
	signal MOR_IN							: std_logic;
	signal MOR_OUT							: std_logic;
	signal MOR_OUT_F						: std_logic;
	
	signal GIN_OR							: std_logic;

	signal NIMTTL_SEL						: std_logic_vector(2 downto 0);
begin

	-------------------------
	-- 200MHz PLL
	-------------------------	
	PLLBlock_inst: PLLBlock
		port map(
			areset	=> SYS_RESET,
			inclk0	=> LCLK,
			c0			=> PLLCLK,
			locked	=> PLL_LOCK
		);

	-------------------------
	-- V1495 VME<->User Bridge
	-------------------------	
	UserBus32bit_inst: UserBus32bit
		port map(
			CLK			=> LCLK,
			nLBRES		=> nLBRES,
			nBLAST		=> nBLAST,
			WnR			=> WnR,
			nADS			=> nADS,
			nREADY		=> nREADY,
			nINT			=> nINT,
			LAD			=> LAD,
			USER_DIN		=> USER_DIN,
			USER_DOUT	=> USER_DOUT,
			USER_ADDR	=> USER_ADDR,
			USER_RD		=> USER_RD,
			USER_WR		=> USER_WR_BRIDGE
		);
		
	USER_WR <= USER_WR_BRIDGE and not JUMPER(0);

	-------------------------
	-- Pulsers Section
	-------------------------	
	Pulser_Gen: for I in 0 to PULSER_NUM-1 generate
		Pulser_inst: Pulser
			generic map(
				BASE_ADDR	=> x"2000" + conv_std_logic_vector(I * 16, 16)
			)
			port map(
				RESET			=> SYS_RESET,
				LCLK			=> LCLK,
				ADDR			=> USER_ADDR,
				DIN			=> USER_DIN,
				DOUT			=> USER_DOUT_MUX(I+3),
				RD				=> USER_RD,
				WR				=> USER_WR,
				CLK			=> PLLCLK,
				START			=> PULSER_START(I),
				STOP			=> PULSER_STOP(I),
				STATUS		=> PULSER_STATUS(I),
				OUTPUT		=> PULSER_OUTPUT(I)
			);
	end generate;

	-------------------------
	-- Master OR Section
	-------------------------
	MasterOr_inst: MasterOr
		generic map(
			BASE_ADDR		=> x"1100",
			DELAY_DEFAULT	=> x"000"
		)
		port map(
			RESET		=> SYS_RESET,
			LCLK		=> LCLK,
			ADDR		=> USER_ADDR,
			DIN		=> USER_DIN,
			DOUT		=> USER_DOUT_MUX(1),
			RD			=> USER_RD,
			WR			=> USER_WR,
			CLK		=> PLLCLK,
			INPUT		=> MOR_IN,
			OUTPUT	=> MOR_OUT
		);

	MasterOr_inst1: MasterOr
		generic map(
			BASE_ADDR		=> x"1200",
			DELAY_DEFAULT	=> x"0C8"
		)
		port map(
			RESET		=> SYS_RESET,
			LCLK		=> LCLK,
			ADDR		=> USER_ADDR,
			DIN		=> USER_DIN,
			DOUT		=> USER_DOUT_MUX(2),
			RD			=> USER_RD,
			WR			=> USER_WR,
			CLK		=> PLLCLK,
			INPUT		=> MOR_IN,
			OUTPUT	=> MOR_OUT_F
		);
	
	-------------------------
	-- I/O Mapping Section
	-------------------------
	
	GOUT(0) <= '0';	-- Output NIM Logic '0' (no current) to allow use of GIN(0)
	GIN_OR <= not GIN(0);
	
	nOED <= '0';	-- Output
	nOEE <= '0';	-- Output
	nOEF <= '0';	-- Output
	nOEG <= '0';	-- Output

	SELD <= NIMTTL_SEL(0);	--'1'=TTL Output, '0'=NIM Output
	SELE <= NIMTTL_SEL(1);	--'1'=TTL Output, '0'=NIM Output
	SELF <= NIMTTL_SEL(2);	--'1'=TTL Output, '0'=NIM Output
	SELG <= '0';	-- NIM Output
	
	process(PLLCLK)
	begin
		if rising_edge(PLLCLK) then			
			-- Master OR
			PULSER_OR(0) <= or_reduce(PULSER_OUTPUT(13 downto 0));
			PULSER_OR(1) <= or_reduce(PULSER_OUTPUT(27 downto 14));
			PULSER_OR(2) <= or_reduce(PULSER_OUTPUT(41 downto 28));
			PULSER_OR(3) <= or_reduce(PULSER_OUTPUT(55 downto 42));
			MOR_IN <= or_reduce(PULSER_OR); 
			C(31) <= MOR_OUT;
			
			-- Pulser Outputs
			PULSER_OUTPUT_Q <= PULSER_OUTPUT_Q(PULSER_OUTPUT_Q'length-2 downto 0) & PULSER_OUTPUT;
		end if;
	end process;

	process(PULSER_OUTPUT, PULSER_OUTPUT_Q, GIN_OR, PULSER_GIN_MASK)
	begin
		GOUT(1) <= (PULSER_OUTPUT_Q(PULSER_OUTPUT_Q'length-3)(55) or (GIN_OR and PULSER_GIN_MASK(55)));
		
		for I in 0 to 30 loop
			C(I) <= PULSER_OUTPUT_Q(PULSER_OUTPUT_Q'length-1)(I) or (GIN_OR and PULSER_GIN_MASK(I));
		end loop;
		
		for I in 0 to 7 loop
			D(NIM_IO_MAP(I)) <= (PULSER_OUTPUT_Q(PULSER_OUTPUT_Q'length-1)(31+ 0+I) or (GIN_OR and PULSER_GIN_MASK(31+ 0+I)));
			E(NIM_IO_MAP(I)) <= (PULSER_OUTPUT_Q(PULSER_OUTPUT_Q'length-1)(31+ 8+I) or (GIN_OR and PULSER_GIN_MASK(31+ 8+I)));
		end loop;

		for I in 0 to 6 loop
			F(NIM_IO_MAP(I)) <= (PULSER_OUTPUT_Q(PULSER_OUTPUT_Q'length-1)(31+16+I) or (GIN_OR and PULSER_GIN_MASK(31+16+I)));
		end loop;
	end process;

	process(PLLCLK)
	begin
		if rising_edge(PLLCLK) then			
			F(NIM_IO_MAP(7)) <= MOR_OUT_F;
		end if;
	end process;

	-------------------------
	-- Pulser Mask Section
	-------------------------	
	process(PLLCLK)
	begin
		if rising_edge(PLLCLK) then
			PULSER_START_PLLCLK <= PULSER_START_PLLCLK(PULSER_START_PLLCLK'length-2 downto 0) & PULSER_START_LCLK;
			PULSER_STOP_PLLCLK <= PULSER_STOP_PLLCLK(PULSER_STOP_PLLCLK'length-2 downto 0) & PULSER_STOP_LCLK;
			PULSER_START_R <= PULSER_START_PLLCLK(PULSER_START_PLLCLK'length-2) and not PULSER_START_PLLCLK(PULSER_START_PLLCLK'length-1);
			PULSER_STOP_R <= PULSER_STOP_PLLCLK(PULSER_STOP_PLLCLK'length-2) and not PULSER_STOP_PLLCLK(PULSER_STOP_PLLCLK'length-1);
			
			for I in 0 to PULSER_NUM-1 loop
				PULSER_START(I) <= PULSER_START_R and PULSER_START_MASK(I);
				PULSER_STOP(I) <= PULSER_STOP_R and PULSER_STOP_MASK(I);
			end loop;
			
		end if;
	end process;

	-------------------------
	-- Registers Section
	-------------------------	
	process(USER_DOUT_MUX)
		variable bus_or		: std_logic_vector(31 downto 0);
	begin
		bus_or := x"00000000";
		
		for I in USER_DOUT_MUX'range loop
			bus_or := bus_or or USER_DOUT_MUX(I);
		end loop;
		
		USER_DOUT <= bus_or;
	end process;
	
	process(SYS_RESET, LCLK)
	begin
		if SYS_RESET = '1' then
			PULSER_START_LCLK <= '0';
			PULSER_STOP_LCLK <= '0';
			PULSER_START_MASK <= (others=>'1');
			PULSER_STOP_MASK <= (others=>'1');
			PULSER_GIN_MASK <= (others=>'0');
			NIMTTL_SEL <= "011";
		elsif rising_edge(LCLK) then
			PULSER_START_LCLK <= '0';
			PULSER_STOP_LCLK <= '0';
			
			if (USER_WR = '1') then
				case USER_ADDR is
					when A_PULSER_START_MASK_H	=> PULSER_START_MASK(55 downto 32) <= USER_DIN(23 downto 0);
					when A_PULSER_START_MASK_L	=> PULSER_START_MASK(31 downto 0) <= USER_DIN;					
					when A_PULSER_STOP_MASK_H	=> PULSER_STOP_MASK(55 downto 32) <= USER_DIN(23 downto 0);
					when A_PULSER_STOP_MASK_L	=> PULSER_STOP_MASK(31 downto 0) <= USER_DIN;
					when A_PULSER_GIN_MASK_H	=> PULSER_GIN_MASK(55 downto 32) <= USER_DIN(23 downto 0);
					when A_PULSER_GIN_MASK_L	=> PULSER_GIN_MASK(31 downto 0) <= USER_DIN;
					when A_PULSER_START_STOP	=> PULSER_START_LCLK <= USER_DIN(0);
					                              PULSER_STOP_LCLK <= not USER_DIN(0);
					when A_NIMTTL					=> NIMTTL_SEL <= USER_DIN(2 downto 0);
					when others 					=> null;
				end case;
			end if;
		end if;
	end process;
	
	process(USER_RD, USER_ADDR, IDF, IDE, IDD, JUMPER, PULSER_STATUS, PULSER_START_MASK, PULSER_STOP_MASK, PULSER_GIN_MASK)
	begin
		if USER_RD = '1' then
			case USER_ADDR is
				when A_PULSER_ID				=> USER_DOUT_MUX(0) <= x"50554C53";
				when A_FIRMWARE_REV			=> USER_DOUT_MUX(0) <= x"00010005";
				when A_BOARDID					=> USER_DOUT_MUX(0) <= x"00000" & "0"&IDF & "0"&IDE & "0"&IDD;
				when A_JUMPERS					=> USER_DOUT_MUX(0) <= x"000000" & "00" & JUMPER;
				when A_PULSER_STATUS_H		=> USER_DOUT_MUX(0) <= "00000000" & PULSER_STATUS(55 downto 32);
				when A_PULSER_STATUS_L		=> USER_DOUT_MUX(0) <= PULSER_STATUS(31 downto 0);
				when A_PULSER_START_MASK_H	=> USER_DOUT_MUX(0) <= "00000000" & PULSER_START_MASK(55 downto 32);
				when A_PULSER_START_MASK_L	=> USER_DOUT_MUX(0) <= PULSER_START_MASK(31 downto 0);
				when A_PULSER_STOP_MASK_H	=> USER_DOUT_MUX(0) <= "00000000" & PULSER_STOP_MASK(55 downto 32);
				when A_PULSER_STOP_MASK_L	=> USER_DOUT_MUX(0) <= PULSER_STOP_MASK(31 downto 0);
				when A_PULSER_GIN_MASK_H	=> USER_DOUT_MUX(0) <= "00000000" & PULSER_GIN_MASK(55 downto 32);
				when A_PULSER_GIN_MASK_L	=> USER_DOUT_MUX(0) <= PULSER_GIN_MASK(31 downto 0);
				when A_NIMTTL					=> USER_DOUT_MUX(0) <= x"0000000" & '0' & NIMTTL_SEL(2 downto 0);
				when others 					=> USER_DOUT_MUX(0) <= x"00000000";
			end case;
		else
			USER_DOUT_MUX(0) <= x"00000000";
		end if;
	end process;

	-------------------------
	-- Status/reset
	-------------------------	
	nLEDG <= not HEART_BEAT_CNT(25);
	nLEDR <= PLL_LOCK;
	SYS_RESET <= not nLBRES;

	process(LCLK)
	begin
		if rising_edge(LCLK) then
			HEART_BEAT_CNT <= HEART_BEAT_CNT + 1;
		end if;
	end process;
	
	JUMPER(0) <= not SPARE(1);
	SPARE(0) <= '0';
	SPARE(1) <= 'Z';

	JUMPER(1) <= not SPARE(3);
	SPARE(2) <= '0';
	SPARE(3) <= 'Z';

	JUMPER(2) <= not SPARE(5);
	SPARE(4) <= '0';
	SPARE(5) <= 'Z';

	JUMPER(3) <= not SPARE(7);
	SPARE(6) <= '0';
	SPARE(7) <= 'Z';

	JUMPER(4) <= not SPARE(9);
	SPARE(8) <= '0';
	SPARE(9) <= 'Z';

	JUMPER(5) <= not SPARE(11);
	SPARE(10) <= '0';
	SPARE(11) <= 'Z';
		
end Synthesis;
   