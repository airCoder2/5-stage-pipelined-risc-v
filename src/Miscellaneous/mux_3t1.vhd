-- Date        : March 25, 2026
-- File        : mux_3t1_bus.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a 3t1 bus mux 

library IEEE;
use IEEE.std_logic_1164.all;


entity mux_3t1_bus is
    port(i_x0 : in std_logic_vector(31 downto 0); -- input 1 
         i_x1 : in std_logic_vector(31 downto 0); -- input 2
         i_x2 : in std_logic_vector(31 downto 0); -- input 3
         i_sel: in std_logic_vector(1 downto 0);  -- select line
         o_out : out std_logic_vector(31 downto 0)
     );
end entity mux_3t1_bus;

architecture dataflow of mux_3t1_bus is
begin
    with i_sel select
        o_out <= i_x0 when 2x"00",
                 i_x1 when 2x"01",
                 i_x2 when others;

end architecture;
