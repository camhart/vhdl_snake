
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity note_generator is
	port(
			clk : in std_logic;
			C4, C4S, D4, D4S, E4, F4, F4S, G4, G4S, A4, A4S,
			B4, C5, C5S, D5, D5S, E5, F5, F5S, G5, G5S, A5, 
			A5S, B5 : out std_logic
		);
end note_generator;

architecture arch of note_generator is

	constant C4_MAX  : natural := 95_554;
	constant C4S_MAX : natural := 90_193;
	constant D4_MAX  : natural := 85_131;
	constant D4S_MAX : natural := 80_351;
	constant E4_MAX  : natural := 75_842;
	constant F4_MAX  : natural := 71_585;
	constant F4S_MAX : natural := 67_568;
	constant G4_MAX  : natural := 63_775;
	constant G4S_MAX : natural := 60_196;
	constant A4_MAX  : natural := 56_817;
	constant A4S_MAX : natural := 53_629;
	constant B4_MAX  : natural := 50_619;
	constant C5_MAX  : natural := 47_777;
	constant C5S_MAX : natural := 45_095;
	constant D5_MAX  : natural := 42_565;
	constant D5S_MAX : natural := 40_176;
	constant E5_MAX  : natural := 37_921;
	constant F5_MAX  : natural := 35_792;
	constant F5S_MAX : natural := 33_783;
	constant G5_MAX  : natural := 31_887;
	constant G5S_MAX : natural := 30_097;
	constant A5_MAX  : natural := 28_408;
	constant A5S_MAX : natural := 26_814;
	constant B5_MAX  : natural := 25_319;
	
	signal c4cnt, c4cntnxt, c4scnt, c4scntnxt, c5cnt, c5cntnxt, c5scnt, c5scntnxt : natural := 0;
	signal d4cnt, d4cntnxt, d4scnt, d4scntnxt, d5cnt, d5cntnxt, d5scnt, d5scntnxt : natural := 0;
	signal e4cnt, e4cntnxt, e5cnt, e5cntnxt : natural := 0;
	signal f4cnt, f4cntnxt, f4scnt, f4scntnxt, f5cnt, f5cntnxt, f5scnt, f5scntnxt : natural := 0;
	signal g4cnt, g4cntnxt, g4scnt, g4scntnxt, g5cnt, g5cntnxt, g5scnt, g5scntnxt : natural := 0;
	signal a4cnt, a4cntnxt, a4scnt, a4scntnxt, a5cnt, a5cntnxt, a5scnt, a5scntnxt : natural := 0;
	signal b4cnt, b4cntnxt, b5cnt, b5cntnxt : natural := 0;
	
	signal c4p, c4pnxt, c4sp, c4spnxt, c5p, c5pnxt, c5sp, c5spnxt : std_logic := '0';
	signal d4p, d4pnxt, d4sp, d4spnxt, d5p, d5pnxt, d5sp, d5spnxt : std_logic := '0';
	signal e4p, e4pnxt,                e5p, e5pnxt                : std_logic := '0';
	signal f4p, f4pnxt, f4sp, f4spnxt, f5p, f5pnxt, f5sp, f5spnxt : std_logic := '0';
	signal g4p, g4pnxt, g4sp, g4spnxt, g5p, g5pnxt, g5sp, g5spnxt : std_logic := '0';
	signal a4p, a4pnxt, a4sp, a4spnxt, a5p, a5pnxt, a5sp, a5spnxt : std_logic := '0';
	signal b4p, b4pnxt,                b5p, b5pnxt                : std_logic := '0';
	
begin                
		--Master Register
		process(clk)
		begin
			if clk'event and clk='1' then
				--Note Counters
				c4cnt  <= c4cntnxt;
				d4cnt  <= d4cntnxt;
				e4cnt  <= e4cntnxt;
				f4cnt  <= f4cntnxt;
				g4cnt  <= g4cntnxt;
				a4cnt  <= a4cntnxt;
				b4cnt  <= b4cntnxt;
				
				c4scnt <= c4scntnxt;
				d4scnt <= d4scntnxt;
				f4scnt <= f4scntnxt;
				g4scnt <= g4scntnxt;
				a4scnt <= a4scntnxt;
				
				c5cnt  <= c5cntnxt;
				d5cnt  <= d5cntnxt;
				e5cnt  <= e5cntnxt;
				f5cnt  <= f5cntnxt;
				g5cnt  <= g5cntnxt;
				a5cnt  <= a5cntnxt;
				b5cnt  <= b5cntnxt;
				
				c5scnt <= c5scntnxt;
				d5scnt <= d5scntnxt;
				f5scnt <= f5scntnxt;
				g5scnt <= g5scntnxt;
				a5scnt <= a5scntnxt;
				
				--Output Pulse
				c4p <= c4pnxt;
				d4p <= d4pnxt;
				e4p <= e4pnxt;
				f4p <= f4pnxt;
				g4p <= g4pnxt;
				a4p <= a4pnxt;
				b4p <= b4pnxt;
				
				c4sp <= c4spnxt;
				d4sp <= d4spnxt;     
				f4sp <= f4spnxt;
				g4sp <= g4spnxt;
				a4sp <= a4spnxt;
	
				c5p <= c5pnxt;
				d5p <= d5pnxt;
				e5p <= e5pnxt;
				f5p <= f5pnxt;
				g5p <= g5pnxt;
				a5p <= a5pnxt;
				b5p <= b5pnxt;
				
				c5sp <= c5spnxt;
				d5sp <= d5spnxt;
				f5sp <= f5spnxt;
				g5sp <= g5spnxt;
				a5sp <= a5spnxt;
				
			end if;
		end process;
		
		--Counter Next State Logic
		c4cntnxt  <= c4cnt+1 when c4cnt < C4_MAX else 0;
		d4cntnxt  <= d4cnt+1 when d4cnt < D4_MAX else 0;
		e4cntnxt  <= e4cnt+1 when e4cnt < E4_MAX else 0;
		f4cntnxt  <= f4cnt+1 when f4cnt < F4_MAX else 0;
		g4cntnxt  <= g4cnt+1 when g4cnt < G4_MAX else 0;
		a4cntnxt  <= a4cnt+1 when a4cnt < A4_MAX else 0;
		b4cntnxt  <= b4cnt+1 when b4cnt < B4_MAX else 0;
		          
		c4scntnxt <= c4scnt+1 when c4scnt < C4S_MAX else 0;
		d4scntnxt <= d4scnt+1 when d4scnt < D4S_MAX else 0;
		f4scntnxt <= f4scnt+1 when f4scnt < F4S_MAX else 0;
		g4scntnxt <= g4scnt+1 when g4scnt < G4S_MAX else 0;
		a4scntnxt <= a4scnt+1 when a4scnt < A4S_MAX else 0;
		          
		c5cntnxt  <= c5cnt+1 when c5cnt < C5_MAX else 0;
		d5cntnxt  <= d5cnt+1 when d5cnt < D5_MAX else 0;
		e5cntnxt  <= e5cnt+1 when e5cnt < E5_MAX else 0;
		f5cntnxt  <= f5cnt+1 when f5cnt < F5_MAX else 0;
		g5cntnxt  <= g5cnt+1 when g5cnt < G5_MAX else 0;
		a5cntnxt  <= a5cnt+1 when a5cnt < A5_MAX else 0;
		b5cntnxt  <= b5cnt+1 when b5cnt < B5_MAX else 0;
		          
		c5scntnxt  <= c5scnt+1 when c5scnt < C5S_MAX else 0;
		d5scntnxt  <= d5scnt+1 when d5scnt < D5S_MAX else 0;
		f5scntnxt  <= f5scnt+1 when f5scnt < F5S_MAX else 0;
		g5scntnxt  <= g5scnt+1 when g5scnt < G5S_MAX else 0;
		a5scntnxt  <= a5scnt+1 when a5scnt < A5S_MAX else 0;
		
		--Pulse Next State Logic
		c4pnxt <= not(c4p) when c4cnt=C4_MAX else c4p;
		d4pnxt <= not(d4p) when d4cnt=D4_MAX else d4p;
		e4pnxt <= not(e4p) when e4cnt=E4_MAX else e4p;
		f4pnxt <= not(f4p) when f4cnt=F4_MAX else f4p;
		g4pnxt <= not(g4p) when g4cnt=G4_MAX else g4p;
		a4pnxt <= not(a4p) when a4cnt=A4_MAX else a4p;
		b4pnxt <= not(b4p) when b4cnt=B4_MAX else b4p;
		
		c4spnxt <= not(c4sp) when c4scnt=C4S_MAX else c4sp;
		d4spnxt <= not(d4sp) when d4scnt=D4S_MAX else d4sp;
		f4spnxt <= not(f4sp) when f4scnt=F4S_MAX else f4sp;
		g4spnxt <= not(g4sp) when g4scnt=G4S_MAX else g4sp;
		a4spnxt <= not(a4sp) when a4scnt=A4S_MAX else a4sp;
		        
		c5pnxt <= not(c5p) when c5cnt=C5_MAX else c5p;
		d5pnxt <= not(d5p) when d5cnt=D5_MAX else d5p;
		e5pnxt <= not(e5p) when e5cnt=E5_MAX else e5p;
		f5pnxt <= not(f5p) when f5cnt=F5_MAX else f5p;
		g5pnxt <= not(g5p) when g5cnt=G5_MAX else g5p;
		a5pnxt <= not(a5p) when a5cnt=A5_MAX else a5p;
		b5pnxt <= not(b5p) when b5cnt=B5_MAX else b5p;
		        
		c5spnxt <= not(c5sp) when c5scnt=C5S_MAX else c5sp;
		d5spnxt <= not(d5sp) when d5scnt=D5S_MAX else d5sp;
		f5spnxt <= not(f5sp) when f5scnt=F5S_MAX else f5sp;
		g5spnxt <= not(g5sp) when g5scnt=G5S_MAX else g5sp;
		a5spnxt <= not(a5sp) when a5scnt=A5S_MAX else a5sp;
		       
		--Output
		C4	<= c4p;
		D4	<=	d4p; 
		E4	<=	e4p; 
		F4	<=	f4p; 
		G4	<=	g4p; 
		A4	<=	a4p; 
		B4	<=	b4p; 
							
		C4S <= c4sp;
		D4S <= d4sp;
		F4S <= f4sp;
		G4S <= g4sp;
		A4S <= a4sp;
							
		C5	<=	c5p; 
		D5	<=	d5p; 
		E5	<=	e5p;
		F5	<=	f5p; 
		G5	<=	g5p; 
		A5	<=	a5p; 
		B5	<=	b5p; 
				
		C5S <= c5sp;
		D5S <= d5sp;
		F5S <= f5sp;
		G5S <= g5sp;
		A5S <= a5sp;
                 
end arch;         
                  