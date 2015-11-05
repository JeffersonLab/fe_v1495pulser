library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity UserBus32bit is
	port(
		CLK			: in std_logic;
		nLBRES		: in std_logic;
		nBLAST		: in std_logic;
		WnR			: in std_logic;
		nADS		: in std_logic;
		nREADY		: out std_logic;
		nINT		: out std_logic;
		LAD			: inout std_logic_vector(15 downto 0);
		
		USER_DIN	: out std_logic_vector(31 downto 0);
		USER_DOUT	: in std_logic_vector(31 downto 0);
		USER_ADDR	: out std_logic_vector(15 downto 0);
		USER_RD		: out std_logic;
		USER_WR		: out std_logic
	);
end entity;

architecture RTL of UserBus32bit is
	type BUS_STATE_TYPE is (IDLE, WRITE_LWORD, WRITE_HWORD, READ_SETUP, READ_LWORD, READ_HWORD);
	
	signal BUS_STATE 	: BUS_STATE_TYPE;
	signal USER_DOUT_H	: std_logic_vector(15 downto 0);
	signal USER_DOUT_Q	: std_logic_vector(15 downto 0);
	signal LAD_OE		: std_logic_vector(15 downto 0);
begin

	nINT <= '1';
	
	process(USER_DOUT_Q, LAD_OE)
	begin
		for I in LAD'range loop
			if LAD_OE(I) = '1' then
				LAD(I) <= USER_DOUT_Q(I);
			else
				LAD(I) <= 'Z';
			end if;
		end loop;
	end process;
	
	process(CLK, nLBRES)
	begin
		if nLBRES = '0' then
			BUS_STATE <= IDLE;
			USER_DIN <= (others=>'0');
			USER_ADDR <= (others=>'0');
			USER_RD <= '0';
			USER_WR <= '0';
			nREADY <= '0';
			LAD_OE <= (others=>'0');
		elsif rising_edge(CLK) then
			USER_WR <= '0';
			nREADY <= '0';
			USER_RD <= '0';
			LAD_OE <= (others=>'0');
			
			case BUS_STATE is
				when IDLE =>
					if nADS = '0' then
						USER_ADDR <= LAD;
						if WnR = '0' then
							nREADY <= '1';
							USER_RD <= '1';
							BUS_STATE <= READ_SETUP;
						else
							BUS_STATE <= WRITE_LWORD;
						end if;
					end if;
					
				when WRITE_LWORD =>
					if nBLAST = '1' then
						BUS_STATE <= WRITE_HWORD;
						USER_DIN(15 downto 0) <= LAD;
					else
						BUS_STATE <= IDLE;
					end if;
					
				when WRITE_HWORD =>
					USER_DIN(31 downto 16) <= LAD;
					USER_WR <= '1';
					if nBLAST = '1' then
						BUS_STATE <= WRITE_LWORD;
					else
						BUS_STATE <= IDLE;
					end if;
					
				when READ_SETUP =>
					BUS_STATE <= READ_LWORD;
					LAD_OE <= (others=>'1');
					USER_DOUT_Q <= USER_DOUT(15 downto 0);
					USER_DOUT_H <= USER_DOUT(31 downto 16);
				
				when READ_LWORD =>
					if nBLAST = '1' then
						BUS_STATE <= READ_HWORD;
						LAD_OE <= (others=>'1');
						USER_DOUT_Q <= USER_DOUT_H;
					else
						BUS_STATE <= IDLE;
					end if;
				
				when READ_HWORD =>
					if nBLAST = '1' then
						USER_RD <= '1';
						BUS_STATE <= READ_LWORD;
					else
						BUS_STATE <= IDLE;
					end if;
					
				when others =>
					BUS_STATE <= IDLE;
				
			end case;
		end if;
	end process;
	
end RTL;
