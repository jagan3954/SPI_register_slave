module tb_spi_m ;
logic clk=0,rst_n=0,start=0;
logic [7:0]tx_data=0;
logic [7:0]rx_data;
logic busy,done;
logic cpol=0,cpha=0;
logic [15:0]clk_div = 4;
logic miso =0;
spi_m dut(.clk,.rst_n,.start,.tx_data,.rx_data
,.busy,.done,.clk_div,.cpol,.cpha,.cs,.sclk,.mosi,.miso);
always #5 clk = ~clk;
initial begin
    rst_n=0;
    #20 rst_n=1;
    @(posedge clk);
    start<=1;
    @(posedge clk);
    start<=0;

    repeat (10) @(posedge clk);
    $display("final state check -> cs=%b busy=%b done=%b",cs,busy,done);
    $finish;
end
always @(posedge clk) begin
    $display("t=%0t rst_n=%b start=%b cs=%b busy=%b done =%b",$time,rst_n,start,cd,busy,done);
end
    
endmodule