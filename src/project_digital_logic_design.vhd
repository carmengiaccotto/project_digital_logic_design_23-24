----------------------------------------------------------------------------------
--
-- Prova Finale (Progetto di Reti Logiche)
-- Anno Accademico 2023/2024
--
-- Carmen Giaccotto
-- Alessia Franchetti-Rosada
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        i_clk       : in std_logic;
        i_rst       : in std_logic;
        i_start     : in std_logic;
        i_add       : in std_logic_vector(15 downto 0);
        i_k         : in std_logic_vector(9 downto 0);
        o_done      : out std_logic;
        o_mem_addr  : out std_logic_vector(15 downto 0);
        i_mem_data  : in std_logic_vector(7 downto 0);
        o_mem_data  : out std_logic_vector(7 downto 0);
        o_mem_we    : out std_logic;
        o_mem_en    : out std_logic
    );
end project_reti_logiche;

architecture behavioral of project_reti_logiche is

    type state_type is (RESET, INIT, INIT_2, CHECK_CONDITION, CHECK_CONDITION_2, READ_DATA, READ_DATA_2, READ, READ_2, WRITE_MEM, WRITE_MEM_2, WRITE_MEM_3, 
                        LOAD_MEM_DATA, ST_TMP, ST_TMP_2, PREPARE_WRITE, WRITE_MEM_4, UPDATE_COUNT, ASSIGN_C, DONE);
    signal current_state: state_type;

    signal val                : std_logic_vector(7 downto 0);
    signal c                  : unsigned(7 downto 0);
    signal output_select      : std_logic;
    signal adder_first_enable : std_logic;
    signal adder_enable       : std_logic;
    signal initialize_c_enable: std_logic;
    signal c_enable           : std_logic;
    signal val_enable         : std_logic;
    signal add_out            : std_logic_vector(15 downto 0);
    signal data_out           : std_logic_vector(7 downto 0);
    signal count_in           : std_logic_vector(9 downto 0);

    component adder is
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            enable      : in  std_logic;
            first_enable: in  std_logic;
            adder_in    : in  std_logic_vector(15 downto 0);
            adder_out   : out std_logic_vector(15 downto 0);
            count_out   : out std_logic_vector(9 downto 0)
        );
    end component;
    
    component down_counter is
    port(
        clk    : in std_logic;
        rst    : in std_logic;
        en1    : in std_logic;
        en2    : in std_logic;
        c      : out unsigned(7 downto 0)
    );
    end component;
    
    component register_1 is
    port(
        clk    : in std_logic;     
        rst    : in std_logic;      
        enable : in std_logic; 
        d_in   : in std_logic_vector(7 downto 0);
        d_out  : out std_logic_vector(7 downto 0)
    );
    end component;

begin

    adder_inst : adder
        port map (
            clk          => i_clk,
            rst          => i_rst,
            enable       => adder_enable,
            first_enable => adder_first_enable,
            adder_in     => i_add,
            adder_out    => add_out,
            count_out    => count_in 
        );
        
    down_counter_inst : down_counter
       port map (
            clk    => i_clk,
            rst    => i_rst,
            en1    => initialize_c_enable,
            en2    => c_enable,
            c      => c
        );
        
     register_1_inst : register_1
       port map (
            clk    => i_clk,
            rst    => i_rst,
            enable => val_enable,
            d_in   => i_mem_data,
            d_out  => val
        );
        
        o_mem_data <= data_out;
        o_mem_addr <= add_out;

    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            current_state <= RESET;
        elsif rising_edge(i_clk) then
            case current_state is
            when RESET =>
                if i_start = '1' then
                    current_state <= INIT;
                else
                    current_state <= RESET;
                end if;

            when INIT =>
                current_state <= ST_TMP;
                
            when ST_TMP =>
                current_state <= CHECK_CONDITION;      

            when CHECK_CONDITION =>
                if unsigned(count_in) < (2 * unsigned(i_k)) then
                    current_state <= READ_DATA;
                else
                    current_state <= DONE;
                end if;

            when READ_DATA => 
               current_state <= WRITE_MEM;
                
            when WRITE_MEM =>
              current_state <= READ;
                
            when READ =>
                if i_mem_data = "00000000" then
                    current_state <= INIT_2;
                else
                   current_state <= WRITE_MEM_2 ;
                end if;
                
             when INIT_2 =>
                current_state <= ST_TMP;

             when WRITE_MEM_2 =>
                current_state <= LOAD_MEM_DATA;

             when LOAD_MEM_DATA =>
                current_state <= ST_TMP_2 ;
                
             when ST_TMP_2 =>
                current_state <= CHECK_CONDITION_2;

             when CHECK_CONDITION_2 =>
                if unsigned(count_in) < (2 * unsigned(i_k)) then
                    current_state <= READ_DATA_2;
                else
                    current_state <= DONE;
                end if;
           
             when READ_DATA_2 =>
                if i_mem_data = "00000000" then
                    current_state <= PREPARE_WRITE;
                else
                    current_state <= WRITE_MEM_3;
                end if;
                
            when WRITE_MEM_3 =>
                current_state <= READ_2;
                
            when READ_2 =>
                current_state <= WRITE_MEM_2;

            when PREPARE_WRITE =>
                current_state <= WRITE_MEM_4;

            when WRITE_MEM_4 =>
                current_state <= UPDATE_COUNT;

            when UPDATE_COUNT =>
                current_state <= ASSIGN_C;
      
            when ASSIGN_C =>
                current_state <= WRITE_MEM_2;
         
            when DONE =>
                if i_start = '0' then
                    current_state <= RESET;
                else
                    current_state <= DONE;
                end if;

            when others =>
                current_state <= RESET;
                
        end case;
        end if;
    end process;

    process(current_state)
    begin
        -- Default output values
        initialize_c_enable <= '0';
        c_enable <= '0';
        val_enable <= '0';
        output_select <= '1';
        o_done <= '0';
        o_mem_en <= '1';
        o_mem_we <= '0';
        adder_enable <= '0';
        adder_first_enable <= '0';

        case current_state is
            when RESET =>
                initialize_c_enable <= '1';

            when INIT =>
                adder_first_enable <= '1';
                
            when ST_TMP =>
                adder_first_enable <= '0';
                adder_enable <= '0';
                
            when CHECK_CONDITION =>
                adder_enable <= '0';

            when READ_DATA => 
               val_enable <= '1';
 
            when WRITE_MEM =>
              adder_enable <= '1';
              output_select <= '1';
              o_mem_we <= '1';
                 
            when READ =>
                o_mem_we <= '0';
                if i_mem_data /= "00000000" then
                   initialize_c_enable <= '1';
                end if;
                
             when INIT_2 =>
                adder_enable <= '1';

            when WRITE_MEM_2 =>
                adder_enable <= '0';
                o_mem_we <= '1';
                output_select <= '0';

            when LOAD_MEM_DATA =>
                o_mem_we <= '0';
                adder_enable <= '1';
                
            when ST_TMP_2 =>
              adder_enable <= '0';

            when READ_DATA_2 =>
               if i_mem_data = "00000000" then
                   output_select <= '1'; 
               else
                   initialize_c_enable <= '1';
                   val_enable <= '1';
                end if;
                
            when WRITE_MEM_3 =>
                o_mem_we <= '1';
                output_select <= '1';
                
            when READ_2 =>
                o_mem_we <= '0';
                adder_enable <= '1';

            when PREPARE_WRITE =>
                output_select <= '1';
                adder_enable <= '0';
                o_mem_we <= '1';

            when WRITE_MEM_4 =>
                o_mem_we <= '0';
                adder_enable <= '1';

            when UPDATE_COUNT =>
                o_mem_we <= '0';
                adder_enable <= '0';
                c_enable <= '1';
      
            when ASSIGN_C =>
                adder_enable <= '0';
                output_select <= '0';
         
            when DONE =>
                o_done <= '1';

            when others =>

        end case;
    end process;
    
    process(output_select, val, c)
    begin
        if output_select = '1' then
            data_out <= val;
        else
            data_out <= std_logic_vector(c);
        end if;
    end process;

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity adder is
    Port (
        clk        : in  STD_LOGIC;
        rst        : in  STD_LOGIC;
        enable     : in  STD_LOGIC;
        first_enable : in  STD_LOGIC;
        adder_in   : in  STD_LOGIC_VECTOR(15 downto 0);
        adder_out  : out STD_LOGIC_VECTOR(15 downto 0);
        count_out  : out STD_LOGIC_VECTOR(9 downto 0)
    );
end adder;

architecture behavioral of adder is
    signal internal_add  : STD_LOGIC_VECTOR(15 downto 0);
    signal counter       : STD_LOGIC_VECTOR(9 downto 0);
begin
    process(clk, rst)
    begin
        if rst = '1' then
            internal_add <= (others => '0');
        elsif rising_edge(clk) then
            if first_enable = '1' then
                counter <= "0000000001";
                internal_add <= adder_in;
            end if;
            if enable = '1' then
               internal_add <= internal_add + 1;
               counter <= counter + 1;
            end if;
        end if;
    end process;

    adder_out <= internal_add;
    count_out <= counter;

end behavioral;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity down_counter is
    port(
        clk    : in std_logic;
        rst    : in std_logic;
        en1    : in std_logic;
        en2    : in std_logic;
        c      : out unsigned(7 downto 0)
    );
end entity down_counter;

architecture behavioral of down_counter is
    signal reg_c : unsigned(7 downto 0);
begin
    process(clk, rst)
    begin
        if rst = '1' then
            reg_c <= (others => '0');
        elsif rising_edge(clk) then
            if en1 = '1' then
                reg_c <= to_unsigned(31, 8);
            elsif en2 = '1' then
                if reg_c > 0 then
                    reg_c <= reg_c - 1;
                end if;
            end if;
        end if;
    end process;

    c <= reg_c;

end architecture behavioral;

library ieee;
use ieee.std_logic_1164.all;

entity register_1 is
    port(
        clk    : in std_logic;    
        rst    : in std_logic;  
        enable : in std_logic;     
        d_in    : in std_logic_vector(7 downto 0);
        d_out   : out std_logic_vector(7 downto 0)
    );
end entity register_1;

architecture behavioral of register_1 is
    signal reg_dout : std_logic_vector(7 downto 0);
begin
    process(clk, rst)
    begin
        if rst = '1' then
            reg_dout <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                reg_dout <= d_in;
            end if;
        end if;
    end process;

    d_out <= reg_dout;
end architecture behavioral;