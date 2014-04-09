library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rx is
	generic(
		CLK_RATE : natural := 50_000_000;
		BAUD_RATE : natural := 19_200
	);
	port(
		clk, rst : in std_logic;
		rx_in : in std_logic;
		data_out : out std_logic_vector(7 downto 0);
		rx_busy, data_strobe : out std_logic
	);
end rx;

architecture arch of rx is
	function log2c(n: integer) return integer is
		variable m, p: integer;
	begin
		m := 0;
		p := 1;
		while p < n loop
			m := m+1;
			p := p*2;
		end loop;
		return m;
	end log2c;	
	constant BIT_COUNTER_MAX_VAL : natural := (CLK_RATE/BAUD_RATE) - 1;
	constant BIT_COUNTER_BITS : natural := log2c(BIT_COUNTER_MAX_VAL);
	signal bit_timer_count, bit_timer_count_next:unsigned(BIT_COUNTER_BITS-1 downto 0);
	signal rx_bit, rx_half_bit, clrTimer, shift, data_strobe_next, data_strobe_temp : std_logic;
	signal shift_out, shift_next : std_logic_vector(7 downto 0);
	type state_type is (power_up, idle, strt, delay, b0, b1, b2, b3, b4, b5, b6, b7, stp, bad);
	signal state, next_state : state_type := power_up;
begin

	process(clk, rst)
	begin
		if(rst='1') then
			bit_timer_count <= (others=>'0');
		elsif(clk'event and clk='1') then
			bit_timer_count <= bit_timer_count_next;
		end if;
	end process;

	bit_timer_count_next <= (others=>'0') when clrTimer='1' or bit_timer_count>BIT_COUNTER_MAX_VAL
								else bit_timer_count+1;

	rx_bit <= '1' when (bit_timer_count=BIT_COUNTER_MAX_VAL) else '0';
	rx_half_bit <= '1' when (bit_timer_count=BIT_COUNTER_MAX_VAL) or (bit_timer_count=BIT_COUNTER_MAX_VAL/2) else '0';
						
	--shift register
	process(clk, rst)
	begin
		if(clk'event and clk='1') then
			if(rst='1' or data_strobe_temp='1') then
				shift_out <= (others=>'0');
			elsif(shift='1') then
				shift_out <= shift_next;
			end if;
		end if;
	end process;
	
	shift_next <= rx_in & shift_out(7 downto 1);
	
	--FSM
	process(clk, rst)
	begin
		if(rst='1') then
			state <= power_up;
		elsif(clk'event and clk='1') then
			state <= next_state;
		end if;
	end process;
	
	next_state <= strt when (state=idle and rx_in='0') or (state=strt and rx_half_bit='0') else
				delay when (state=strt and rx_half_bit='1') or (state=delay and rx_bit='0') else
				b0 when (state=delay and rx_bit='1') or (state=b0 and rx_bit='0') else
				b1 when (state=b0 and rx_bit='1') or (state=b1 and rx_bit='0') else
				b2 when (state=b1 and rx_bit='1') or (state=b2 and rx_bit='0') else
				b3 when (state=b2 and rx_bit='1') or (state=b3 and rx_bit='0') else
				b4 when (state=b3 and rx_bit='1') or (state=b4 and rx_bit='0') else
				b5 when (state=b4 and rx_bit='1') or (state=b5 and rx_bit='0') else
				b6 when (state=b5 and rx_bit='1') or (state=b6 and rx_bit='0') else
				b7 when (state=b6 and rx_bit='1') or (state=b7 and rx_bit='0') else
				stp when (state=b7 and rx_bit='1' and rx_in='1') else
				bad when (state=b7 and rx_bit='1') else
				power_up when (state=power_up and rx_in='0') else
				idle;
				
		process(clk)
		begin
			if(clk'event and clk='1') then
				data_strobe_temp <= data_strobe_next;
			end if;
		end process;
		
		data_strobe <= data_strobe_temp;
		data_strobe_next <= '1' when (state=stp) else '0';
		
		rx_busy <= '0' when state=idle else '1';
		shift <= '1' when (rx_bit='1' and (state=delay or state=b0 or state=b1 or state=b2 or state=b3 or state=b4 or state=b5 or state=b6)) else '0';
		clrTimer <= '1' when state=idle or (state=strt and rx_half_bit='1') else '0';
		data_out <= shift_out;
	
end arch;