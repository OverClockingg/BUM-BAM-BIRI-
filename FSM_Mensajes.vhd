--------------------------------------------------------------------------------
-- Institución: Instituto Politécnico Nacional (IPN) - UPIITA
-- Proyecto:    Exergame "BUM BAM BIRI" - Tarea 1 DLP
-- Módulo:      FSM_Mensajes
-- Descripción: Máquina de estados de alto nivel que gestiona la selección y
--              el disparo (trigger) de mensajes hacia el driver del LCD.
--              Implementa un protocolo de comunicación robusto (Handshake)
--              para asegurar la correcta transferencia de datos.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.lcd_pkg.all; -- Importa el almacén de mensajes y tipos

entity FSM_Mensajes is
    port(
        clk       : in  std_logic; -- Reloj de sistema (ej. 50MHz)
        rst       : in  std_logic; -- Reset asíncrono
        
        -- Interfaz de Control
        cmd       : in  std_logic_vector(3 downto 0); -- Código del mensaje a mostrar
        ready     : in  std_logic; -- Indica que el LCD ha terminado su inicialización
        
        -- Interfaz con el Driver (FSM_LCD)
        busy_drv  : in  std_logic; -- Señal de ocupado proveniente del driver
        start_drv : out std_logic; -- Pulso de inicio para el driver
        msg_id    : out std_logic_vector(3 downto 0) -- ID del mensaje estabilizado
    );
end FSM_Mensajes;

architecture Behavioral of FSM_Mensajes is

    -- Definición de estados de la FSM
    -- ST_IDLE:    Espera pasiva de un comando válido (distinto de "1111")
    -- ST_LATCH:   Etapa de registro para estabilizar el bus de datos msg_id
    -- ST_TRIGGER: Generación del pulso de inicio con espera de confirmación
    -- ST_WAIT:    Bloqueo de seguridad hasta que el driver libere el recurso
    type state_t is (ST_IDLE, ST_LATCH, ST_TRIGGER, ST_WAIT);
    signal state : state_t;
    
    -- Registro interno para evitar variaciones en el bus durante la impresión
    signal msg_id_reg : std_logic_vector(3 downto 0);

begin

    ----------------------------------------------------------------------------
    -- Proceso Principal: Control de Flujo de Mensajes
    ----------------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            -- Estado inicial de reset
            state      <= ST_IDLE;
            start_drv  <= '0';
            msg_id_reg <= "1111"; -- ID neutro
            msg_id     <= "1111";
            
        elsif rising_edge(clk) then
            -- Asignación por defecto: Garantiza que start_drv sea un pulso y 
            -- previene la inferencia de latches involuntarios.
            start_drv <= '0';

            -- El sistema solo opera si el hardware del LCD está listo (ready = '1')
            if ready = '1' then
                case state is
                    
                    -- 1. Monitoreo de entrada y estado del driver
                    when ST_IDLE =>
                        if cmd /= "1111" and busy_drv = '0' then
                            msg_id_reg <= cmd; -- Captura el comando entrante
                            state      <= ST_LATCH;
                        end if;

                    -- 2. Sincronización: Se coloca el ID en el puerto de salida
                    -- un ciclo antes del trigger para asegurar el Setup Time.
                    when ST_LATCH =>
                        msg_id <= msg_id_reg;
                        state  <= ST_TRIGGER;

                    -- 3. Protocolo Handshake: Se activa 'start' y se mantiene
                    -- hasta que el receptor (driver) acuse de recibo con 'busy'.
                    when ST_TRIGGER =>
                        start_drv <= '1';
                        if busy_drv = '1' then
                            state <= ST_WAIT;
                        end if;

                    -- 4. Protección: Evita que nuevos comandos interrumpan la 
                    -- escritura actual en el display.
                    when ST_WAIT =>
                        if busy_drv = '0' then
                            state <= ST_IDLE;
                        end if;

                    when others => 
                        state <= ST_IDLE;
                end case;
            else
                -- Regreso preventivo a reposo si se pierde la señal de listo
                state <= ST_IDLE;
            end if;
        end if;
    end process;

end Behavioral;