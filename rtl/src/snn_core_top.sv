`timescale 1ns / 1ps
module snn_core_top
#(
    parameter C_S_AXI_ACLK_FREQ_HZ = 100000000,
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 16,
    parameter THRESH=15,
    parameter RESET=0,
    parameter REFRAC=5,
    parameter WEIGHT_SIZE=32,
    parameter NUM_INPUTS=4,
    parameter NUM_LAYERS=1,
    parameter [31 : 0] NUM_HIDDEN_LAYER_NEURONS [NUM_LAYERS - 1 : 0] = {32'h1}
)
(
    // axi_cfg_regs
    input S_AXI_ACLK,   
    input S_AXI_ARESETN,
    input [C_S_AXI_ADDR_WIDTH - 1:0] S_AXI_AWADDR, 
    input S_AXI_AWVALID,
    input [C_S_AXI_ADDR_WIDTH - 1:0] S_AXI_ARADDR, 
    input S_AXI_ARVALID,
    input [C_S_AXI_DATA_WIDTH - 1:0] S_AXI_WDATA,  
    input [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,  
    input S_AXI_WVALID, 
    input S_AXI_RREADY, 
    input S_AXI_BREADY, 

    output S_AXI_AWREADY, 
    output S_AXI_ARREADY, 
    output S_AXI_WREADY,  
    output [C_S_AXI_DATA_WIDTH - 1:0] S_AXI_RDATA,
    output [1:0] S_AXI_RRESP,
    output S_AXI_RVALID,  
    output [1:0] S_AXI_BRESP,
    output S_AXI_BVALID    
);

localparam NUM_OUTPUTS = NUM_HIDDEN_LAYER_NEURONS[NUM_LAYERS - 1];


wire rst;

assign rst = ~S_AXI_ARESETN;

wire [31:0] debug;
wire [31:0] ctrl;

wire [NUM_INPUTS - 1:0] spike_in;
wire [NUM_OUTPUTS - 1:0] spike_out;

wire [31 : 0] ext_mem_addr;
wire ext_mem_wen;
wire [31 : 0] ext_mem_data_in;
wire [31 : 0] ext_mem_data_out;
wire [1 : 0] ext_mem_sel;

wire [31 : 0] spike_gen_mem_addr;
wire spike_gen_mem_wen;
wire [31 : 0] spike_gen_mem_data_in;
wire [31 : 0] spike_gen_mem_data_out;

wire [31 : 0] synpase_weight_mem_addr;
wire synpase_weight_mem_wen;
wire [31 : 0] synpase_weight_mem_data_in;
wire [31 : 0] synpase_weight_mem_data_out;

wire [31:0] sim_time;

wire [31 : 0] spike_counter_out [NUM_OUTPUTS - 1 : 0];

wire network_rst;

wire network_en;

wire network_done;

assign spike_gen_mem_addr = ext_mem_addr;
assign spike_gen_mem_wen = (ext_mem_sel == 2'h0) ? ext_mem_wen : 0;
assign spike_gen_mem_data_in = ext_mem_data_in;

assign synpase_weight_mem_addr = ext_mem_addr;
assign synpase_weight_mem_wen = (ext_mem_sel == 2'h1) ? ext_mem_wen : 0;
assign synpase_weight_mem_data_in = ext_mem_data_in;

assign ext_mem_data_out = (ext_mem_sel == 2'h0) ? spike_gen_mem_data_out : synpase_weight_mem_data_out;



axi_cfg_regs 
#(
    .C_S_AXI_ACLK_FREQ_HZ(C_S_AXI_ACLK_FREQ_HZ),
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
    .NUM_OUTPUTS(NUM_OUTPUTS)
)
axi_cfg_regs
(
    // Debug Register Output
    .debug(debug),
    // Control Register Output
    .ctrl(ctrl),
    // Simulation Time Register
    .sim_time(sim_time),
    // Spike Counter Registers
    .spike_counter_out(spike_counter_out),
    // Network Done Signal
    .network_done(network_done),
    // Network Busy Signal
    .network_busy(network_en),
    // Spike Generator RAM Signals
    .ext_mem_addr(ext_mem_addr),
    .ext_mem_wen(ext_mem_wen),
    .ext_mem_data_in(ext_mem_data_in),
    .ext_mem_data_out(ext_mem_data_out),
    .ext_mem_sel(ext_mem_sel),
    //AXI Signals
    .S_AXI_ACLK(S_AXI_ACLK),     
    .S_AXI_ARESETN(S_AXI_ARESETN),  
    .S_AXI_AWADDR(S_AXI_AWADDR),   
    .S_AXI_AWVALID(S_AXI_AWVALID),  
    .S_AXI_AWREADY(S_AXI_AWREADY),  
    .S_AXI_ARADDR(S_AXI_ARADDR),   
    .S_AXI_ARVALID(S_AXI_ARVALID),  
    .S_AXI_ARREADY(S_AXI_ARREADY),  
    .S_AXI_WDATA(S_AXI_WDATA),    
    .S_AXI_WSTRB(S_AXI_WSTRB),    
    .S_AXI_WVALID(S_AXI_WVALID),   
    .S_AXI_WREADY(S_AXI_WREADY),   
    .S_AXI_RDATA(S_AXI_RDATA),    
    .S_AXI_RRESP(S_AXI_RRESP),    
    .S_AXI_RVALID(S_AXI_RVALID),   
    .S_AXI_RREADY(S_AXI_RREADY),   
    .S_AXI_BRESP(S_AXI_BRESP),    
    .S_AXI_BVALID(S_AXI_BVALID),   
    .S_AXI_BREADY(S_AXI_BREADY)   
);

// binary_spike_gen
// #(
//     .NUM_OUTPUTS(NUM_INPUTS),
//     .SPIKE_PERIOD(1)
// )
// binary_spike_gen
// (
//     .clk(S_AXI_ACLK),
//     .rst(rst),
//     .spike_en(debug[NUM_INPUTS - 1 : 0]),
//     .spike_out(spike_in)
// );


assign network_rst = ctrl[0] || rst;

if_network
#(
    .THRESH(THRESH),
    .RESET(RESET),
    .REFRAC(REFRAC),
    .WEIGHT_SIZE(WEIGHT_SIZE),
    .NUM_INPUTS(NUM_INPUTS),
    .NUM_LAYERS(NUM_LAYERS),
    .NUM_HIDDEN_LAYER_NEURONS(NUM_HIDDEN_LAYER_NEURONS)
)
if_network
(
    .clk(S_AXI_ACLK),
    .rst(network_rst),
    .spike_in(spike_in),
    .spike_out(spike_out),
    .mem_addr(synpase_weight_mem_addr),
    .mem_din(synpase_weight_mem_data_in),
    .mem_wen(synpase_weight_mem_wen),
    .mem_dout(synpase_weight_mem_data_out)
);




spike_counter
#(
    .NUM_INPUTS(NUM_OUTPUTS),
    .COUNTER_SIZE(32)
)
spike_counter
(
    .spike_in(spike_out),
    .rst(network_rst),
    .counter_out(spike_counter_out)
);


bernoulli_spike_generator
# (
    .NUM_SPIKES(NUM_INPUTS),
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
)
spike_generator
(
    .clk(S_AXI_ACLK),
    .rst(rst),
    .en(network_en),
    .mem_addr(spike_gen_mem_addr),
    .mem_wen(spike_gen_mem_wen),
    .mem_data_in(spike_gen_mem_data_in),
    .mem_data_out(spike_gen_mem_data_out),
    .spikes(spike_in)
);

wire [31:0] sim_time_cntr_out;

counter 
#(
    .DATA_WIDTH(32)
)
sim_time_cntr (
    .clk(S_AXI_ACLK),
    .rst(network_rst),
    .en(network_en),
    .dout(sim_time_cntr_out)
);

assign network_en = (sim_time_cntr_out < sim_time);

assign network_done = (sim_time_cntr_out == sim_time);

endmodule