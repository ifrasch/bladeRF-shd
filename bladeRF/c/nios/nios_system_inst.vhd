	component nios_system is
		port (
			clk_clk                         : in  std_logic                     := 'X';             -- clk
			command_serial_in               : in  std_logic                     := 'X';             -- serial_in
			command_serial_out              : out std_logic;                                        -- serial_out
			correction_rx_phase_gain_export : out std_logic_vector(31 downto 0);                    -- export
			correction_tx_phase_gain_export : out std_logic_vector(31 downto 0);                    -- export
			dac_MISO                        : in  std_logic                     := 'X';             -- MISO
			dac_MOSI                        : out std_logic;                                        -- MOSI
			dac_SCLK                        : out std_logic;                                        -- SCLK
			dac_SS_n                        : out std_logic_vector(1 downto 0);                     -- SS_n
			gpio_export                     : out std_logic_vector(31 downto 0);                    -- export
			oc_i2c_scl_pad_o                : out std_logic;                                        -- scl_pad_o
			oc_i2c_scl_padoen_o             : out std_logic;                                        -- scl_padoen_o
			oc_i2c_sda_pad_i                : in  std_logic                     := 'X';             -- sda_pad_i
			oc_i2c_sda_pad_o                : out std_logic;                                        -- sda_pad_o
			oc_i2c_sda_padoen_o             : out std_logic;                                        -- sda_padoen_o
			oc_i2c_arst_i                   : in  std_logic                     := 'X';             -- arst_i
			oc_i2c_scl_pad_i                : in  std_logic                     := 'X';             -- scl_pad_i
			reset_reset_n                   : in  std_logic                     := 'X';             -- reset_n
			rx_tamer_ts_sync_in             : in  std_logic                     := 'X';             -- ts_sync_in
			rx_tamer_ts_sync_out            : out std_logic;                                        -- ts_sync_out
			rx_tamer_ts_pps                 : in  std_logic                     := 'X';             -- ts_pps
			rx_tamer_ts_clock               : in  std_logic                     := 'X';             -- ts_clock
			rx_tamer_ts_reset               : in  std_logic                     := 'X';             -- ts_reset
			rx_tamer_ts_time                : out std_logic_vector(63 downto 0);                    -- ts_time
			rx_trigger_ctl_in_port          : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- in_port
			rx_trigger_ctl_out_port         : out std_logic_vector(7 downto 0);                     -- out_port
			shd_state_export                : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- export
			spi_sclk                        : out std_logic;                                        -- sclk
			spi_miso                        : in  std_logic                     := 'X';             -- miso
			spi_mosi                        : out std_logic;                                        -- mosi
			spi_ss_n                        : out std_logic;                                        -- ss_n
			tx_tamer_ts_sync_in             : in  std_logic                     := 'X';             -- ts_sync_in
			tx_tamer_ts_sync_out            : out std_logic;                                        -- ts_sync_out
			tx_tamer_ts_pps                 : in  std_logic                     := 'X';             -- ts_pps
			tx_tamer_ts_clock               : in  std_logic                     := 'X';             -- ts_clock
			tx_tamer_ts_reset               : in  std_logic                     := 'X';             -- ts_reset
			tx_tamer_ts_time                : out std_logic_vector(63 downto 0);                    -- ts_time
			tx_trigger_ctl_in_port          : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- in_port
			tx_trigger_ctl_out_port         : out std_logic_vector(7 downto 0);                     -- out_port
			vctcxo_tamer_tune_ref           : in  std_logic                     := 'X';             -- tune_ref
			vctcxo_tamer_vctcxo_clock       : in  std_logic                     := 'X';             -- vctcxo_clock
			xb_gpio_in_port                 : in  std_logic_vector(31 downto 0) := (others => 'X'); -- in_port
			xb_gpio_out_port                : out std_logic_vector(31 downto 0);                    -- out_port
			xb_gpio_dir_export              : out std_logic_vector(31 downto 0)                     -- export
		);
	end component nios_system;

	u0 : component nios_system
		port map (
			clk_clk                         => CONNECTED_TO_clk_clk,                         --                      clk.clk
			command_serial_in               => CONNECTED_TO_command_serial_in,               --                  command.serial_in
			command_serial_out              => CONNECTED_TO_command_serial_out,              --                         .serial_out
			correction_rx_phase_gain_export => CONNECTED_TO_correction_rx_phase_gain_export, -- correction_rx_phase_gain.export
			correction_tx_phase_gain_export => CONNECTED_TO_correction_tx_phase_gain_export, -- correction_tx_phase_gain.export
			dac_MISO                        => CONNECTED_TO_dac_MISO,                        --                      dac.MISO
			dac_MOSI                        => CONNECTED_TO_dac_MOSI,                        --                         .MOSI
			dac_SCLK                        => CONNECTED_TO_dac_SCLK,                        --                         .SCLK
			dac_SS_n                        => CONNECTED_TO_dac_SS_n,                        --                         .SS_n
			gpio_export                     => CONNECTED_TO_gpio_export,                     --                     gpio.export
			oc_i2c_scl_pad_o                => CONNECTED_TO_oc_i2c_scl_pad_o,                --                   oc_i2c.scl_pad_o
			oc_i2c_scl_padoen_o             => CONNECTED_TO_oc_i2c_scl_padoen_o,             --                         .scl_padoen_o
			oc_i2c_sda_pad_i                => CONNECTED_TO_oc_i2c_sda_pad_i,                --                         .sda_pad_i
			oc_i2c_sda_pad_o                => CONNECTED_TO_oc_i2c_sda_pad_o,                --                         .sda_pad_o
			oc_i2c_sda_padoen_o             => CONNECTED_TO_oc_i2c_sda_padoen_o,             --                         .sda_padoen_o
			oc_i2c_arst_i                   => CONNECTED_TO_oc_i2c_arst_i,                   --                         .arst_i
			oc_i2c_scl_pad_i                => CONNECTED_TO_oc_i2c_scl_pad_i,                --                         .scl_pad_i
			reset_reset_n                   => CONNECTED_TO_reset_reset_n,                   --                    reset.reset_n
			rx_tamer_ts_sync_in             => CONNECTED_TO_rx_tamer_ts_sync_in,             --                 rx_tamer.ts_sync_in
			rx_tamer_ts_sync_out            => CONNECTED_TO_rx_tamer_ts_sync_out,            --                         .ts_sync_out
			rx_tamer_ts_pps                 => CONNECTED_TO_rx_tamer_ts_pps,                 --                         .ts_pps
			rx_tamer_ts_clock               => CONNECTED_TO_rx_tamer_ts_clock,               --                         .ts_clock
			rx_tamer_ts_reset               => CONNECTED_TO_rx_tamer_ts_reset,               --                         .ts_reset
			rx_tamer_ts_time                => CONNECTED_TO_rx_tamer_ts_time,                --                         .ts_time
			rx_trigger_ctl_in_port          => CONNECTED_TO_rx_trigger_ctl_in_port,          --           rx_trigger_ctl.in_port
			rx_trigger_ctl_out_port         => CONNECTED_TO_rx_trigger_ctl_out_port,         --                         .out_port
			shd_state_export                => CONNECTED_TO_shd_state_export,                --                shd_state.export
			spi_sclk                        => CONNECTED_TO_spi_sclk,                        --                      spi.sclk
			spi_miso                        => CONNECTED_TO_spi_miso,                        --                         .miso
			spi_mosi                        => CONNECTED_TO_spi_mosi,                        --                         .mosi
			spi_ss_n                        => CONNECTED_TO_spi_ss_n,                        --                         .ss_n
			tx_tamer_ts_sync_in             => CONNECTED_TO_tx_tamer_ts_sync_in,             --                 tx_tamer.ts_sync_in
			tx_tamer_ts_sync_out            => CONNECTED_TO_tx_tamer_ts_sync_out,            --                         .ts_sync_out
			tx_tamer_ts_pps                 => CONNECTED_TO_tx_tamer_ts_pps,                 --                         .ts_pps
			tx_tamer_ts_clock               => CONNECTED_TO_tx_tamer_ts_clock,               --                         .ts_clock
			tx_tamer_ts_reset               => CONNECTED_TO_tx_tamer_ts_reset,               --                         .ts_reset
			tx_tamer_ts_time                => CONNECTED_TO_tx_tamer_ts_time,                --                         .ts_time
			tx_trigger_ctl_in_port          => CONNECTED_TO_tx_trigger_ctl_in_port,          --           tx_trigger_ctl.in_port
			tx_trigger_ctl_out_port         => CONNECTED_TO_tx_trigger_ctl_out_port,         --                         .out_port
			vctcxo_tamer_tune_ref           => CONNECTED_TO_vctcxo_tamer_tune_ref,           --             vctcxo_tamer.tune_ref
			vctcxo_tamer_vctcxo_clock       => CONNECTED_TO_vctcxo_tamer_vctcxo_clock,       --                         .vctcxo_clock
			xb_gpio_in_port                 => CONNECTED_TO_xb_gpio_in_port,                 --                  xb_gpio.in_port
			xb_gpio_out_port                => CONNECTED_TO_xb_gpio_out_port,                --                         .out_port
			xb_gpio_dir_export              => CONNECTED_TO_xb_gpio_dir_export               --              xb_gpio_dir.export
		);

