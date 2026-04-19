library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LCD_Full_System_tb is
end LCD_Full_System_tb;

architecture sim of LCD_Full_System_tb is

    -- 1. Señales para conectar al componente Top-Level
    signal clk_tb    : std_logic := '0';
    signal rst_tb    : std_logic := '0';
    signal sw_tb     : std_logic_vector(3 downto 0) := "1111"; -- Simulando DIP Switches
    
    -- Salidas físicas del LCD
    signal lcd_rs_tb : std_logic;
    signal lcd_rw_tb : std_logic;
    signal lcd_e_tb  : std_logic;
    signal lcd_d_tb  : std_logic_vector(3 downto 0);

    -- Constantes de tiempo
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz

begin

    -- 2. Instancia de tu entidad raíz (TOP)
    -- Asegúrate de que en tu archivo LCD.vhd hayas añadido el puerto 'sw'
    uut: entity work.LCD
        port map (
            clk    => clk_tb,
            rst    => rst_tb,
            -- sw     => sw_tb, -- Descomenta esta línea si ya añadiste 'sw' en LCD.vhd
            LCD_RS => lcd_rs_tb,
            LCD_RW => lcd_rw_tb,
            LCD_E  => lcd_e_tb,
            LCD_D  => lcd_d_tb
        );

    -- 3. Generador de Reloj (50 MHz)
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 4. Proceso de Estímulos (Secuencia de prueba paso a paso)
    stim_proc: process
    begin		
        -- Fase 1: Reset del sistema (Active High según tus archivos)
        report "Aplicando Reset...";
        rst_tb <= '1';
        wait for 100 ns;
        rst_tb <= '0';
        
        -- Fase 2: Espera de Inicialización
        -- IMPORTANTE: La inicialización real toma ~20ms. 
        -- En ModelSim verás que pasan muchos ciclos antes de que LCD_E se mueva.
        report "Esperando que termine LCD_INIT_FSM...";
        wait for 16 ms; 

        -- Fase 3: Probar Mensaje de BIENVENIDA (ID: 0001)
        report "Probando mensaje 0001: Bienvenidos";
        sw_tb <= "0001";
        wait for 5 ms; -- Tiempo suficiente para ver las ráfagas de datos en la onda

        -- Fase 4: Probar Mensaje TEST (ID: 0100)
        report "Probando mensaje 0100: TEST";
        sw_tb <= "0100";
        wait for 2 ms;

        -- Fase 5: Regresar a reposo
        report "Regresando switches a reposo (1111)";
        sw_tb <= "1111";
        wait for 1 ms;

        report "Simulación completada con éxito.";
        wait;
    end process;

end sim;