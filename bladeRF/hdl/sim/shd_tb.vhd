--Tests the full spectrum hole detector system
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use std.textio.all;

entity shd_tb is
end shd_tb;

architecture behv of shd_tb is
	--inputs to SHD system
	signal clk				: std_logic := '0';
	signal rst				: std_logic := '1';
	signal in_real			: signed(11 downto 0) := (others => '0');
	signal in_imag			: signed(11 downto 0) := (others => '0');
	signal in_valid			: std_logic := '0';
	signal shd_start		: std_logic := '0';
	--outputs and wires between components
	signal ctrl_in_valid	: std_logic;
	signal shd_state		: std_logic;
	signal out_hole			: std_logic;
	signal out_hole_rank	: unsigned(6 downto 0);
	signal out_psd_approx	: unsigned(23 downto 0);
	signal out_valid		: std_logic;
	--tb signals
	signal out_psd_db	: real;
	--constants
	constant clk_period	: time	:= 10 ns;
	constant NSAMP		: integer := 9;	--log2(number of samples to process);
	file fin			: text open READ_MODE is "../testdata/samples_314mhz.csv";
	file fout			: text open WRITE_MODE is "../testdata/shd_tb_dout.txt";
begin
	u_shd: entity work.shd
		generic map(
			NSAMP	=> NSAMP
		) port map(
			clk				=> clk,
			rst				=> rst,
			in_real			=> in_real,
			in_imag			=> in_imag,
			in_valid		=> ctrl_in_valid,
			out_hole		=> out_hole,
			out_hole_rank	=> out_hole_rank,
			out_psd_approx	=> out_psd_approx,
			out_valid		=> out_valid
		);
	u_shd_control: entity work.shd_control
		generic map(
			N		=> NSAMP
		) port map(
			clk			=> clk,
			rst			=> rst,
			start		=> shd_start,
			in_valid	=> in_valid,
			out_valid	=> ctrl_in_valid,
			out_state	=> shd_state
		);

	clk <= not clk after clk_period/2;
	--simulate in_valid signal
	in_valid <= not in_valid when rising_edge(clk);
	out_psd_db <= 10.0*log10(real(to_integer(out_psd_approx))) when out_psd_approx > 0
					else 0.0;

	stim: process
		variable vline		: line;
		variable din_real	: integer;
		variable din_imag	: integer;
		variable char		: character;
	begin
		wait for clk_period*3;
		wait for clk_period/2;
		rst <= '0';
		wait for clk_period*3;
		shd_start <= '1';
		wait for clk_period;
		shd_start <= '0';
		while not endfile(fin) loop
			wait until rising_edge(in_valid);
			readline(fin, vline);
			read(vline, din_real);
			read(vline, char);	--read delimiter
			read(vline, din_imag);
			in_real <= to_signed(din_real, in_real'length);
			in_imag <= to_signed(din_imag, in_imag'length);
		end loop;
		wait;
	end process;
	
	writeoutput: process
		variable vline		: line;
		variable count		: integer := 0;
		constant count_stop	: integer := 89;
	begin
		wait until rising_edge(clk);
		if out_valid = '1' then
			write(vline, out_hole);
			write(vline, ',');
			write(vline, to_integer(out_hole_rank));
			write(vline, ',');
			write(vline, to_integer(out_psd_approx));
			writeline(fout, vline);
			count := count + 1;
			if count = 1 then
				report "Sampled first output data"
					severity note;
			elsif count = count_stop then
				report "Sampled last output data"
					severity note;
				wait for clk_period*20;
				report "Sim finished"
					severity failure;
			end if;
		end if;
	end process;

end behv;
