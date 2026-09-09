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
        sclk_reg<=0;
    end
    else begin
        sclk_reg <=~ sclk_reg;
    end
end
assign sclk = sclk_reg;


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
            end
        end 
        busy_state:begin
            if(tick && sclk_reg ==1)
                state<=finish;
        // state<=finish;
        end
        finish:begin
            cs<=1;busy<=0;done<=1;state<=idle;
        end
    endcase
   end
end 
endmodule