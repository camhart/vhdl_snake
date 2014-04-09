library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity music_maker is
	port(
			clk,reset  	: in std_logic;
			state 		: in std_logic_vector(2 downto 0);
			audio_out	: out std_logic
	);
end music_maker;

architecture arch of music_maker is
	constant rest: std_logic_vector(7 downto 0) := x"00";
	constant C4  : std_logic_vector(7 downto 0) := x"01";
	constant C4S : std_logic_vector(7 downto 0) := x"02";
	constant D4  : std_logic_vector(7 downto 0) := x"03";
	constant D4S : std_logic_vector(7 downto 0) := x"04";
	constant E4  : std_logic_vector(7 downto 0) := x"05";
	constant F4  : std_logic_vector(7 downto 0) := x"06";
	constant F4S : std_logic_vector(7 downto 0) := x"07";
	constant G4  : std_logic_vector(7 downto 0) := x"08";
	constant G4S : std_logic_vector(7 downto 0) := x"09";
	constant A4  : std_logic_vector(7 downto 0) := x"0a";
	constant A4S : std_logic_vector(7 downto 0) := x"0b";
	constant B4  : std_logic_vector(7 downto 0) := x"0c";
	constant C5  : std_logic_vector(7 downto 0) := x"0d";
	constant C5S : std_logic_vector(7 downto 0) := x"0e";
	constant D5  : std_logic_vector(7 downto 0) := x"0f";
	constant D5S : std_logic_vector(7 downto 0) := x"10";
	constant E5  : std_logic_vector(7 downto 0) := x"11";
	constant F5  : std_logic_vector(7 downto 0) := x"12";
	constant F5S : std_logic_vector(7 downto 0) := x"13";
	constant G5  : std_logic_vector(7 downto 0) := x"14";
	constant G5S : std_logic_vector(7 downto 0) := x"15";
	constant A5  : std_logic_vector(7 downto 0) := x"16";
	constant A5S : std_logic_vector(7 downto 0) := x"17";
	constant B5  : std_logic_vector(7 downto 0) := x"18";
	constant MAX : natural := 12_499_999;
	constant PLAY : std_logic_vector(2 downto 0) := "001";
	constant WIN  : std_logic_vector(2 downto 0) := "010";
	constant LOSS : std_logic_vector(2 downto 0) := "100";
	-----
	signal count : natural := 0;
	signal count_next : natural;
	signal note : std_logic_vector(7 downto 0) := rest;
	signal note_next : std_logic_vector(7 downto 0);
	signal c4p,d4p,e4p,f4p,g4p,a4p,b4p,c4sp,d4sp,f4sp,g4sp,a4sp,c5p,d5p, 
	       e5p,f5p,g5p,a5p,b5p,c5sp,d5sp,f5sp,g5sp,a5sp : std_logic;	
	signal ptr_gp, ptr_w, ptr_l : natural := 0;	
	signal ptr_gp_nxt, ptr_w_nxt, ptr_l_nxt : natural;
	-----
	type gp_song is array (0 to 59) of std_logic_vector(7 downto 0);
	signal game_song : gp_song := (
											 F4, A4, B4, B4, F4, A4, B4, B4, F4, A4, B4, E5, D5, D5, B4, C5,
											 B4, G4, E4, E4, E4, E4, D4, E4, G4, E4, E4, E4, E4, rest,
											 F4, A4, B4, B4, F4, A4, B4, B4, F4, A4, B4, E5, D5, D5, B4, C5,
											 E5, B4, G4, G4, G4, G4, B4, G4, D4, E4, E4, E4, E4, rest);
	type w_song is array (0 to 65) of std_logic_vector(7 downto 0);
	signal win_song : w_song := (
											E4, F4, G4, C5, C5, C5, C5, D5, E5, F4, F4, F4, F4, F4, F4, rest, 
											G4, B4, F5, F5, F5, F5, A4, B4, C5, C5, D5, D5, E5, REST, E4, F4, 
											G4, C5, C5, C5, C5, D5, E5, F5, F5, F5, F5, F5, F5, REST, G4, REST, 
											G4, E5, E5, D5, REST, G4, E5, E5, D5, REST, G4, E5, E5, D5, REST, 
											G4, E5, D5);
	type l_song is array (0 to 85) of std_logic_vector(7 downto 0);
	signal loss_song : l_song := (
											 D4, F4, D5, D5, D5, D5, D4, F4, D5, D5, D5, D5, E5, E5, E5, F5, E5, F5, E5, C5, 
											 A4, A4, A4, rest, A4, A4, D4, D4, F4, G4, A4, A4, A4, A4, A4, rest, A4, A4, 
											 D4, F4, G4, E4, E4, E4, E4, E4, E4,
											 D4, F4, D5, D5, D5, D5, D4, F4, D5, D5, E5, E5, E5, F5, E5, F5, E5, C5, 
											 A4, A4, A4, rest, A4, A4, F4, G4, A4, A4, A4, rest, A4, A4, D4, D4, D4, D4,
											 rest, rest, rest);									 
											
begin
	
	process(clk)
	begin
		if reset='1' then
			count <= 0;
			note <= rest;
			ptr_gp <= 0;
			ptr_w <= 0;
			ptr_l <= 0;
		elsif clk'event and clk='1' then
			count <= count_next;
			note <= note_next;
			ptr_gp <= ptr_gp_nxt;
			ptr_w <= ptr_w_nxt;
			ptr_l <= ptr_l_nxt;
		end if;
	end process;
	
	count_next <= count+1 when count < MAX else 0;
	
	ptr_gp_nxt <= ptr_gp+1 when ptr_gp < 59 and count=MAX and state=PLAY else
					  0 when ptr_gp=59 and state=PLAY  and count=MAX else
					  ptr_gp;
					  
	ptr_w_nxt <= ptr_w+1 when ptr_w < 65 and count=MAX and state=WIN else
					  0 when ptr_w=65 and state=WIN and count=MAX else
					  ptr_w;
					  
	ptr_l_nxt <= ptr_l+1 when ptr_l < 85 and count=MAX and state=LOSS else
					 0 when ptr_l=85 and state=LOSS and count=MAX else 
					 ptr_l;
					 
	note_gen : entity work.note_generator
		port map(
					clk => clk,
					C4	=> c4p,
					D4	=>	d4p,
					E4	=>	e4p, 
					F4	=>	f4p, 
					G4	=>	g4p, 
					A4	=>	a4p, 
					B4	=>	b4p, 			
					C4S => c4sp,
					D4S => d4sp,
					F4S => f4sp,
					G4S => g4sp,
					A4S => a4sp,	 
					C5	=>	c5p, 
					D5	=>	d5p, 
					E5	=>	e5p,
					F5	=>	f5p, 
					G5	=>	g5p, 
					A5	=>	a5p, 
					B5	=>	b5p, 
					C5S => c5sp,
					D5S => d5sp,
					F5S => f5sp,
					G5S => g5sp,
					A5S => a5sp	
			);
	
	note_next <= game_song(ptr_gp) when state=PLAY else win_song(ptr_w)
					 when state=WIN else loss_song(ptr_l);
	
	audio_out <= c4p when note=C4 else
	             d4p when note=D4 else
	             e4p when note=E4 else
	             f4p when note=F4 else
	             g4p when note=G4 else
	             a4p when note=A4 else
	             b4p when note=B4 else
	             c4sp when note=C4S else
	             d4sp when note=D4S else
	             f4sp when note=F4S else
	             g4sp when note=G4S else
	             a4sp when note=A4S else
	             c5p when note=C5 else
	             d5p when note=D5 else
	             e5p when note=E5 else
	             f5p when note=F5 else
	             g5p when note=G5 else
	             a5p when note=A5 else
	             b5p when note=B5 else
	             c5sp when note=C5S else
	             d5sp when note=D5S else
	             f5sp when note=F5S else
	             g5sp when note=G5S else
	             a5sp when note=A5S else
					 '0';
	
end arch;
