library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.lcd_pkg.all;

entity LCD is
    port(
        clk    : in  std_logic; 
        rst    : in  std_logic; 
        botones : in std_logic_vector(3 downto 0); -- Nueva entrada para los modos
        
        -- Salidas físicas del LCD
        LCD_RS : out std_logic;
        LCD_RW : out std_logic;
        LCD_E  : out std_logic;
        LCD_D  : out std_logic_vector(3 downto 0)
    );
end LCD;

architecture Behavioral of LCD is

    -- Señales de control de hardware
    signal ce_1us     : std_logic; 
    signal init_done  : std_logic; 
    signal drv_rs, drv_e : std_logic;
    signal drv_d          : std_logic_vector(3 downto 0);
    signal drv_busy       : std_logic;
    signal msg_id         : std_logic_vector(3 downto 0);
    signal msg_start      : std_logic;
    signal init_rs, init_e : std_logic;
    signal init_d          : std_logic_vector(3 downto 0);

    -- Señales de flujo de mensajes
    signal cmd_secuencia : std_logic_vector(3 downto 0);
    signal cmd_juego     : std_logic_vector(3 downto 0);
    signal cmd_final     : std_logic_vector(3 downto 0);
    signal secuencia_ok  : std_logic;

    -- Señales del cronómetro
    signal jugando_en    : std_logic;
    signal segundos      : integer range 0 to 999;

begin

    LCD_RW <= '0';

    -- MULTIPLEXADO DE PINES FÍSICOS (Hardware)
    LCD_RS <= init_rs when init_done = '0' else drv_rs;
    LCD_E  <= init_e  when init_done = '0' else drv_e;
    LCD_D  <= init_d  when init_done = '0' else drv_d;

    -- 1. Base de tiempo
    u_timer : entity work.LCD_Timer
        generic map ( CLK_FREQ_HZ => 50_000_000 )
        port map ( clk => clk, rst => rst, en => '1', ce_1us => ce_1us );

    -- 2. Inicialización
    u_init : entity work.LCD_INIT_FSM
        generic map ( CLK_FREQ_HZ => 50_000_000 )
        port map (
            clk => clk, rst => rst, ce_1us => ce_1us,
            LCD_RS => init_rs, LCD_E => init_e, LCD_D => init_d,
            init_done => init_done 
        );

    -- 3. Secuenciador Automático (Bienvenida)
    u_sec : entity work.Secuencia_inicio
        generic map ( CLK_FREQ => 50_000_000 )
        port map (
            clk        => clk,
            rst        => rst,
            ready_init => init_done,
            busy_drv   => drv_busy,
            cmd_out    => cmd_secuencia
        );

    -- Lógica de transición: cuando la bienvenida llega a "Seleccione Juego" (ID 0011)
    secuencia_ok <= '1' when cmd_secuencia = "0011" else '0';

    -- 4. Secuenciador de Juego (Recibe los botones)
    u_juego : entity work.Secuencia_Juego
        generic map ( CLK_FREQ => 50_000_000 )
        port map (
            clk          => clk,
            rst          => rst,
            botones_in   => botones,
            secuencia_ok => secuencia_ok,
            busy_drv     => drv_busy,
            cmd_juego    => cmd_juego,
            jugando_en   => jugando_en
        );

    -- 5. Cronómetro
    u_cron : entity work.Cronometro_Juego
        generic map ( CLK_FREQ => 50_000_000 )
        port map (
            clk        => clk,
            rst        => rst,
            jugando_en => jugando_en,
            segundos   => segundos
        );

    -- MUX de mensajes: Si terminó la bienvenida, manda el control del juego
    cmd_final <= cmd_juego when secuencia_ok = '1' else cmd_secuencia;

    -- 6. Gestor de Mensajes
    u_msg_ctrl : entity work.FSM_Mensajes
        port map (
            clk       => clk,
            rst       => rst,
            cmd       => cmd_final, -- Ahora recibe la señal del MUX
            ready     => init_done,
            busy_drv  => drv_busy,
            start_drv => msg_start,
            msg_id    => msg_id
        );

    -- 7. Driver de bajo nivel
    u_driver : entity work.FSM_LCD
        generic map ( CLK_FREQ => 50_000_000 )
        port map (
            clk => clk, rst => rst, start => msg_start, msg_id => msg_id,
            LCD_RS => drv_rs, LCD_E => drv_e, LCD_D => drv_d,
            busy => drv_busy, done => open
        );

end Behavioral;