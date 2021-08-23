library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity WakeUp is port(
	cristal: in std_logic;
	der: in std_logic;
	izq: in std_logic;
	up: in std_logic;
	down: in std_logic;
	s: in std_logic;
	sled: out std_logic;
	led: out std_logic_vector(3 downto 0);
	alarma: out std_logic;
	AN: out std_logic_vector (7 downto 0);
	dis: out std_logic_vector (7 downto 0)); 
end WakeUp;

architecture Behavioral of WakeUp is
	type Sreg1_type is (
    S1,S2,S3,S4,izqi3,dere3,izqi2,dere2,izqi1,dere1,opera3,espera3,
	 opera2,espera2,opera1,espera1,opera4,espera4);
	signal Sreg1, NextState_Sreg1: Sreg1_type;
---------------------------------------------------------------
	signal pos: std_logic_vector(1 downto 0);
	signal ANS : std_logic_vector(7 downto 0):= "11111110";
---------------------------------------------------------------
	signal clock: std_logic := '1';	--señal de reloj
	signal reloj: std_logic := '1';	--señales para divisor1
	signal contador: integer := 1;
	signal reloj2: std_logic := '1';	--señales para divisor2
	signal contador2: integer := 1;
	signal clk: std_logic := '1';		--señales para dicisor3
	signal contador3: integer := 1;
-----------------Señales de hora normal------------------------
	signal segs: std_logic_vector(5 downto 0):= "000000";
	signal min0: std_logic_vector(3 downto 0):= "0000";
	signal min1: std_logic_vector(3 downto 0):= "0000";
	signal hor0: std_logic_vector(3 downto 0):= "0000";
	signal hor1: std_logic_vector(3 downto 0):= "0000";
	signal minutos0: std_logic_vector(7 downto 0):= "00000000";
	signal minutos1: std_logic_vector(7 downto 0):= "00000000";
	signal horas0: std_logic_vector(7 downto 0):= "00000000";
	signal horas1: std_logic_vector(7 downto 0):= "00000000";
	signal flag: std_logic_vector(3 downto 0):="1001";
-------------------Señales de hora deseada----------------------
	signal min0d: std_logic_vector(3 downto 0) := "0000";
	signal min1d: std_logic_vector(3 downto 0):= "0101";
	signal hor0d: std_logic_vector(3 downto 0):= "0000";
	signal hor1d: std_logic_vector(3 downto 0):= "0000";
	signal minutos0d: std_logic_vector(7 downto 0):= "00000000";
	signal minutos1d: std_logic_vector(7 downto 0):= "00000000";
	signal horas0d: std_logic_vector(7 downto 0):= "00000000";
	signal horas1d: std_logic_vector(7 downto 0):= "00000000";
	signal nextmin0d: std_logic_vector(3 downto 0):="0000";
	signal nextmin1d: std_logic_vector(3 downto 0):="0000";
	signal nexthor0d: std_logic_vector(3 downto 0):="0000";
	signal nexthor1d: std_logic_vector(3 downto 0):="0000";
begin
----------------Asignación de señales--------------	
	--Señal del cristal se iguala a la señal clock
	clock <= cristal;
	--Señal ANS se iguala a los puertos de los
	--Anodos de la FPGA
	An <= ANS;
	--Puerto Sled se iguala a la salida s que es un 
	--led indicador de encendido o apagado del modo
	--de configuración de hora normal
	sled <= s;
-------------Divisor de frecuenca de 1Hz-----------
	process(clock) begin
	--Valores del contador:
	--1Hz -> 25000000 / 60Hz-> 416667 / 120->208334
		if clock'event and clock = '1' then
			if contador = 25000000 then
				reloj <= not reloj;
				contador <= 0;
			else
				contador <= contador + 1;
			end if;
		end if;
	end process;
-------------Divisor de frecuencia 1kHz (anodos)-----
	process(clock) begin--1kHz -> 25000
		if clock'event and clock = '1' then
			if contador2 = 25000 then
				reloj2 <= not reloj2;
				contador2 <= 1;
			else
				contador2 <= contador2 + 1;
			end if;
		end if;
	end process;
----------Divisor de frecuencia 400Hz (posición)------
	process(clock)begin--400Hz -> 62500 200hz -> 125000
		if clock'event and clock = '1' then
			if contador3 = 62500 then
				clk <= not clk;
			else 
				contador3 <= contador3 + 1;
			end if;
		end if;
	end process;
-----------------------Anodos-------------------------
--Proceso de corrimiento de bits para la activación
--y desactivación de los anodos de los displays
	process(ANS, reloj2) begin
		if (reloj2'event and reloj2 = '1') then
			ANS(0) <= ANS(7);--Corrimiento de
			ANS(1) <= ANS(0);--Anodos de display
			ANS(2) <= ANS(1);
			ANS(3) <= ANS(2);
			ANS(4) <= ANS(3);
			ANS(5) <= ANS(4);
			ANS(6) <= ANS(5);
			ANS(7) <= ANS(6);
		else 
			ANS <= ANS;
		end if;
	end process;
------------------Main process------------------------
--Proceso de reloj, cada 60 segundos se suma una unidad
--a los minutos, cada 60 minutos se suma una unidad a
--las horas. Se tienen restricciones aqui también.
process(reloj,hor1,hor1d,hor0,hor0d,min1,min1d,min0,min0d,s) begin
	if s = '0' then
		if(hor1=hor1d and hor0=hor0d and min1=min1d and min0=min0d) then
			alarma <= '1';
		else
			alarma <= '0';
		end if;
		if (reloj'event and reloj = '1') then--segundos
			if segs = "111100" then
				segs <= "000000";
				if min0 = "1001" then--minutos0
					min0 <= "0000";
					if min1 = "0101" then--minutos1
						min1 <= "0000";
							if hor0 = flag then--horas0
								hor0 <= "0000";--flag es 9 o 3
								if hor1 = "0010" then--horas1
									hor1 <= "0000";
									flag <= "1001";--bandera de hor1
								elsif hor1 = "0001" then
									hor1 <= hor1 + "0001";
									flag <= "0011";--bandera de hor1
								else
									hor1 <= hor1 + "0001";
									flag <= "1001";--bandera de hor1
								end if;
							else
								hor0 <= hor0 + "0001";
							end if;
					else
						min1 <= min1 + "0001";
					end if;
				else 
					min0 <= min0 + "0001";
				end if;
			else 
				segs <= segs + "000001";
			end if;
		end if;
	else
		alarma <= '0';
		hor0 <= hor0d;
		hor1 <= hor1d;
		min0 <= min0d;
		min1 <= min1d;
	end if;
end process;
-------------------Cases de reloj-------------------------
--Asignación de valores a cada uno de los valores en el 
--reloj despertador, horas y minutos, normales o deseados
	process (min0,min1,hor0,hor1,min0d,min1d,hor0d,hor1d) begin
		case min0 is
			when "0000" => minutos0 <= not"11111100";--0
			when "0001" => minutos0 <= not"01100000";--1
			when "0010" => minutos0 <= not"11011010";--2
			when "0011" => minutos0 <= not"11110010";--3
			when "0100" => minutos0 <= not"01100110";--4
			when "0101" => minutos0 <= not"10110110";--5
			when "0110" => minutos0 <= not"10111110";--6
			when "0111" => minutos0 <= not"11100000";--7
			when "1000" => minutos0 <= not"11111110";--8
			when "1001" => minutos0 <= not"11100110";--9
			when others => minutos0 <= "11111111";
		end case;
		case min0d is
			when "0000" => minutos0d <= not"11111100";--0
			when "0001" => minutos0d <= not"01100000";--1
			when "0010" => minutos0d <= not"11011010";--2
			when "0011" => minutos0d <= not"11110010";--3
			when "0100" => minutos0d <= not"01100110";--4
			when "0101" => minutos0d <= not"10110110";--5
			when "0110" => minutos0d <= not"10111110";--6
			when "0111" => minutos0d <= not"11100000";--7
			when "1000" => minutos0d <= not"11111110";--8
			when "1001" => minutos0d <= not"11100110";--9
			when others => minutos0d <= "11111111";
		end case;
		case min1 is
			when "0000" => minutos1 <= not"11111100";--0
			when "0001" => minutos1 <= not"01100000";--1
			when "0010" => minutos1 <= not"11011010";--2
			when "0011" => minutos1 <= not"11110010";--3
			when "0100" => minutos1 <= not"01100110";--4
			when "0101" => minutos1 <= not"10110110";--5
			when others => minutos1 <= "11111111";
		end case;
		case min1d is
			when "0000" => minutos1d <= not"11111100";--0
			when "0001" => minutos1d <= not"01100000";--1
			when "0010" => minutos1d <= not"11011010";--2
			when "0011" => minutos1d <= not"11110010";--3
			when "0100" => minutos1d <= not"01100110";--4
			when "0101" => minutos1d <= not"10110110";--5
			when others => minutos1d <= "11111111";
		end case;
		case hor0 is
			when "0000" => horas0 <= not"11111100";--0
			when "0001" => horas0 <= not"01100000";--1
			when "0010" => horas0 <= not"11011010";--2
			when "0011" => horas0 <= not"11110010";--3
			when "0100" => horas0 <= not"01100110";--4
			when "0101" => horas0 <= not"10110110";--5
			when "0110" => horas0 <= not"10111110";--6
			when "0111" => horas0 <= not"11100000";--7
			when "1000" => horas0 <= not"11111110";--8
			when "1001" => horas0 <= not"11100110";--9
			when others => horas0 <= "11111111";
		end case;
		case hor0d is
			when "0000" => horas0d <= not"11111100";--0
			when "0001" => horas0d <= not"01100000";--1
			when "0010" => horas0d <= not"11011010";--2
			when "0011" => horas0d <= not"11110010";--3
			when "0100" => horas0d <= not"01100110";--4
			when "0101" => horas0d <= not"10110110";--5
			when "0110" => horas0d <= not"10111110";--6
			when "0111" => horas0d <= not"11100000";--7
			when "1000" => horas0d <= not"11111110";--8
			when "1001" => horas0d <= not"11100110";--9
			when others => horas0d <= "11111111";
		end case;
		case hor1 is
			when "0000" => horas1 <= not"11111100";--0
			when "0001" => horas1 <= not"01100000";--1
			when "0010" => horas1 <= not"11011010";--2
			when others => horas1 <= "11111111";
		end case;
		case hor1d is
			when "0000" => horas1d <= not"11111100";--0
			when "0001" => horas1d <= not"01100000";--1
			when "0010" => horas1d <= not"11011010";--2
			when others => horas1d <= "11111111";
		end case;
	end process;
--------------------Posición------------------------
--Proceso de asignación de posición del cursor en leds
	process(pos) begin
		case pos is
			when "00" => led <= "0001";
			when "01" => led <= "0010";
			when "10" => led <= "0100";
			when "11" => led <= "1000";
			when others => led <= "1111";
		end case;
	end process;
---------Process Principal de posición, suma y resta-------------
	Sreg1_NextState: process (der,down,izq,up,Sreg1,pos,hor0d,hor1d,
		nexthor0d,nexthor1d,min0d,min1d,nextmin0d,nextmin1d)begin
-- Set default values for outputs and signals	nextmin0d <= min0d;
		nextmin0d <= min0d;--Intercambio de valores
		nextmin1d <= min1d;--de la maquina de estados
		nexthor0d <= hor0d;
		nexthor1d <= hor1d;
		NextState_Sreg1 <= Sreg1;
		case Sreg1 is
------------------------State 1------------------------
		when S1 =>pos<="11";
			if der='1' then
				NextState_Sreg1 <= dere1;
			elsif izq='1' then
				NextState_Sreg1 <= s1;
			elsif up='1' or down='1' then
				NextState_Sreg1 <= opera1;
			end if;
		when opera1 =>pos<="11";
			case hor1d is
			when "0000" =>
				if up = '1' and down = '0' then
					nexthor1d<=hor1d+"0001";
				elsif up='0' and down='1' then
					nexthor1d<="0010";
				else
					nexthor1d<=hor1d;
				end if;
			when "0001" =>
				if up = '1' and down = '0' then
					nexthor1d<=hor1d+"0001";
				elsif up='0' and down='1' then
					nexthor1d<=hor1d-"0001";
				else
					nexthor1d<=hor1d;
				end if;
			when "0010" =>
				if up = '1' and down = '0' then
					nexthor1d<="0000";
				elsif up='0' and down='1' then
					nexthor1d<=hor1d-"0001";
				else
					nexthor1d<=hor1d;
				end if;
			when others =>nexthor1d<="0000";
			end case;
			NextState_Sreg1 <= espera1;
		when espera1 =>pos<="11";
			if up='0' and down='0' then
				NextState_Sreg1 <= S1;
			end if;
------------------------State 2------------------------		
		when S2 =>pos<="10";
			if der='1' then
				NextState_Sreg1 <= dere2;
			elsif izq='1' then
				NextState_Sreg1 <= izqi3;
			elsif up='1' or down='1' then
				NextState_Sreg1 <= opera2;
			end if;
		when opera2 =>pos<="10";
			if hor0d > "1000" then
				if up = '1' and down = '0' then
					nexthor0d<="0000";
				elsif up='0' and down='1' then
					nexthor0d<=hor0d-"0001";
				else
					nexthor0d<=hor0d;
				end if;
			elsif hor0d = "0000" then
				if up = '1' and down = '0' then
					nexthor0d<=hor0d+"0001";
				elsif up='0' and down='1' then
					nexthor0d<="1001";
				else
					nexthor0d<=hor0d;
				end if;
			else
				if up = '1' and down = '0' then
					nexthor0d<=hor0d+"0001";
				elsif up='0' and down='1' then
					nexthor0d<=hor0d-"0001";
				else
					nexthor0d<=hor0d;
				end if;
			end if;
			NextState_Sreg1 <= espera2;
		when espera2 =>pos<="10";
			if up='0' and down='0' then
				NextState_Sreg1 <= S2;
			end if;
------------------------State 3------------------------
		when S3 =>pos<="01";
			if der='1' then
				NextState_Sreg1 <= dere3;
			elsif izq='1' then
				NextState_Sreg1 <= izqi2;
			elsif up='1' or down='1' then
				NextState_Sreg1 <= opera3;
			end if;
		when opera3 =>pos<="01";
			case min1d is
			when "0000" =>--0
				if up = '1' and down = '0' then
					nextmin1d<=min1d+"0001";
				elsif up='0' and down='1' then
					nextmin1d<="0101";
				else
					nextmin1d<=min1d;
				end if;
			when "0001" =>--1
				if up = '1' and down = '0' then
					nextmin1d<=min1d+"0001";
				elsif up='0' and down='1' then
					nextmin1d<=min1d-"0001";
				else
					nextmin1d<=min1d;
				end if;
			when "0010" =>--2
				if up = '1' and down = '0' then
					nextmin1d<=min1d+"0001";
				elsif up='0' and down='1' then
					nextmin1d<=min1d-"0001";
				else
					nextmin1d<=min1d;
				end if;
			when "0011" =>--3
				if up = '1' and down = '0' then
					nextmin1d<=min1d+"0001";
				elsif up='0' and down='1' then
					nextmin1d<=min1d-"0001";
				else
					nextmin1d<=min1d;
				end if;
			when "0100" =>--4
				if up = '1' and down = '0' then
					nextmin1d<=min1d+"0001";
				elsif up='0' and down='1' then
					nextmin1d<=min1d-"0001";
				else
					nextmin1d<=min1d;
				end if;
			when "0101" =>--5
				if up = '1' and down = '0' then
					nextmin1d<="0000";
				elsif up='0' and down='1' then
					nextmin1d<=min1d-"0001";
				else
					nextmin1d<=min1d;
				end if;
			when others =>nextmin1d<="0000";
			end case;
			NextState_Sreg1 <= espera3;
		when espera3 =>pos<="01";
			if up='0' and down='0' then
				NextState_Sreg1 <= S3;
			end if;
------------------------State 4------------------------
		when S4 =>pos<="00";
			if der='1' then
				NextState_Sreg1 <= S4;
			elsif izq='1' then
				NextState_Sreg1 <= izqi1;
			elsif up='1' or down='1' then
				NextState_Sreg1 <= opera4;
			end if;
		when opera4 =>pos<="00";
			if min0d > "1000" then
				if up = '1' and down = '0' then
					nextmin0d<="0000";
				elsif up='0' and down='1' then
					nextmin0d<=min0d-"0001";
				else
					nextmin0d<=min0d;
				end if;
			elsif min0d = "0000" then
				if up = '1' and down = '0' then
					nextmin0d<=min0d+"0001";
				elsif up='0' and down='1' then
					nextmin0d<="1001";
				else
					nextmin0d<=min0d;
				end if;
			else
				if up = '1' and down = '0' then
					nextmin0d<=min0d+"0001";
				elsif up='0' and down='1' then
					nextmin0d<=min0d-"0001";
				else
					nextmin0d<=min0d;
				end if;
			end if;
			NextState_Sreg1 <= espera4;
		when espera4 =>pos<="00";
			if up='0' and down='0' then
				NextState_Sreg1 <= S4;
			end if;
----------Estados iquierda o derecha------------
		when izqi1 =>pos<="00";
			if izq='0' then
				NextState_Sreg1 <= S3;
			end if;
		when izqi2 =>pos<="01";
			if izq='0' then
				NextState_Sreg1 <= S2;
			end if;
		when izqi3 =>pos<="10";
			if izq='0' then
				NextState_Sreg1 <= S1;
			end if;
		when dere1 =>pos<="11";
			if der='0' then
				NextState_Sreg1 <= S2;
			end if;
		when dere2 =>pos<="10";
			if der='0' then
				NextState_Sreg1 <= S3;
			end if;
		when dere3 =>pos<="01";
			if der='0' then
				NextState_Sreg1 <= S4;
			end if;
		when others =>null;
		end case;
	end process;
------------------------------------
-- Current State Logic (sequential)
------------------------------------
	Sreg0_CurrentState: process (clk)begin
		if clk'event and clk = '1' then
			Sreg1 <= NextState_Sreg1;
		end if;
	end process;
-----Process de intercambio de variables-----
---------Para la maquina de estados----------
	process (clk) begin
		if clk'event and clk='1' then
			min0d <= nextmin0d;
			min1d <= nextmin1d;
			hor0d <= nexthor0d;
			hor1d <= nexthor1d;
		end if;
	end process;
--------------------CASE de ANS-------------------------
--CProceso de activación de nodos con su correspondiente
--valor en el display, con un Case
	process (ANS,minutos0,minutos1,horas0,horas1,
	minutos0d,minutos1d,horas0d,horas1d) begin
		CASE ANS is 
			when "11111110" => dis <= minutos0d;
			when "11111101" => dis <= minutos1d;
			when "11111011" => dis <= horas0d(7 downto 1) & '0';
			when "11110111" => dis <= horas1d;
			when "11101111" => dis <= minutos0;
			when "11011111" => dis <= minutos1;
			when "10111111" => dis <= horas0(7 downto 1) & '0';
			when "01111111" => dis <= horas1; 
			when others => dis <= not "00000000";
		end CASE;
	end process;
end Behavioral;

