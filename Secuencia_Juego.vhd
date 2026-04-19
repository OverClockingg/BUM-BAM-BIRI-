library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Secuencia_Juego is
    generic(
        CLK_FREQ : integer := 50_000_000
    );
    port(
        clk, rst     : in  std_logic;
        botones_in   : in  std_logic_vector(3 downto 0); -- Entradas físicas
        secuencia_ok : in  std_logic;                    -- Viene del Top (fin de bienvenida)
        busy_drv     : in  std_logic;                    -- Para saber si el LCD está ocupado
        
        cmd_juego    : out std_logic_vector(3 downto 0); -- Hacia FSM_Mensajes
        jugando_en   : out std_logic                     -- Habilita el contador del juego
    );
end Secuencia_Juego;

architecture Behavioral of Secuencia_Juego is
    type t_state is (ST_IDLE, ST_CHECK, ST_ERROR, ST_NAME, ST_3, ST_2, ST_1, ST_GO, ST_PLAYING);
    signal state : t_state := ST_IDLE;
    
    constant SEC_1 : integer := CLK_FREQ; -- 1 segundo
    signal timer   : integer range 0 to SEC_1 := 0;
    signal r_cmd   : std_logic_vector(3 downto 0) := "1111";

begin
    cmd_juego <= r_cmd;

    process(clk, rst)
    begin
        if rst = '1' then
            state <= ST_IDLE;
            timer <= 0;
            r_cmd <= "1111";
            jugando_en <= '0';
        elsif rising_edge(clk) then
            case state is

                -- Espera a que termine la bienvenida y se presione un botón
                when ST_IDLE =>
                    jugando_en <= '0';
                    r_cmd <= "0011"; -- ID de "SELECCIONE JUEGO"
                    if secuencia_ok = '1' and botones_in /= "0000" and botones_in /= "1111" then
                        state <= ST_CHECK;
                    end if;

                -- Validación de One-Hot (Solo un botón a la vez)
                when ST_CHECK =>
                    case botones_in is
                        when "1000" => r_cmd <= "0100"; state <= ST_NAME; -- TEST
                        when "0100" => r_cmd <= "0101"; state <= ST_NAME; -- DEMO
                        when "0010" => r_cmd <= "0110"; state <= ST_NAME; -- JUEGO 1
                        when "0001" => r_cmd <= "0111"; state <= ST_NAME; -- JUEGO 2
                        when others => state <= ST_ERROR;                 -- Más de uno presionado
                    end case;

                when ST_ERROR =>
                    r_cmd <= "1000"; -- ID de "ERROR: SOLO UN MODO"
                    if botones_in = "0000" then state <= ST_IDLE; end if;

                -- Inicia cuenta regresiva (Solo para Juego 1 y 2 por ahora)
                when ST_NAME =>
                    if timer < SEC_1 then 
                        timer <= timer + 1;
                    else
                        timer <= 0;
                        if r_cmd = "0110" or r_cmd = "0111" then state <= ST_3; 
                        else state <= ST_PLAYING; end if; -- TEST/DEMO no llevan cuenta
                    end if;

                when ST_3 =>
                    r_cmd <= "1001"; -- ID de "3"
                    if timer < SEC_1 then timer <= timer + 1;
                    else timer <= 0; state <= ST_2; end if;

                when ST_2 =>
                    r_cmd <= "1010"; -- ID de "2"
                    if timer < SEC_1 then timer <= timer + 1;
                    else timer <= 0; state <= ST_1; end if;

                when ST_1 =>
                    r_cmd <= "1011"; -- ID de "1"
                    if timer < SEC_1 then timer <= timer + 1;
                    else timer <= 0; state <= ST_GO; end if;

                when ST_GO =>
                    r_cmd <= "1100"; -- ID de "!!!GO!!!"
                    if timer < SEC_1 then timer <= timer + 1;
                    else timer <= 0; state <= ST_PLAYING; end if;

                when ST_PLAYING =>
                    jugando_en <= '1'; -- Habilita tu lógica de contador externo
                    if botones_in = "0000" then state <= ST_IDLE; end if;

                when others => state <= ST_IDLE;
            end case;
        end if;
    end process;
end Behavioral;