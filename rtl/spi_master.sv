module spi_m #(
    parameter wid = 8
) (
    input logic clk,rst_n,start,
    input logic [wid-1:0]tx_data,
    output logic [wid-1:0]rx_data,
    output logic busy,done,

    input logic [15:0]clk_div,
    input logic cpol,cpha,

    output logic cs,sclk,mosi,
    input logic miso
);
typedef enum logic [1:0]{idle,busy_state,finish } state_t;
state_t state;

// clk divider sig
logic [15:0] div_cnt;
logic tick,sclk_reg;
 
//shiftreg+bit counter
logic [wid-1:0]tx_shift,rx_shift;
logic [3:0]bit_count;

//signals f0r edge
logic leading_edge,trailing_edge,sample_edge,shift_edge;

//divider block
always_ff @( posedge clk or negedge rst_n ) begin
    if (!rst_n) begin
        div_cnt<=0;tick<=0;
    end
    else if(state==busy_state)begin
        if(div_cnt==clk_div)begin
            div_cnt<=0;
            tick<=1;
        end
        else begin
            div_cnt<=div_cnt+1;tick<=0;
        end
    end
    else begin
            div_cnt<=0;tick<=0;
        end
end

//sclk toggle block
always_ff @(posedge clk or negedge rst_n ) begin
    if (!rst_n) begin
        sclk_reg<=0;
    end
    else if(state ==idle)begin
        //sclk_reg<=0;
        sclk_reg<=cpol;
    end
    else begin
        sclk_reg <=~ sclk_reg;
    end
end
assign sclk = sclk_reg;

//trailing_edge: SCLK BACK to idle level
assign leading_edge  = tick && (sclk_reg == cpol);
assign trailing_edge = tick && (sclk_reg != cpol);

//cpha picks sampling or shifting
assign sample_edge = cpha ? trailing_edge : leading_edge;
assign shift_edge  = cpha ? leading_edge  : trailing_edge;


always_ff @( posedge clk or negedge rst_n  ) begin
   if(!rst_n) begin
    state<=idle;
    cs<=1;
    busy<=0;
    done<=0;
   end 
   else begin
    done<=0;
    case (state)
        idle:begin
            cs<=1;
            if(start)begin
               busy<=1;cs<=0;
               state<=busy_state;
               tx_shift<=tx_data;
               bit_count<=0;
            end
        end 
        busy_state:begin
     //testing   //     if(tick && sclk_reg ==1)
        //         state<=finish;
        // // state<=finish;
        // end
            if(shift_edge)
            tx_shift<={tx_shift[wid-2:0],1'b0}; //msb 1st
        
            if(sample_edge)begin
                rx_shift<={rx_shift[wid-2:0],miso};
                bit_count <=bit_count+1;
                if(bit_count == wid-1)
                state<=finish;
            end
        end
        finish:begin
            cs<=1;busy<=0;done<=1;state<=idle;
            rx_data<=rx_shift;
        end
    endcase
   end
end 
assign mosi = tx_shift[wid-1];
endmodule