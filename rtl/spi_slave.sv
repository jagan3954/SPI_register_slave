module spi_s (
    input logic clk,rst_n,
    input logic cs,
    input logic sclk,
    input logic mosi,
    output logic miso
);

always_ff @( posedge clk or negedge rst_n) begin
    if(!rst_n)
    miso<=0;
    else if(!cs)
        miso<=1'b1;
    else
        miso<=1'b0;
end
endmodule
