--------------------------------------------------------------------------------
-- Institución: Instituto Politécnico Nacional (IPN) - UPIITA
-- Proyecto:    Exergame "BUM BAM BIRI" - Tarea 1 DLP
-- Módulo:      LCD (Top-Level)
-- Descripción: Módulo raíz que integra el temporizador, la inicialización,
--              la gestión de mensajes y el driver físico del LCD.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.lcd_pkg.all; -- Importa mensajes y funciones del package

entity LCD is
    port(
        clk    : in  std_logic; -- Reloj maestro (50 MHz)
        rst    : in  std_logic; -- Reset físico (Push button)
        
        -- Pines físicos del LCD 16x2
        LCD_RS : out std_logic;
        LCD_RW : out std_logic;
        LCD_E  : out std_logic;
        LCD_D  : out std_logic_vector(3 downto 0)
    );
end LCD;

architecture Behavioral of LCD is

    -- Señales de interconexión interna
    signal ce_1us    : std_logic; 
    signal init_done : std_logic; 
    
    -- Señales del Driver (FSM_LCD_FINAL)
    signal drv_rs, drv_e : std_logic;
    signal drv_d          : std_logic_vector(3 downto 0);
    signal drv_busy       : std_logic;
    signal drv_done       : std_logic;
    
    -- Señales de la FSM de Mensajes
    signal msg_id         : std_logic_vector(3 downto 0);
    signal msg_start      : std_logic;
    
    -- Señales de la FSM de Inicialización
    signal init_rs, init_e : std_logic;
    signal init_d          : std_logic_vector(3 downto 0);

    -- Comando de control (Puedes conectarlo a un selector o máquina de juego)
    -- "0001" disparará el mensaje de bienvenida definido en lcd_pkg
    signal cmd_juego      : std_logic_vector(3 downto 0) := "0001";

begin

    -- El pin RW se mantiene en bajo permanentemente (Modo Escritura)
    LCD_RW <= '0';

    ----------------------------------------------------------------------------
    -- LÓGICA DE MULTIPLEXADO (CRÍTICO)
    ----------------------------------------------------------------------------
    -- Mientras init_done sea '0', u_init tiene el control total de los pines.
    -- Una vez terminado (init_done = '1'), el control pasa al driver de mensajes.
    ----------------------------------------------------------------------------
    LCD_RS <= init_rs when init_done = '0' else drv_rs;
    LCD_E  <= init_e  when init_done = '0' else drv_e;
    LCD_D  <= init_d  when init_done = '0' else drv_d;

    ----------------------------------------------------------------------------
    -- INSTANCIACIÓN DE MÓDULOS
    ----------------------------------------------------------------------------

    -- 1. Base de tiempo de 1 microsegundo
    u_timer : entity work.LCD_Timer
        generic map ( CLK_FREQ_HZ => 50_000_000 )
        port map (
            clk    => clk,
            rst    => rst,
            en     => '1',
            ce_1us => ce_1us 
        );

    -- 2. Máquina de estados de inicialización (Modo 4-bits)
    u_init : entity work.LCD_INIT_FSM
        generic map ( CLK_FREQ_HZ => 50_000_000 )
        port map (
            clk       => clk,
            rst       => rst,
            ce_1us    => ce_1us,
            LCD_RS    => init_rs,
            LCD_E     => init_e,
            LCD_D     => init_d,
            init_done => init_done 
        );

    -- 3. Gestor de Mensajes (Controlador de alto nivel)
    u_msg_ctrl : entity work.FSM_Mensajes
        port map (
            clk       => clk,
            rst       => rst,
            cmd       => cmd_juego,
            ready     => init_done, -- Espera a que termine la inicialización
            busy_drv  => drv_busy,
            start_drv => msg_start,
            msg_id    => msg_id
        );

    -- 4. Driver de bajo nivel (Traductor a nibbles y tiempos de espera)
    u_driver : entity work.FSM_LCD
        generic map ( CLK_FREQ => 50_000_000 )
        port map (
            clk     => clk,
            rst     => rst,
            start   => msg_start,
            msg_id  => msg_id,
            LCD_RS  => drv_rs,
            LCD_E   => drv_e,
            LCD_D   => drv_d,
            busy    => drv_busy,
            done    => drv_done
        );

end Behavioral;