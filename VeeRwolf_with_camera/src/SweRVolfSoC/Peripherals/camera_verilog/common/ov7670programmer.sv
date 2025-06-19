module ov7670programmer_v #(
    parameter int FREQ_KHZ,        
    parameter int BAUDRATE,         
    parameter logic [6:0] DEV_ID    
)(
    input  logic clk,               
    output logic rdy,   
    output logic sioc,  
    output logic siod      
);

typedef struct packed {
    logic [7:0] reg_addr;
    logic [7:0] data;
} t_conf;

localparam PROG_LEN = 35;
t_conf confROM [0:PROG_LEN-1] = '{
    '{8'h12, 8'h80},  
    '{8'h12, 8'h04},  
    '{8'h40, 8'hF0},  
    '{8'h8C, 8'h02},    
    '{8'h3C, 8'h00},   
    '{8'h11, 8'h00}, 
    '{8'h6B, 8'h00}, 
    '{8'h3A, 8'h00}, 
    '{8'h1E, 8'h10}, 
    '{8'h4F, 8'hB3}, 
    '{8'h50, 8'hB3}, 
    '{8'h51, 8'h00}, 
    '{8'h52, 8'h3D}, 
    '{8'h53, 8'hA7}, 
    '{8'h54, 8'hE4}, 
    '{8'h58, 8'h9E},
    '{8'h7A, 8'h20},
    '{8'h7B, 8'h10},
    '{8'h7C, 8'h1E}, 
    '{8'h7D, 8'h35},
    '{8'h7E, 8'h5A},
    '{8'h7F, 8'h69},
    '{8'h80, 8'h76},
    '{8'h81, 8'h80},
    '{8'h82, 8'h88},
    '{8'h83, 8'h8F},
    '{8'h84, 8'h96},
    '{8'h85, 8'hA3},
    '{8'h86, 8'hAF},
    '{8'h87, 8'hC4},
    '{8'h88, 8'hD7},
    '{8'h89, 8'hE8},
    '{8'h3D, 8'hC0},
    '{8'h69, 8'h06},
    '{8'hB0, 8'h84}  
};

localparam POWERUP_CYCLES = FREQ_KHZ * 2;  
localparam SWRST_CYCLES = FREQ_KHZ * 1;     
localparam SCK_CYCLES = (FREQ_KHZ * 1000) / BAUDRATE;
localparam QSCK_CYCLES = SCK_CYCLES / 4;

localparam WR = 1'b0;
localparam FRAME_LEN = 27;

typedef enum logic [3:0] {
    INITIAL,
    LOAD_FRAME,
    START1,
    START2,
    WR1,
    WR2,
    WR3,
    WR4,
    END1,
    END2,
    CHECK,
    IDLE
} state_t;

state_t state = INITIAL;
logic [31:0] numCycles;
logic [4:0] bitPos;
logic [26:0] shifter;
logic [5:0] addr;

always_ff @(posedge clk) begin
    if (numCycles != 0) begin
        numCycles <= numCycles - 1;
    end
    else begin
        case (state)
            INITIAL: begin
                state <= LOAD_FRAME;
                numCycles <= SWRST_CYCLES;
                addr <= 0;
                shifter <= '0;
                bitPos <= 0;
            end
            LOAD_FRAME: begin
                shifter <= {DEV_ID, WR, 1'b0, confROM[addr].reg_addr, 1'b0, confROM[addr].data, 1'b0};
                addr <= addr + 1;
                bitPos <= 0;
                state <= START1;
                numCycles <= QSCK_CYCLES;
            end
            
            START1: begin
                state <= START2;
                numCycles <= QSCK_CYCLES;
            end
            
            START2: begin
                state <= WR1;
                numCycles <= QSCK_CYCLES;
            end
            
            WR1: begin
                state <= WR2;
                numCycles <= QSCK_CYCLES;
            end
            
            WR2: begin
                state <= WR3;
                numCycles <= QSCK_CYCLES;
            end
            
            WR3: begin
                state <= WR4;
                numCycles <= QSCK_CYCLES;
            end
            
            WR4: begin
                if (bitPos < FRAME_LEN-1) begin
                    shifter <= {shifter[25:0], 1'b1};
                    bitPos <= bitPos + 1;
                    state <= WR1;
                end
                else begin
                    state <= END1;
                end
                numCycles <= QSCK_CYCLES;
            end
            
            END1: begin
                state <= END2;
                numCycles <= QSCK_CYCLES;
            end
            
            END2: begin
                state <= CHECK;
            end
            
            CHECK: begin
                if (addr < PROG_LEN) begin
                    state <= LOAD_FRAME;
                    numCycles <= SWRST_CYCLES;
                end
                else begin
                    state <= IDLE;
                end
            end
            
            IDLE: begin
                // Maintain idle state
            end
            
            default: state <= INITIAL;
        endcase
    end
end

always_comb begin
    rdy = (state == IDLE);
    {sioc, siod} = 2'b11;  

    case (state)
        INITIAL, CHECK, IDLE, LOAD_FRAME: ;
        
        START1: {sioc, siod} = 2'b10;
        START2: {sioc, siod} = 2'b00;
        
        WR1, WR4: {sioc, siod} = {1'b0, shifter[26]};
        WR2, WR3: {sioc, siod} = {1'b1, shifter[26]};
        
        END1: {sioc, siod} = 2'b00;
        END2: {sioc, siod} = 2'b10;
    endcase
end

endmodule
