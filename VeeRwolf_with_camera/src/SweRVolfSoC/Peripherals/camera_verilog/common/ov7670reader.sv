module ov7670reader_v (
    input  logic        clk,  
    input  logic        rec, 
    
    output logic [8:0]  y,        
    output logic [9:0]  x,        
    output logic        dataRdy,  
    output logic [11:0] data,  
    output logic        frameRdy, 
    
    input  logic        pclk,  
    input  logic        cvSync, 
    input  logic        href, 
    input  logic [7:0]  cData  
);

logic [7:0] cDataD;
logic hrefD, pclkRise, cvSyncRise;

localparam BYTE_CNT_MOD = 2*640;
localparam LINE_CNT_MOD = 480;

logic [8:0] delay_reg = '0;

edgeDetector #(.XPOL(0)) pclkEdge (
    .clk(clk),
    .x(pclk),
    .xFall(),
    .xRise(pclkRise)
);

edgeDetector #(.XPOL(0)) vsyncEdge (
    .clk(clk),
    .x(cvSync),
    .xFall(),
    .xRise(cvSyncRise)
);

always_ff @(posedge clk) begin
    {hrefD, cDataD} <= delay_reg;
    delay_reg <= {href, cData};
end

assign frameRdy = cvSyncRise && rec;


logic [3:0]  nibble = '0;
logic [10:0] byteCnt = '0;
logic [8:0]  lineCnt = '0;

always_ff @(posedge clk) begin
    if (cvSyncRise && rec) begin
        byteCnt <= '0;
        lineCnt <= '0;
        nibble  <= '0;
    end
    else if (rec && pclkRise && hrefD) begin
        byteCnt <= (byteCnt == BYTE_CNT_MOD-1) ? '0 : byteCnt + 1;
        
        nibble <= cDataD[3:0];
        
        if (byteCnt == BYTE_CNT_MOD-1) begin
            lineCnt <= (lineCnt == LINE_CNT_MOD-1) ? '0 : lineCnt + 1;
        end
    end
end

assign data = {nibble, cDataD};
assign x = byteCnt[10:1]; 
assign y = lineCnt;
assign dataRdy = rec && pclkRise && hrefD && byteCnt[0];

endmodule


module edgeDetector #(
    parameter XPOL = 0
)(
    input  logic clk,
    input  logic x,
    output logic xFall,
    output logic xRise
);

logic [1:0] sync_reg = '0;

always_ff @(posedge clk)
    sync_reg <= {sync_reg[0], x};

assign xRise = (XPOL ? ~sync_reg[1] && sync_reg[0] 
                   : sync_reg[1] && ~sync_reg[0]);
assign xFall = (XPOL ? sync_reg[1] && ~sync_reg[0] 
                   : ~sync_reg[1] && sync_reg[0]);

endmodule
