library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Cronometro_Juego is
    generic(
        CLK_FREQ : integer := 50_000_000 -- Reloj de la FPGA (50MHz)
    );
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        jugando_en : in  std_logic; -- Señal de habilitación (Enable)
        
        -- Salidas para el LCD (pueden ser enteros o convertidos a BCD)
        segundos   : out integer range 0 to 999
    );
end Cronometro_Juego;

architecture Behavioral of Cronometro_Juego is
    -- Contador para generar el pulso de 1 segundo
    signal prescaler : integer range 0 to CLK_FREQ := 0;
    -- Registro para los segundos transcurridos
    signal r_segundos : integer range 0 to 999 := 0;

begin
    segundos <= r_segundos;

    process(clk, rst)
    begin
        if rst = '1' then
            prescaler <= 0;
            r_segundos <= 0;
            
        elsif rising_edge(clk) then
            -- Solo cuenta si la señal 'jugando_en' está activa [cite: 22]
            if jugando_en = '1' then
                if prescaler < (CLK_FREQ - 1) then
                    prescaler <= prescaler + 1;
                else
                    prescaler <= 0;
                    -- Incrementar segundos si no hemos llegado al límite del display
                    if r_segundos < 999 then
                        r_segundos <= r_segundos + 1;
                    end if;
                end if;
            else
                -- Si el juego se detiene por error, el tiempo se mantiene 
                prescaler <= 0;
                -- Aquí podrías decidir si el rst del sistema limpia el cronómetro 
                -- para la siguiente partida.
            end if;
        end if;
    end process;
end Behavioral;