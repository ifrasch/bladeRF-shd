--scale.vhd
--Scales input signal up by 2x it's corresponding exponent 'in_exp' which comes from
--the Altera FFT core output.
--Ex: if in_exp = -6, then the scaled up signal will be in_power*2^(2*6) (12 left shifts)
--Multiplies the exponent by 2 because it assumes a power calculation has been
--performed on the unscaled FFT output.
--Uses hardcoded case statement/lookup table for applying the scaling
--ASSUMES THAT THE EXPONENT CAN ONLY RANGE FROM -10 TO -2
--(corresponding to 128pt quad output engine FFT)
--Thus, the width of out_power is intially 43 bits. The 4 least significant bits are
--truncated since they will always be zero (since max exponent is -2)
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity scale is
	port(
		clk			: in	std_logic;
		rst			: in	std_logic;
		in_power	: in	unsigned(22 downto 0);
		in_exp		: in	signed(5 downto 0);
		in_valid	: in	std_logic;
		out_power	: out	unsigned(38 downto 0);
		out_valid	: out	std_logic
	);
end scale;

architecture rtl of scale is
begin

	scale: process(clk, rst)
	begin
		if rst = '1' then
			out_power <= (others => '0');
			out_valid <= '0';
		elsif rising_edge(clk) then
			--For 128-point streaming FFT (quad output engine) the output
			--exponent can range from -10 to -2.
			--If FFT size/type changes, this case statement should be changed with the
			--appropriate exponent range (found on the altera FFT datasheet)
			out_valid <= in_valid;
			case in_exp is
				when to_signed(-10, in_exp'length) =>
					out_power(38 downto 38-22) <= in_power;
					out_power(38-23 downto 0) <= (others => '0');
				when to_signed(-9, in_exp'length) =>
					out_power(38 downto 36+1) <= (others => '0');
					out_power(36 downto 36-22) <= in_power;
					out_power(36-23 downto 0) <= (others => '0');
				when to_signed(-8, in_exp'length) =>
					out_power(38 downto 34+1) <= (others => '0');
					out_power(34 downto 34-22) <= in_power;
					out_power(34-23 downto 0) <= (others => '0');
				when to_signed(-7, in_exp'length) =>
					out_power(38 downto 32+1) <= (others => '0');
					out_power(32 downto 32-22) <= in_power;
					out_power(32-23 downto 0) <= (others => '0');
				when to_signed(-6, in_exp'length) =>
					out_power(38 downto 30+1) <= (others => '0');
					out_power(30 downto 30-22) <= in_power;
					out_power(30-23 downto 0) <= (others => '0');
				when to_signed(-5, in_exp'length) =>
					out_power(38 downto 28+1) <= (others => '0');
					out_power(28 downto 28-22) <= in_power;
					out_power(28-23 downto 0) <= (others => '0');
				when to_signed(-4, in_exp'length) =>
					out_power(38 downto 26+1) <= (others => '0');
					out_power(26 downto 26-22) <= in_power;
					out_power(26-23 downto 0) <= (others => '0');
				when to_signed(-3, in_exp'length) =>
					out_power(38 downto 24+1) <= (others => '0');
					out_power(24 downto 24-22) <= in_power;
					out_power(24-23 downto 0) <= (others => '0');
				when others =>	-- -2 
					out_power(38 downto 22+1) <= (others => '0');
					out_power(22 downto 22-22) <= in_power;
			end case;
		end if;
	end process;
end rtl;