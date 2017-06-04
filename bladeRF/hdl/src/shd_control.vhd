--shd_control.vhd
--simple state machine for controlling the spectrum processing chain by gating the
--in_valid signal.
--Waits for a 'start' pulse, sucks in 2^N samples, then stops and waits for the 'start'
--pulse again.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity shd_control is
	generic(
		N	: integer := 15		--2^N = number of samples to receive per frequency
								--default: 15 -> 32768 samples to receive
	);
	port(
		clk			: in	std_logic;
		rst			: in	std_logic;
		start		: in	std_logic;	--pulse high to start processing
		in_valid	: in	std_logic;
		out_valid	: out	std_logic;
		out_state	: out	std_logic	--0=idle,1=busy
	);
end shd_control;

architecture rtl of shd_control is

	type state_t is (IDLE, PROC);
	
	signal state		: state_t := IDLE;
	signal samp_count	: unsigned(N-1 downto 0) := (others => '0');
begin
	fsm: process(clk, rst)
	begin
		if rst = '1' then
			state <= IDLE;
			samp_count <= (others => '0');
		elsif rising_edge(clk) then
			case state is
				when IDLE =>
					if start = '1' then
						state <= PROC;
					end if;
				when PROC =>
					if samp_count = 2**N-1 and in_valid = '1' then
						state <= IDLE;
					end if;
					if in_valid = '1' then
						samp_count <= samp_count + 1;
					end if;
			end case;
		end if;
	end process;

	out_valid <= in_valid when state = PROC else '0';
	out_state <= '1' when state = PROC else '0';
end rtl;
