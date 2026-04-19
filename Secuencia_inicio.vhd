library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Secuencia_inicio is
    generic(
        CLK_FREQ : integer := 50_000_000
    );
    port(
        clk, rst : in std_logic;
        ready_init : in std_logic; -- Viene del init_done del LCD
        busy_drv   : in std_logic; -- Viene del busy del driver
        
        -- Salida hacia la FSM_Mensajes
        cmd_out    : out std_logic_vector(3 downto 0)
    );
end Secuencia_inicio;

architecture Behavioral of Secuencia_inicio is
    type t_state is (ST_POWER_ON, ST_BIENVENIDOS, ST_WAIT1, ST_DIVIERTANSE, ST_WAIT2, ST_MODO_JUEGO);
    signal state : t_state := ST_POWER_ON;
    
    -- Contador para 3 segundos: 50MHz * 3 = 150,000,000
    constant SEC_3 : integer := CLK_FREQ * 3;
    signal timer : integer range 0 to SEC_3 := 0;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            state <= ST_POWER_ON;
            timer <= 0;
            cmd_out <= "1111"; -- ID Nulo
        elsif rising_edge(clk) then
            case state is
                
                when ST_POWER_ON =>
                    if ready_init = '1' then -- Espera a que el LCD encienda
                        state <= ST_BIENVENIDOS;
                    end if;

                when ST_BIENVENIDOS =>
                    cmd_out <= "0001"; -- ID de BIENVENIDOS
                    if busy_drv = '1' then -- Ya empezó a escribir
                        timer <= 0;
                        state <= ST_WAIT1;
                    end if;

                when ST_WAIT1 =>
                    if timer < SEC_3 then
                        timer <= timer + 1;
                    else
                        timer <= 0;
                        state <= ST_DIVIERTANSE;
                    end if;

                when ST_DIVIERTANSE =>
                    cmd_out <= "0010"; 
                    if busy_drv = '1' then
                        timer <= 0;
                        state <= ST_WAIT2;
                    end if;

                when ST_WAIT2 =>
                    if timer < SEC_3 then
                        timer <= timer + 1;
                    else
                        timer <= 0;
                        state <= ST_MODO_JUEGO;
                    end if;

                when ST_MODO_JUEGO =>
                    cmd_out <= "0011"; -- ID de "SELECCIONE JUEGO"
                    -- Aquí se queda permanentemente hasta un nuevo Reset 
                    -- o puedes añadir lógica para que escuche los switches.

                when others => state <= ST_POWER_ON;
            end case;
        end if;
    end process;
end Behavioral;