--shd.vhd
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;		--only for compile time

entity shd is
	generic(
		NSAMP	: integer	:= 15	--log2(samples to process)
	);
	port(
		clk				: in	std_logic;
		rst				: in	std_logic;
		in_real			: in	signed(11 downto 0);
		in_imag			: in	signed(11 downto 0);
		in_valid		: in	std_logic;
		out_hole		: out	std_logic;
		out_hole_rank	: out	unsigned(6 downto 0);
		out_psd_approx	: out	unsigned(23 downto 0);
		out_valid		: out	std_logic
	);
end shd;

architecture rtl of shd is
	constant NFFT		: integer	:= 128;	--FFT size
	constant LPF_BW		: real		:= 0.7;	--LPF bandwidth [0 to 1]
	constant PSD_W		: integer	:= 39;	--width of PSD sample in bits
	constant OUT_PSD_W	: integer	:= out_psd_approx'length;
	--log2(number of blocks to average)
	constant NAVG		: integer	:= NSAMP - integer(round(log2(real(NFFT))));
	--words per block (number of PSD bins per band)
	constant S			: integer	:= integer(floor(real(NFFT)*LPF_BW/2.0))*2 + 1;
	--hole detection scaling factor
	constant SF_EXACT	: real		:= 1.75;
	constant SF_W		: integer	:= 13;
	constant RANK_W		: integer	:= out_hole_rank'length;
	
	signal fft_out_real		: signed(11 downto 0);
	signal fft_out_imag		: signed(11 downto 0);
	signal fft_out_exp		: signed(5 downto 0);
	signal fft_out_exp_reg	: signed(5 downto 0);
	signal fft_out_valid	: std_logic;
	signal pwr_out_power	: unsigned(22 downto 0);
	signal pwr_out_valid	: std_logic;
	signal sc_out_power		: unsigned(PSD_W-1 downto 0);
	signal sc_out_valid		: std_logic;
	signal psd_out			: unsigned(PSD_W-1 downto 0);
	signal psd_out_min		: unsigned(PSD_W-1 downto 0);
	signal psd_out_valid	: std_logic;
	
begin

	u_fft_wrapper: entity work.fft_wrapper
		generic map(
			NFFT	=> NFFT,
			LPF_BW	=> LPF_BW
		) port map(
			clk			=> clk,
			rst			=> rst,
			in_real		=> in_real,
			in_imag		=> in_imag,
			in_valid	=> in_valid,
			out_real	=> fft_out_real,
			out_imag	=> fft_out_imag,
			out_exp		=> fft_out_exp,
			out_valid	=> fft_out_valid
		);
	u_calc_power: entity work.calc_power
		port map(
			clk			=> clk,
			rst			=> rst,
			in_real		=> fft_out_real,
			in_imag		=> fft_out_imag,
			in_valid	=> fft_out_valid,
			out_power	=> pwr_out_power,
			out_valid	=> pwr_out_valid
		);
	u_scale: entity work.scale
		port map(
			clk			=> clk,
			rst			=> rst,
			in_power	=> pwr_out_power,
			in_exp		=> fft_out_exp_reg,
			in_valid	=> pwr_out_valid,
			out_power	=> sc_out_power,
			out_valid	=> sc_out_valid
		);
	u_averager: entity work.averager
		generic map(
			N	=> NAVG,
			S	=> S,
			W	=> PSD_W
		) port map(
			clk			=> clk,
			rst			=> rst,
			in_word		=> sc_out_power,
			in_valid	=> sc_out_valid,
			out_avg		=> psd_out,
			out_min		=> psd_out_min,
			out_valid	=> psd_out_valid
		);
	u_hole_detector: entity work.hole_detector
		generic map(
			IN_PSD_W		=> PSD_W,
			OUT_PSD_W		=> OUT_PSD_W,
			SF_EXACT		=> SF_EXACT,
			SF_W			=> SF_W,
			SF_FRACT_W		=> SF_W-1,
			RANK_W			=> RANK_W,
			RANK_FRACT_W	=> RANK_W
		) port map(
			clk				=> clk,
			rst				=> rst,
			in_valid		=> psd_out_valid,
			in_psd			=> psd_out,
			in_psd_min		=> psd_out_min,
			out_hole		=> out_hole,
			out_hole_rank	=> out_hole_rank,
			out_psd_approx	=> out_psd_approx,
			out_valid		=> out_valid
		);
		
	fft_out_exp_reg <= fft_out_exp when rising_edge(clk);

end rtl;
