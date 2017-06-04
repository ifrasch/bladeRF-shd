--hole_detector.vhd
--Uses fixed point math with added fractional bits to yield accurate results.
library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
	use IEEE.math_real.all;

entity hole_detector is
	generic(
		IN_PSD_W		: integer	:= 39;
		OUT_PSD_W		: integer	:= 24;
		SF_EXACT		: real		:= 1.2784;
		SF_W			: integer	:= 13;	--scale factor total width
		SF_FRACT_W		: integer	:= 12;	--width of fractional bits in scale factor
		RANK_W			: integer	:= 7;
		RANK_FRACT_W	: integer	:= 7
	);
	port(
		clk				: in	std_logic;
		rst				: in	std_logic;
		in_valid		: in	std_logic;
		in_psd			: in	unsigned(IN_PSD_W-1 downto 0);
		in_psd_min		: in	unsigned(IN_PSD_W-1 downto 0);
		out_hole		: out	std_logic;
		out_hole_rank	: out	unsigned(RANK_W-1 downto 0);
		out_psd_approx	: out	unsigned(OUT_PSD_W-1 downto 0);
		out_valid		: out	std_logic
	);
end hole_detector;

architecture rtl of hole_detector is

	--fixed point representation of scaling factor
	--Default generics make this a Q1.12 number, meaning its range is
	--[0, 2), and its precision is 1/2^12 = 0.000244
	--For SF_EXACT=1.2784, this fixed point representation is equal to 1.27832
	constant SCALE_FACT	: unsigned(SF_W-1 downto 0)
						:= to_unsigned(integer(round(SF_EXACT * real(2**SF_FRACT_W))), SF_W);
	--Length of pipeline in divider
	constant DIV_PL_LENGTH	: natural	:= 24;
	type psd_reg_array is array(0 to DIV_PL_LENGTH-1) of unsigned(OUT_PSD_W-1 downto 0);
						
	signal thresh		: unsigned(IN_PSD_W-1 downto 0)	:= (others => '0');
	signal psd_reg		: unsigned(IN_PSD_W-1 downto 0)	:= (others => '0');
	signal quotient		: unsigned(IN_PSD_W+RANK_FRACT_W-1 downto 0);
	--pipeline registers (needed because divider takes DIV_PL_LENGTH cycles)
	--Low index = newest data. High index = oldest data
	signal out_psd_regs		: psd_reg_array		:= (others => (others => '0'));
	signal out_hole_regs	: std_logic_vector(DIV_PL_LENGTH-1 downto 0)	:= (others => '0');
	signal out_valid_regs	: std_logic_vector(DIV_PL_LENGTH downto 0)		:= (others => '0');
	
begin

	--instantiate altera pipelined divider which computes hole ranking
	--Mathematically, ranking = [thresh]/[psd value]
	--Add RANK_FRACT_W fractional bits to dividend before dividing
	--After dividing, take the bottom RANK_W bits (will include fractional bits,
	--and possibly some integer bits) to determine out_hole_rank
	u_divider: entity work.divider
		port map(
			aclr 				=> rst,
			clock 				=> clk,
			denom 				=> std_logic_vector(psd_reg),
			numer 				=> std_logic_vector(thresh) & 7b"0",
			unsigned(quotient)	=> quotient,
			remain 				=> open
		);

	hole_detection: process(clk, rst)
		variable product	: unsigned(SF_W+IN_PSD_W-1 downto 0);
	begin
		if rst = '1' then
			thresh <= (others => '0');
			psd_reg <= (others => '0');
			out_psd_regs <= (others => (others => '0'));
			out_hole_regs <= (others => '0');
			out_valid_regs <= (others => '0');
		elsif rising_edge(clk) then
			psd_reg <= in_psd;
			--Compute threshold for next comparison
			--Mathematically, threshold = [min psd value]*[scaling factor]
			--divide product by 2^SF_FRACT_W to remove fractional bits
			--also truncate MSB (since we don't expect it to be needed)
			product := in_psd_min * SCALE_FACT;
			thresh <= product(product'high-1 downto SF_FRACT_W);
			--------Compare PSD value to threshold-----
			if psd_reg < thresh then
				out_hole_regs(0) <= '1';
			else
				out_hole_regs(0) <= '0';
			end if;
			--------Shift pipeline registers-----------
			out_hole_regs(out_hole_regs'high downto 1) <= out_hole_regs(out_hole_regs'high-1 downto 0);
			out_valid_regs(0) <= in_valid;
			out_valid_regs(out_valid_regs'high downto 1) <= out_valid_regs(out_valid_regs'high-1 downto 0);
			out_psd_regs(0) <= psd_reg(31 downto 8);
			for i in 1 to out_psd_regs'high loop
				out_psd_regs(i) <= out_psd_regs(i-1);
			end loop;
		end if;
	end process;
	
	out_hole <= out_hole_regs(out_hole_regs'high);
	out_valid <= out_valid_regs(out_valid_regs'high);
	out_psd_approx <= out_psd_regs(out_psd_regs'high);
	out_hole_rank <= quotient(RANK_FRACT_W-1 downto 0);

end rtl;
