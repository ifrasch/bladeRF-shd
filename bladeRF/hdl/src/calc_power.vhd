--calc_power.vhd
--Calculates the power/squared magnitude of the input signal by computing Re^2 + Im^2
--Performs no truncation on the power output
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity calc_power is
	port(
		clk			: in	std_logic;
		rst			: in	std_logic;
		in_real		: in	signed(11 downto 0);
		in_imag		: in	signed(11 downto 0);
		in_valid	: in	std_logic;
		out_power	: out	unsigned(22 downto 0);
		out_valid	: out	std_logic
	);
end calc_power;

architecture rtl of calc_power is
	
	--Multiplies two 12 bit signed (two's complement numbers) and produces
	--a 23 bit result which uses the full range of its bits.
	--Explanation:
	--A multiplication of two N bit numbers produces a 2N bit result.
	--An unsigned multiplication can require all 2N of those bits in many cases.
	--However, a signed multiplication basically only requires 2N-1 bits except
	--for one rare special case where the two inputs are both the most negative number.
	--This function produces a 2N-1 bit result to the signed multiplication and performs
	--a check for the special case. Essentially, this function removes an uneeded MSB bit
	--at the expense of a single LUT for checking the special case. As a result of
	--removing the uneeded MSB, the output will use the full range of its bits. Without
	--this function, the output would only use half the range of its bits.
	function signed_mult(
		a	:	signed(11 downto 0);
		b	:	signed(11 downto 0)
	) return signed is
		variable product	: signed(23 downto 0);
		variable y			: signed(22 downto 0);
	begin
		product := a*b;
		y := product(22 downto 0);
		--Check for the overflow case: -2048*-2048=-4194304
		if a(11) = '1' and b(11) = '1' and y(22) = '1' then
			y := to_signed(4194303, y'length);	--saturate to +4194303
		end if;
		return y;
	end signed_mult;
begin

	calcpower: process(clk, rst)
		variable re_sq	: unsigned(22 downto 0);
		variable im_sq	: unsigned(22 downto 0);
	begin
		if rst = '1' then
			out_power <= (others => '0');
			out_valid <= '0';
		elsif rising_edge(clk) then
			--compute multiplications, convert signed to unsigned
			re_sq := unsigned(std_logic_vector(signed_mult(in_real, in_real)));
			im_sq := unsigned(std_logic_vector(signed_mult(in_imag, in_imag)));
			--Add (it's guaranteed not to overflow)
			out_power <= re_sq + im_sq;
			out_valid <= in_valid;
		end if;
	end process;
end rtl;