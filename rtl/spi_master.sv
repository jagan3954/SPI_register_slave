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
                busy<=1;cs<=0;state<=busy_state;
            end
        end 
        busy_state:begin
            state<=finish;
        end
        finish:begin
            cs<=1;busy<=0;done<=1;state<=idle;
        end
    endcase
   end
end 
endmodule