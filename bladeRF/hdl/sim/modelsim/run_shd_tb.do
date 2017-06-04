#Create & map work library
vlib work
vmap work work
#Copy memory init files for Altera FFT core into local directory
cp ../../src/altera_fft/fft128/simulation/submodules/fft128_fft_ii_0_1n128cos.hex ./
cp ../../src/altera_fft/fft128/simulation/submodules/fft128_fft_ii_0_1n128sin.hex ./
cp ../../src/altera_fft/fft128/simulation/submodules/fft128_fft_ii_0_2n128cos.hex ./
cp ../../src/altera_fft/fft128/simulation/submodules/fft128_fft_ii_0_2n128sin.hex ./
cp ../../src/altera_fft/fft128/simulation/submodules/fft128_fft_ii_0_3n128cos.hex ./
cp ../../src/altera_fft/fft128/simulation/submodules/fft128_fft_ii_0_3n128sin.hex ./

# Compile Altera-generated files
vcom -explicit -2008 "../../src/altera_fft/fft128/simulation/submodules/fft128_fft_ii_0.vho"
vcom -explicit -2008 "../../src/altera_fft/fft128/simulation/fft128.vhd"
vcom -explicit -2008 "../../src/altera_divider/divider.vhd"
# Compile all other files
vcom -explicit -2008 "../../src/fft_wrapper.vhd"
vcom -explicit -2008 "../../src/calc_power.vhd"
vcom -explicit -2008 "../../src/scale.vhd"
vcom -explicit -2008 "../../src/averager.vhd"
vcom -explicit -2008 "../../src/hole_detector.vhd"
#Compile sources
vcom -explicit -2008 "../../src/shd.vhd"
vcom -explicit -2008 "../../src/shd_control.vhd"
vcom -explicit -2008 "../shd_tb.vhd"

#Call vsim to invoke simulator
vsim -voptargs="+acc" -t 1ps -lib work work.shd_tb
add wave -noupdate /shd_tb/clk
add wave -noupdate /shd_tb/rst
add wave -noupdate /shd_tb/shd_start
add wave -noupdate /shd_tb/in_valid
add wave -noupdate /shd_tb/ctrl_in_valid
add wave -noupdate /shd_tb/shd_state
add wave -analog-step -min -2048 -max 2047 -height 50 -radix decimal /shd_tb/in_real
add wave -analog-step -min -2048 -max 2047 -height 50 -radix decimal /shd_tb/in_imag
add wave -divider
add wave -noupdate -radix decimal /shd_tb/u_shd/fft_out_real
add wave -noupdate -radix decimal /shd_tb/u_shd/fft_out_imag
add wave -noupdate -radix decimal /shd_tb/u_shd/fft_out_exp
add wave -noupdate /shd_tb/u_shd/fft_out_valid
add wave -noupdate -radix unsigned /shd_tb/u_shd/pwr_out_power
add wave -noupdate -radix unsigned /shd_tb/u_shd/sc_out_power
add wave -noupdate /shd_tb/u_shd/sc_out_valid
add wave -divider
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_averager/num_blocks_avgd
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_averager/sum
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_averager/wr_addr
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_averager/word_written
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_averager/rd_addr
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_averager/word_read
add wave -noupdate /shd_tb/u_shd/u_averager/state
add wave -noupdate /shd_tb/u_shd/u_averager/find_min
add wave -noupdate /shd_tb/u_shd/u_averager/send_output
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_averager/out_addr
add wave -noupdate -radix unsigned /shd_tb/u_shd/psd_out
add wave -noupdate -radix unsigned /shd_tb/u_shd/psd_out_min
add wave -noupdate /shd_tb/u_shd/psd_out_valid
add wave -divider
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_hole_detector/SCALE_FACT
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_hole_detector/thresh
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_hole_detector/psd_reg
add wave -noupdate -radix unsigned /shd_tb/u_shd/u_hole_detector/out_psd_regs
add wave -noupdate /shd_tb/u_shd/u_hole_detector/out_hole_regs
add wave -noupdate /shd_tb/u_shd/u_hole_detector/out_valid_regs
add wave -divider
add wave -noupdate /shd_tb/out_hole
add wave -noupdate -radix unsigned /shd_tb/out_hole_rank
add wave -noupdate -radix unsigned /shd_tb/out_psd_approx
add wave -noupdate /shd_tb/out_valid
add wave -analog-step -min -5 -max 45 -height 100 -clampanalog 1 /shd_tb/out_psd_db

#Remove path from signal names
config wave -signalnamewidth 1
#Set waveform units to ns
config wave -timelineunits ns
view wave
run 660 us
wave zoom full
