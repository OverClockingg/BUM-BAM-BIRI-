library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LCD_Test_Secuencia_tb is
end LCD_Test_Secuencia_tb;

architecture sim of LCD_Test_Secuencia_tb is

    -- 1. Señales para conectar a la entidad LCD
    signal clk_tb     : std_logic := '0';
    signal rst_tb     : std_logic := '0';
    signal botones_tb : std_logic_vector(3 downto 0) := "0000";
    
    -- Salidas físicas del LCD para observar en el simulador
    signal lcd_rs_tb  : std_logic;
    signal lcd_rw_tb  : std_logic;
    signal lcd_e_tb   : std_logic;
    signal lcd_d_tb   : std_logic_vector(3 downto 0);

    -- Constante de reloj (50 MHz = 20ns de periodo)
    constant CLK_PERIOD : time := 20 ns;

begin

    -- 2. Instancia de la entidad LCD (UUT - Unit Under Test)
    uut: entity work.LCD
        port map (
            clk    => clk_tb,
            rst    => rst_tb,
            botones => botones_tb,
            LCD_RS => lcd_rs_tb,
            LCD_RW => lcd_rw_tb,
            LCD_E  => lcd_e_tb,
            LCD_D  => lcd_d_tb
        );

    -- 3. Generador de Reloj
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 4. Proceso de Estímulos
    stim_proc: process
    begin		
        -- FASE 1: Reset inicial
        report "Iniciando simulación: Fase de Reset...";
        rst_tb <= '1';
        botones_tb <= "0000";
        wait for 100 ns;
        rst_tb <= '0';
        
        -- FASE 2: Inicialización de Hardware
        -- Esperamos los 20ms que tarda el módulo LCD_INIT_FSM
        report "Esperando inicialización de hardware (20ms)...";
        wait for 20 ms;

        -- FASE 3: Secuencia Automática de Bienvenida
        -- "Bienvenidos" (3s) -> "Diviértanse" (3s) -> "Seleccione Juego"
        report "Observando secuencia automática de bienvenida...";
        wait for 7 sec; 

        -- FASE 4: Prueba de JUEGO 1
        -- Seleccionamos Juego 1 presionando el botón correspondiente (One-hot 0010)
        report "--- TEST: Seleccionando JUEGO 1 ---";
        botones_tb <= "0010"; 
        wait for 200 ms; -- Simular tiempo de presión
        
        -- Esperar cuenta regresiva: "Juego 1" (1s) -> 3 (1s) -> 2 (1s) -> 1 (1s) -> GO
        report "Esperando cuenta regresiva y mensaje GO...";
        wait for 5 sec;
        
        -- En este punto el cronómetro debe estar corriendo
        report "Verificando que el cronómetro avance...";
        wait for 5 sec; -- El contador 'segundos' dentro de LCD debería llegar a 5
        
        -- FASE 5: Volver a IDLE (Soltar botones)
        report "Soltando botones, volviendo a selección...";
        botones_tb <= "0000";
        wait for 2 sec;

        -- FASE 6: Prueba de JUEGO 2
        report "--- TEST: Seleccionando JUEGO 2 ---";
        botones_tb <= "0001";
        wait for 5 sec; -- Ver el inicio del juego 2

        -- FASE 7: Prueba de Error (Selección múltiple)
        report "--- TEST: Probando error por presionar varios botones ---";
        botones_tb <= "0011"; -- Juego 1 y Juego 2 a la vez
        wait for 2 sec;

        report "Simulación finalizada correctamente.";
        wait;
    end process;

end sim;