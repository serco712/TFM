module camera_top (
        input  logic         i_wb_clk,
        input  logic         i_wb_rst,
        input  logic         i_cam_btn,
       
        output logic         hSync,
        output logic         vSync,
        output logic [11:0]  RGB,
        
        input  logic         ext_pclk_i,
        output logic         ext_xclk_o,
        input  logic         ext_cvsync_i,
        input  logic         ext_href_i,
        input  logic [7:0]   ext_cdata_i,
        output logic         ext_sioc_o,
        output logic         ext_siod_o,
        output logic         ext_pwdn_o,
        output logic         ext_rstn_o,
      
        input  logic [7:0]  i_wb_adr,
        input  logic [31:0]  i_wb_dat,
        input  logic         i_wb_sel,
        input  logic         i_wb_we,
        input  logic         i_wb_cyc,
        input  logic         i_wb_stb,
        output logic [31:0]  o_wb_rdt,
        output logic         o_wb_ack
    );
    
    localparam FREQ_KHZ = 50_000; 
    localparam VGA_KHZ  = 25_000; 
    localparam FREQ_DIV = FREQ_KHZ/VGA_KHZ;
    localparam BOUNCE_MS = 50;    
    localparam BAUDRATE = 400_000;
    
    
    logic cctvOnSync, progRdy, rec, xclkRdy;
    logic [0:0] wea;
    logic [16:0] wrAddr, rdAddr;
    logic [11:0] wrData, rdData, wb_rd_data;
    logic [8:0]  wrY, rdY;
    logic [9:0]  rdYaux;
    logic [9:0]  wrX, rdX;
    
    assign ext_rstn_o = 1'b1;
    assign ext_pwdn_o = 1'b0;
    
    reg [11:0] rdata_o;
    reg [16:0] raddr_i;
    reg        rcam_i;
    
    
    reg frame_captured;
    
    wire rdata_sel;
    wire raddr_sel;
    wire rcam_sel;
    wire rcam_end_sel;
    wire rd_addr_cam;
    wire wb_ack;
    
    
    assign wb_ack = i_wb_cyc & i_wb_stb;
    
    
    always @(posedge i_wb_clk or posedge i_wb_rst)
        if (i_wb_rst)
            o_wb_ack <= #1 1'b0;
        else
            o_wb_ack <= #1 wb_ack & ~o_wb_ack ;
    
    assign rdata_sel = i_wb_cyc & i_wb_stb & (i_wb_adr[5:2] == 4'h1);
    assign raddr_sel = i_wb_cyc & i_wb_stb & (i_wb_adr[5:2] == 4'h2);
    assign rcam_sel = i_wb_cyc & i_wb_stb & (i_wb_adr[5:2] == 4'h4);
    
    always @(posedge i_wb_clk or posedge i_wb_rst)
        if (i_wb_rst)
            raddr_i <= #1 17'b0;
        else if (raddr_sel)
            raddr_i <= #1 i_wb_dat[16:0];
            
    always @(posedge i_wb_clk or posedge i_wb_rst)
        if (i_wb_rst)
            rdata_o <= #1 12'b0;
        else 
            rdata_o <= #1 wb_rd_data;
        
            
            
    always @(posedge i_wb_clk or posedge i_wb_rst)
        if (i_wb_rst)
            o_wb_rdt <= #1 32'b0;
        else if (rdata_sel)
            o_wb_rdt <= #1 {20'b0, rdata_o};
        else if (rcam_sel)
            o_wb_rdt <= #1 {28'b0, 3'h7, rcam_i};
            
    always @(posedge i_wb_clk or posedge i_wb_rst)
        if (i_wb_rst)
            rcam_i <= 1'b0;
        else if (rcam_sel && i_wb_we)
        begin
            if ( i_wb_sel == 1'b1 )
                rcam_i <= i_wb_dat[0];
        end
        else if (wrX == 639 && wrY == 479)
            rcam_i <= 1'b0;


    clk_wiz_25 xclkGenerator (
        .clk_in1(i_wb_clk),
        .locked(xclkRdy),
        .clk_out1(ext_xclk_o)
    );
    
    debouncer_v #(
        .FREQ_KHZ(FREQ_KHZ),
        .BOUNCE_MS(BOUNCE_MS),
        .XPOL(1'b0)
    ) cctvon_debouncer (
        .clk(i_wb_clk),
        .rst(1'b0),
        .x(i_cam_btn),
        .xDeb(cctvOnSync)
    );
    
    ov7670programmer_v #(
        .FREQ_KHZ(FREQ_KHZ),
        .BAUDRATE(BAUDRATE),
        .DEV_ID(7'b0100001)
    ) programmer (
        .clk(i_wb_clk),
        .rdy(progRdy),
        .sioc(ext_sioc_o),
        .siod(ext_siod_o)
    );
    
    assign rec = progRdy && xclkRdy && (rcam_i || cctvOnSync);
    
    ov7670reader_v videoIn (
        .clk(i_wb_clk),
        .rec(rec),
        .x(wrX),
        .y(wrY),
        .dataRdy(wea[0]),
        .data(wrData),
        .frameRdy(frame_captured),
        .pclk(ext_pclk_i),
        .cvSync(ext_cvsync_i),
        .href(ext_href_i),
        .cData(ext_cdata_i)
    );
    
    multAdd wrAddrCalculator (
        .A(wrY[8:1]),
        .B(9'd320),
        .C({1'b0, wrX[9:1]}),
        .SUBTRACT(1'b0),
        .P(wrAddr),
        .PCOUT()
    );
    
    multAdd rdAddrCalculator (
        .A(rdY[8:1]),
        .B(9'd320),
        .C({1'b0, rdX[9:1]}), 
        .SUBTRACT(1'b0),
        .P(rdAddr),
        .PCOUT()
    );
    
    frameBuffer videoInMemory1 (
        .clka(i_wb_clk),
        .wea(wea),
        .addra(wrAddr),
        .dina(wrData),
        .clkb(i_wb_clk),
        .addrb(raddr_i),
        .doutb(wb_rd_data)
    );
    
    
    
    frameBuffer videoInMemory2 (
        .clka(i_wb_clk),
        .wea(wea),
        .addra(wrAddr),
        .dina(wrData),
        .clkb(i_wb_clk),
        .addrb(rdAddr),
        .doutb(rdData)
    );
    
    vgaRefresher #(
        .FREQ_DIV(FREQ_DIV)
    ) videoOut (
        .clk(i_wb_clk),
        .line(rdYaux),
        .pixel(rdX),
        .R(rdData[11:8]),
        .G(rdData[7:4]),
        .B(rdData[3:0]),
        .hSync(hSync),
        .vSync(vSync),
        .RGB(RGB)
    );
    
    assign rdY = rdYaux[8:0];

endmodule
