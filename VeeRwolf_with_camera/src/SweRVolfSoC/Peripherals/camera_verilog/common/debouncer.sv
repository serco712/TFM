module debouncer_v #(
    parameter FREQ_KHZ,    
    parameter BOUNCE_MS,   
    parameter XPOL         
)(
    input clk,         
    input rst,           
    input x,          
    output reg xDeb    
);

localparam CYCLES = FREQ_KHZ * BOUNCE_MS;
localparam CNT_WIDTH = $clog2(CYCLES);

reg [CNT_WIDTH-1:0] count;
wire timerEnd = (count == 0);
reg startTimer;

localparam [1:0] 
    WAITING_DOWN = 2'b00,
    DEBOUNCING_DOWN = 2'b01,
    WAITING_UP = 2'b10,
    DEBOUNCING_UP = 2'b11;

reg [1:0] state, next_state;

always @(posedge clk) begin
    if (rst) begin
        count <= 0;
    end else begin
        if (startTimer)
            count <= CYCLES - 1;
        else if (!timerEnd)
            count <= count - 1;
    end
end

always @(posedge clk) begin
    if (rst)
        state <= WAITING_DOWN;
    else
        state <= next_state;
end

always @(*) begin
    next_state = state;
    case (state)
        WAITING_DOWN: 
            if (x == !XPOL) 
                next_state = DEBOUNCING_DOWN;
        
        DEBOUNCING_DOWN: 
            if (timerEnd)
                next_state = WAITING_UP;
        
        WAITING_UP: 
            if (x == XPOL)
                next_state = DEBOUNCING_UP;
        
        DEBOUNCING_UP: 
            if (timerEnd)
                next_state = WAITING_DOWN;
        
        default: next_state = WAITING_DOWN;
    endcase
end

always @(*) begin
    xDeb = XPOL;           
    startTimer = 1'b0;
    
    case (state)
        WAITING_DOWN: 
            if (x == !XPOL)
                startTimer = 1'b1;
        
        DEBOUNCING_DOWN: 
            xDeb = !XPOL;
        
        WAITING_UP: begin
            xDeb = !XPOL;
            if (x == XPOL)
                startTimer = 1'b1;
        end
        
        DEBOUNCING_UP: ;    
    endcase
end

endmodule
