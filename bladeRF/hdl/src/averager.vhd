--averager.vhd
--Averages 2^N blocks of M data words where each data word is W bits wide
--Outputs averaged words in a shifted order: starting with middle index,
--increasing to highest index, then lowest index to (middle index - 1).
--For FFT data, this shift puts the output data in natural order
--(negative frequencies first, then DC, then positive frequencies).
--Also outputs the minimum averaged value observed
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;	--only for compile time

entity averager is
	generic(
		N	: integer := 8;	--N = log2(number of blocks to average)
		S	: integer := 89; --S = number of words per block (block size)
		W	: integer := 39 --W = width of word in bits
	);
	port(
		clk			: in	std_logic;
		rst			: in	std_logic;
		in_word		: in	unsigned(W-1 downto 0);
		in_valid	: in	std_logic;
		out_avg		: out	unsigned(W-1 downto 0);
		out_min		: out	unsigned(W-1 downto 0);
		out_valid	: out	std_logic
	);
end averager;

architecture rtl of averager is
	--word array: models register/blockRAM memory
	type word_array is array (0 to S-1) of unsigned(W+N-1 downto 0);
	type state_t is (INIT, ACCUM);
	
	constant ADDR_WIDTH		: integer	:= integer(ceil(log2(real(S))));
	--address to use for the first output word which will be sent
	constant FIRST_OUT_ADDR	: unsigned(ADDR_WIDTH-1 downto 0)
							:= to_unsigned((S-1)/2 + 1, ADDR_WIDTH);
	--memory containing all word sums
	signal sum				: word_array := (others => (others => '0'));
	--memory write address
	signal wr_addr			: unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
	--memory read address for getting current word
	signal rd_addr			: unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
	--memory read address for output words
	signal out_addr			: unsigned(ADDR_WIDTH-1 downto 0) := FIRST_OUT_ADDR;
	--counts the number of blocks up to number averages (2^N), then resets to 0
	signal num_blocks_avgd	: unsigned(N-1 downto 0) := (others => '0');

	signal send_output		: std_logic := '0';
	
	signal sout_min			: unsigned(W-1 downto 0) := (others => '1');
	signal find_min			: std_logic	:= '0';
	
	signal word_written		: unsigned(W-1 downto 0) := (others => '0');
	signal word_read		: unsigned(W+N-1 downto 0)	:= (others => '0');
	signal state			: state_t	:= INIT;

begin

	sum_fsm: process(clk, rst)
	begin
		if rst = '1' then
			state <= INIT;
		elsif rising_edge(clk) then
			case state is
				when INIT =>
					if wr_addr = S-1 and in_valid = '1' then
						state <= ACCUM;
					end if;
				when ACCUM =>
					if wr_addr = S-1 and num_blocks_avgd = 2**N-1 and in_valid = '1' then
						state <= INIT;
					end if;
			end case;
		end if;
	end process;
	
	calc_sum: process(clk, rst)
		variable vsum	: unsigned(W+N-1 downto 0);
	begin
		if rst = '1' then
			wr_addr <= (others => '0');
			rd_addr <= (others => '0');
			num_blocks_avgd <= (others => '0');
			word_read <= (others => '0');
			word_written <= (others => '0');
		elsif rising_edge(clk) then
			--wr_addr, num_blocks_avgd, word_read
			if in_valid = '1' then
				word_read <= sum(to_integer(rd_addr));
				if wr_addr = S-1 then
					wr_addr <= (others => '0');
					num_blocks_avgd <= num_blocks_avgd + 1;
				else
					wr_addr <= wr_addr + 1;
				end if;
			end if;
			case state is
				when INIT =>
					--Sum
					if in_valid = '1' then
						sum(to_integer(wr_addr)) <= resize(in_word, W+N);
					end if;
					--rd_addr
					if in_valid = '1' and wr_addr = S-1 then
						rd_addr <= to_unsigned(1, rd_addr'length);
					else
						rd_addr <= (others => '0');
					end if;
				when ACCUM =>
					--sum, word_written
					if in_valid = '1' then
						--Add in_word to word_read, write to memory
						vsum := word_read + resize(in_word, W+N);
						sum(to_integer(wr_addr)) <= vsum;
						--record the word that is being written to memory
						word_written <= vsum(W+N-1 downto N);
					end if;
					--rd_addr
					if in_valid = '1' then
						if rd_addr = S-1 then
							rd_addr <= (others => '0');
						else
							rd_addr <= rd_addr + 1;
						end if;
					end if;
			end case;
		end if;
	end process;
	
	find_min_proc: process(clk, rst)
	begin
		if rst = '1' then
			find_min <= '0';
			sout_min <= (others => '1');
		elsif rising_edge(clk) then
			if num_blocks_avgd = 2**N-1 and in_valid = '1' then
				find_min <= '1';
			else
				find_min <= '0';
			end if;
			if num_blocks_avgd = 1 then
				--reset the minimum
				--not sure when else to do it
				sout_min <= (others => '1');
			elsif find_min = '1' then
				if word_written < sout_min then
					sout_min <= word_written;
				end if;
			end if;
		end if;
	end process;
	
	--Outputs all averaged values serially through out_avg once the averaging has completed
	--Removes bottom N bits to divide by 2^N - computing the average
	output_control: process(clk, rst)
		--Avg values adjacent to FIRST_OUT_ADDR
		variable vavg1	: unsigned(W-1 downto 0);
		variable vavg2	: unsigned(W-1 downto 0);
		variable vsum	: unsigned(W downto 0);
	begin
		if rst = '1' then
			out_avg <= (others => '0');
			out_addr <= FIRST_OUT_ADDR;
			send_output <= '0';
			out_valid <= '0';
		elsif rising_edge(clk) then
			out_valid <= send_output;	--out_valid is a delayed version of send_output
			--control send_output
			case send_output is
				when '0' =>
					if in_valid = '1' and num_blocks_avgd = 2**N-1 and
							wr_addr = S-1 then
						send_output <= '1';
					end if;
				when others => --'1'
					if out_addr = FIRST_OUT_ADDR-1 then
						send_output <= '0';
					end if;
			end case;
			--control out_avg and out_addr
			if send_output = '1' then
				if out_addr = 0 then
					--DC bin. Ignore its value - instead, estimate it with the mean of
					--the adjacent bins
					vavg1 := sum(1)(W+N-1 downto N);
					vavg2 := sum(S-1)(W+N-1 downto N);
					vsum := resize(vavg1, vsum'length) + resize(vavg2, vsum'length);
					out_avg <= vsum(vsum'high downto 1);
				else
					out_avg <= sum(to_integer(out_addr))(W+N-1 downto N);
				end if;
				if out_addr = S-1 then
					out_addr <= (others => '0');
				else
					out_addr <= out_addr + 1;
				end if;
			end if;
		end if;
	end process;
	
	out_min <= sout_min;
	
end rtl;