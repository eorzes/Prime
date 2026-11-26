library ieee;
use ieee.std_logic_1164.all;

use work.gt_pkg.all;
use work.arrays_pkg.all; 

entity quads_chs_map is
  generic(
    QUADs_GTs_map : QUADs_GTs_map_t := (0 => (0, -1, -1, -1));
    QUADs_N       : positive        := 1;  
    GTs_N         : positive        := 1;        -- total number of channels among quads
    QUADs_BUF_map : integer_array   := (0 => 0); -- BUFG_GT dest (quad id) => BUFG_GT source (quad id)
    MTX           : integer_array   := (0 => 0); -- channel index of the GT provider of txusrclk, per quad
    SIM_DEVICE    : string          := "VERSAL_PREMIUM"
  );
  port(
    clk_sys     : in  std_logic;
    gt_refclk_p : in  std_logic_vector(QUADs_N-1 downto 0);
    gt_refclk_n : in  std_logic_vector(QUADs_N-1 downto 0);
    gt_rx_p     : in  std_logic_vector(GTs_N-1 downto 0);
    gt_rx_n     : in  std_logic_vector(GTs_N-1 downto 0);
    gt_tx_p     : out std_logic_vector(GTs_N-1 downto 0);
    gt_tx_n     : out std_logic_vector(GTs_N-1 downto 0);
    gt_ctrl_i   : in  gt_ctrl_array_t (GTs_N-1 downto 0);
    gt_stat_o   : out gt_stat_array_t (GTs_N-1 downto 0);
    gt_i        : in  to_gt_array_t   (GTs_N-1 downto 0);
    gt_o        : out from_gt_array_t (GTs_N-1 downto 0);
    refclk_o    : out std_logic;
    txpi_done_i : in  std_logic_vector(GTs_N-1 downto 0);
  );
end quads_chs_map;

architecture rtl of quads_chs_map is

  signal gt_rx_p_in  : array_nb(0 to QUADs_N-1)(0 to 3);
  signal gt_rx_n_in  : array_nb(0 to QUADs_N-1)(0 to 3);
  signal gt_tx_p_out : array_nb(0 to QUADs_N-1)(0 to 3);
  signal gt_tx_n_out : array_nb(0 to QUADs_N-1)(0 to 3);

  signal gt_ctrl_in  : gt_ctrl_matrix_t(0 to QUADs_N-1);
  signal gt_stat_out : gt_stat_matrix_t(0 to QUADs_N-1);
  signal gt_in       : to_gt_matrix_t(0 to QUADs_N-1);
  signal gt_out      : from_gt_matrix_t(0 to QUADs_N-1);
  
  signal gt_refclk   : std_logic_vector(0 to QUADs_N-1);
  signal refclk      : std_logic_vector(0 to QUADs_N-1);
  
  signal txpi_done   : array_nb(0 to QUADs_N-1)(0 to 3);

begin

    QUADs_map: for i in 0 to QUADs_N-1 generate
        CHs_map: for j in 0 to 3 generate
            CH_signals: if QUADs_GTs_map(i)(j) > -1 generate 
                gt_rx_p_in(i)(j)               <= gt_rx_p(QUADs_GTs_map(i)(j));
                gt_rx_n_in(i)(j)               <= gt_rx_n(QUADs_GTs_map(i)(j));
                gt_ctrl_in(i)(j)               <= gt_ctrl_i(QUADs_GTs_map(i)(j));
                gt_in(i)(j)                    <= gt_i(QUADs_GTs_map(i)(j));
                gt_tx_p(QUADs_GTs_map(i)(j))   <= gt_tx_p_out(i)(j);
                gt_tx_n(QUADs_GTs_map(i)(j))   <= gt_tx_n_out(i)(j);
                gt_stat_o(QUADs_GTs_map(i)(j)) <= gt_stat_out(i)(j);
                gt_o(QUADs_GTs_map(i)(j))      <= gt_out(i)(j);
                txpi_done(i)(j)                <= txpi_done_i(QUADs_GTs_map(i)(j));
            end generate CH_signals;
        end generate CHs_map; 
    end generate QUADs_map; 
    
    bufg_inst: for i in 0 to QUADs_N-1 generate
        buf_gen: if i = QUADs_BUF_map(i) generate
            gtclk: entity work.gt_buf
                generic map ( SIM_DEVICE => SIM_DEVICE )
                port map(
                    i     => gt_refclk_p(i),  
                    ib    => gt_refclk_n(i),  
                    o     => gt_refclk(i),
                    clk_o => refclk(i)
                );
        end generate buf_gen;
    end generate bufg_inst;
    
    refclk_o <= refclk(0);

    quad_inst: for i in 0 to QUADs_N-1 generate 
        mgt: entity work.m_gt
            generic map ( ACTIVE_CHs => QUADs_GTs_map(i), MTX => MTX(i), SIM_DEVICE => SIM_DEVICE ) 
            port map(
                clk_sys   => clk_sys,
                gt_refclk => gt_refclk(QUADs_BUF_map(i)),
                gt_rx_p   => gt_rx_p_in(i),   
                gt_rx_n   => gt_rx_n_in(i), 
                gt_tx_p   => gt_tx_p_out(i),   
                gt_tx_n   => gt_tx_n_out(i), 
                gt_ctrl_i => gt_ctrl_in(i), 
                gt_stat_o => gt_stat_out(i), 
                gt_i      => gt_in(i),   
                gt_o      => gt_out(i),
                txpi_done => txpi_done(i)
            );
    end generate quad_inst;
    
end rtl;
