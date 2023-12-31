library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;


entity serial_div is
	port(
			 clk_i 			  	: in std_logic;
			 dvdnd_i			: in std_logic_vector(2*(23+2)-1 downto 0); -- hidden(1) & fraction(23)
			 dvsor_i			: in std_logic_vector(23+3 downto 0);
			 sign_dvd_i 		: in std_logic;
			 sign_div_i 		: in std_logic;
			 start_i			: in std_logic;
			 ready_o			: out std_logic;
			 qutnt_o			: out std_logic_vector(23+3 downto 0);
			 rmndr_o			: out std_logic_vector(23+3 downto 0);
			 sign_o 			: out std_logic;
			 div_zero_o			: out std_logic
		);
end serial_div;

architecture rtl of serial_div is

type t_state is (waiting,busy);

signal s_qutnt_o, s_rmndr_o : std_logic_vector(23+3 downto 0);

signal s_dvdnd_i : std_logic_vector(2*(23+2)-1 downto 0);
signal s_dvsor_i : std_logic_vector(23+3 downto 0);
signal s_sign_dvd_i, s_sign_div_i, s_sign_o : std_logic;
signal s_div_zero_o : std_logic;
signal s_start_i, s_ready_o : std_logic;
signal s_state : t_state;
signal s_count : integer range 0 to 23+3;
signal s_dvd : std_logic_vector(23+3 downto 0);

begin


-- Input Register
process(clk_i)
begin
	if rising_edge(clk_i) then	
		s_dvdnd_i <= dvdnd_i;
		s_dvsor_i <= dvsor_i;
		s_sign_dvd_i<= sign_dvd_i;
		s_sign_div_i<= sign_div_i;
		s_start_i <= start_i;
	end if;
end process;	

-- Output Register
--process(clk_i)
--begin
--	if rising_edge(clk_i) then	
		qutnt_o <= s_qutnt_o;
		rmndr_o <= s_rmndr_o;
		sign_o <= s_sign_o;	
		ready_o <= s_ready_o;
		div_zero_o <= s_div_zero_o;
--	end if;
--end process;

s_sign_o <= sign_dvd_i xor sign_div_i;
s_div_zero_o <= '1' when or_reduce(s_dvsor_i)='0' and or_reduce(s_dvdnd_i)='1' else '0';

-- FSM
process(clk_i)
begin
	if rising_edge(clk_i) then
		if s_start_i ='1' then
			s_state <= busy;
			s_count <= 26; 
		elsif s_count=0 and s_state=busy then
			s_state <= waiting;
			s_ready_o <= '1';
			s_count <=26; 
		elsif s_state=busy then
			s_count <= s_count - 1;
		else
			s_state <= waiting;
			s_ready_o <= '0';
		end if;
	end if;	
end process;


process(clk_i)
variable v_div : std_logic_vector(26 downto 0);
begin
	if rising_edge(clk_i) then
		if s_state=busy then
			if s_count=26 then
				v_div := "000" & s_dvdnd_i(49 downto 26);
			else	
				v_div:= s_dvd;
			end if;
			if v_div < s_dvsor_i then 
				s_qutnt_o(s_count) <= '0';
			else
				s_qutnt_o(s_count) <= '1';
				v_div:=v_div-s_dvsor_i; 
			end if;	
			s_rmndr_o <= v_div;
			s_dvd <= v_div(25 downto 0)&'0';  			
		end if;
	end if;	
end process;

end rtl;

