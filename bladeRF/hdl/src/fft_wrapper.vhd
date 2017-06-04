--fft_wrapper.vhd
--Wrapper for altera FFT core which outputs a subset of the FFT bins corresponding to the
--anti-aliasing LPF bandwidth.
--
--Outputs FFT bins in order from DC to most positive, then most negative to least negative
--Outputs a subset of the FFT bins - removes unwanted bins.
--Ex: If samplerate=40MHz and bandwidth=28MHz, the 12MHz of bandwidth around the 28MHz
--LPF is not wanted. Therefore, instead of outputting 128 bins, this will output
--89 bins: corresponding to FFT indices k=0 to k=44 (positive frequencies) and k=84 to
--k=127 (negative frequencies).
--See below: Bins with Xs are discarded and not outputted (by keeping out_valid low)
--
--     XXXXX| Only these  |XXXXX
--           _____________
--     _____/             \_____
--
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;		--only for compile time

entity fft_wrapper is
	generic(
		NFFT	: integer := 128;	--FFT size
		LPF_BW	: real	  := 0.7	--LPF bandwidth as fraction of total bandwidth (0 to 1)
	);
	port(
		clk			: in	std_logic;
		rst			: in	std_logic;
		in_real		: in	signed(11 downto 0);
		in_imag		: in	signed(11 downto 0);
		in_valid	: in	std_logic;
		out_real	: out	signed(11 downto 0);
		out_imag	: out	signed(11 downto 0);
		out_exp		: out	signed(5 downto 0);
		out_valid	: out	std_logic
	);
end fft_wrapper;

architecture rtl of fft_wrapper is
	component fft128
		port(
			clk          : in  std_logic                     := '0';             --    clk.clk
			reset_n      : in  std_logic                     := '0';             --    rst.reset_n
			sink_valid   : in  std_logic                     := '0';             --   sink.sink_valid
			sink_ready   : out std_logic;                                        --       .sink_ready
			sink_error   : in  std_logic_vector(1 downto 0)  := (others => '0'); --       .sink_error
			sink_sop     : in  std_logic                     := '0';             --       .sink_sop
			sink_eop     : in  std_logic                     := '0';             --       .sink_eop
			sink_real    : in  std_logic_vector(11 downto 0) := (others => '0'); --       .sink_real
			sink_imag    : in  std_logic_vector(11 downto 0) := (others => '0'); --       .sink_imag
			inverse      : in  std_logic_vector(0 downto 0)  := (others => '0'); --       .inverse
			source_valid : out std_logic;                                        -- source.source_valid
			source_ready : in  std_logic                     := '0';             --       .source_ready
			source_error : out std_logic_vector(1 downto 0);                     --       .source_error
			source_sop   : out std_logic;                                        --       .source_sop
			source_eop   : out std_logic;                                        --       .source_eop
			source_real  : out std_logic_vector(11 downto 0);                    --       .source_real
			source_imag  : out std_logic_vector(11 downto 0);                    --       .source_imag
			source_exp   : out std_logic_vector(5 downto 0)                      --       .source_exp
		);
	end component;
	
	--inputs to FFT core
	signal rst_n		: std_logic;
	signal sink_sop		: std_logic;
	signal sink_eop		: std_logic;
	--outputs from FFT core
	signal source_valid	: std_logic;
	signal source_real	: std_logic_vector(11 downto 0);
	signal source_imag	: std_logic_vector(11 downto 0);
	signal source_exp	: std_logic_vector(5 downto 0);

	signal in_counter	: unsigned(integer(log2(real(NFFT)))-1 downto 0);
	signal out_counter	: unsigned(integer(log2(real(NFFT)))-1 downto 0);
	--constants
	constant k_clip_start	: integer := integer(floor(real(NFFT)*LPF_BW/2.0)) + 1;
	constant k_clip_end		: integer := NFFT - integer(floor(real(NFFT)*LPF_BW/2.0)) - 1;

begin
	
	u_fft128: fft128 port map(
		clk				=> clk,
		reset_n			=> rst_n,
		sink_valid		=> in_valid,
		sink_ready		=> open,
		sink_error		=> (others => '0'),
		sink_sop		=> sink_sop,
		sink_eop		=> sink_eop,
		sink_real		=> std_logic_vector(in_real),
		sink_imag		=> std_logic_vector(in_imag),
		inverse			=> "0",
		source_valid	=> source_valid,
		source_ready	=> '1',
		source_error	=> open,
		source_sop		=> open,
		source_eop		=> open,
		source_real		=> source_real,
		source_imag		=> source_imag,
		source_exp		=> source_exp
	);
	
	out_real <= signed(source_real);
	out_imag <= signed(source_imag);
	out_exp <= signed(source_exp);
	rst_n <= not rst;

	counter_in: process(clk, rst)
	begin
		if rst = '1' then
			in_counter <= (others => '0');
		elsif rising_edge(clk) then
			if in_valid = '1' then
				in_counter <= in_counter + 1;
			end if;
		end if;
	end process;
	sink_sop <= '1' when (in_counter = 0) and (in_valid = '1')
					else '0';
	sink_eop <= '1' when (in_counter = NFFT-1) and (in_valid = '1')
					else '0';
			
	counter_out: process(clk, rst)
	begin
		if rst = '1' then
			out_counter <= (others => '0');
		elsif rising_edge(clk) then
			if source_valid = '1' then
				out_counter <= out_counter + 1;
			end if;
		end if;
	end process;
	out_valid <= '1' when source_valid = '1' and (out_counter < k_clip_start
											or out_counter > k_clip_end)
					else '0';

end rtl;