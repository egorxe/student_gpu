library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity axis_fifo_wrapper is
    generic(
        DEPTH : integer := 4096;
        DATA_WIDTH : integer := 32;
        KEEP_WIDTH : integer := DATA_WIDTH/8;
        ID_WIDTH : integer := 8;
        DEST_WIDTH : integer := 8;
        USER_WIDTH : integer := 8
    );
    port(
        clk                  : in  std_logic;
        rst                  : in  std_logic;
        
        s_axis_tdata         : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        s_axis_tkeep         : in  std_logic_vector(DATA_WIDTH/8 - 1 downto 0);
        s_axis_tvalid        : in  std_logic;
        s_axis_tlast         : in  std_logic;
        s_axis_tid           : in  std_logic_vector(ID_WIDTH - 1 downto 0);
        s_axis_tdest         : in  std_logic_vector(DEST_WIDTH - 1 downto 0);
        s_axis_tuser         : in  std_logic_vector(USER_WIDTH - 1 downto 0);
        s_axis_tready        : out std_logic;
        
        
        m_axis_tdata        : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        m_axis_tkeep        : out std_logic_vector(DATA_WIDTH/8 - 1 downto 0);
        m_axis_tvalid       : out std_logic;
        m_axis_tlast        : out std_logic;
        m_axis_tid          : out std_logic_vector(ID_WIDTH - 1 downto 0);
        m_axis_tdest        : out std_logic_vector(DEST_WIDTH - 1 downto 0);
        m_axis_tuser        : out std_logic_vector(USER_WIDTH - 1 downto 0);
        m_axis_tready       : in  std_logic
        
        );
end axis_fifo_wrapper;

architecture behav of axis_fifo_wrapper is
   component axis_fifo is
        generic(
            DEPTH                : integer   := 4096;
            DATA_WIDTH           : integer   := 8;
            KEEP_ENABLE          : integer   := 1;
            KEEP_WIDTH           : integer   := 512;
            LAST_ENABLE          : integer   := 1;
            ID_ENABLE            : integer   := 0;
            ID_WIDTH             : integer   := 8;
            DEST_ENABLE          : integer   := 0;
            DEST_WIDTH           : integer   := 8;
            USER_ENABLE          : integer   := 1;
            USER_WIDTH           : integer   := 1;
            PIPELINE_OUTPUT      : integer   := 2;
            FRAME_FIFO           : integer   := 0;
            USER_BAD_FRAME_VALUE : std_logic := '1';
            USER_BAD_FRAME_MASK  : std_logic := '1';
            DROP_BAD_FRAME       : integer   := 0;
            DROP_WHEN_FULL       : integer   := 0
        );
        port(
            clk               : in  std_logic;
            rst               : in  std_logic;
            s_axis_tdata      : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
            s_axis_tkeep      : in  std_logic_vector(KEEP_WIDTH - 1 downto 0);
            s_axis_tvalid     : in  std_logic;
            s_axis_tready     : out std_logic;
            s_axis_tlast      : in  std_logic;
            s_axis_tid        : in  std_logic_vector(ID_WIDTH - 1 downto 0);
            s_axis_tdest      : in  std_logic_vector(DEST_WIDTH - 1 downto 0);
            s_axis_tuser      : in  std_logic_vector(USER_WIDTH - 1 downto 0);
            m_axis_tdata      : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            m_axis_tkeep      : out std_logic_vector(KEEP_WIDTH - 1 downto 0);
            m_axis_tvalid     : out std_logic;
            m_axis_tready     : in  std_logic;
            m_axis_tlast      : out std_logic;
            m_axis_tid        : out std_logic_vector(ID_WIDTH - 1 downto 0);
            m_axis_tdest      : out std_logic_vector(DEST_WIDTH - 1 downto 0);
            m_axis_tuser      : out std_logic_vector(USER_WIDTH - 1 downto 0);
            status_overflow   : out std_logic;
            status_bad_frame  : out std_logic;
            status_good_frame : out std_logic
        );
    end component;
begin

    AXIS_FIFO_INST : axis_fifo
        generic map(
            DEPTH                => DEPTH,
            DATA_WIDTH           => DATA_WIDTH,
            KEEP_ENABLE          => 1,
            KEEP_WIDTH           => DATA_WIDTH/8,
            LAST_ENABLE          => 1,
            ID_ENABLE            => 1,
            ID_WIDTH             => ID_WIDTH,
            DEST_ENABLE          => 1,
            DEST_WIDTH           => DEST_WIDTH,
            USER_ENABLE          => 1,
            USER_WIDTH           => USER_WIDTH,
            PIPELINE_OUTPUT      => 1,
            FRAME_FIFO           => 0,
            USER_BAD_FRAME_VALUE => '0',
            USER_BAD_FRAME_MASK  => '0',
            DROP_BAD_FRAME       => 0,
            DROP_WHEN_FULL       => 0
        )
        port map(
            clk               => clk,
            rst               => rst,
            s_axis_tdata      => s_axis_tdata,
            s_axis_tkeep      => s_axis_tkeep,
            s_axis_tvalid     => s_axis_tvalid,
            s_axis_tready     => s_axis_tready,
            s_axis_tlast      => s_axis_tlast,
            s_axis_tid        => s_axis_tid,
            s_axis_tdest      => s_axis_tdest,
            s_axis_tuser      => s_axis_tuser,
            m_axis_tdata      => m_axis_tdata,
            m_axis_tkeep      => m_axis_tkeep,
            m_axis_tvalid     => m_axis_tvalid,
            m_axis_tready     => m_axis_tready,
            m_axis_tlast      => m_axis_tlast,
            m_axis_tid        => m_axis_tid,
            m_axis_tdest      => m_axis_tdest,
            m_axis_tuser      => m_axis_tuser,
            status_overflow   => open,
            status_bad_frame  => open,
            status_good_frame => open
        );
end behav;
