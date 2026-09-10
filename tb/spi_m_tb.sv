module tb_spi_m ;
logic clk=0,rst_n=0,start=0;
logic [7:0]tx_data=0;
logic [7:0]rx_data;
logic busy,done;
logic cpol=0,cpha=0;
logic [15:0]clk_div = 4;
logic miso =0;
logic cs, sclk, mosi;
spi_m dut(.clk,.rst_n,.start,.tx_data,.rx_data
,.busy,.done,.clk_div,.cpol,.cpha,.cs,.sclk,.mosi,.miso);
always #5 clk = ~clk;

logic [7:0] miso_pattern = 8'b10100101;


task do_tx(input [7:0] data);
    begin
        @(posedge clk);
        tx_data = data;
        start = 1;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        $display("Sent tx_data=0x%0h -> mosi seen, rx_data=0x%0h", data, rx_data);
        @(posedge clk);
    end
endtask

initial begin
    rst_n=0;
    #20 rst_n=1;
        // Mode 0: cpol=0, cpha=0
        cpol = 0; cpha = 0;
        do_tx(8'hC3); // 1100_0011

        // Mode 1: cpol=0, cpha=1
        cpol = 0; cpha = 1;
        do_tx(8'h5A);

        // Mode 2: cpol=1, cpha=0
        cpol = 1; cpha = 0;
        do_tx(8'h3C);

        // Mode 3: cpol=1, cpha=1
        cpol = 1; cpha = 1;
        do_tx(8'hF0);

        $display("All 4 modes done");
        $finish;
end

always @(posedge clk) begin
    if(!cs)begin
        miso<=miso_pattern[7];
    end
end

always @(posedge clk) begin
  $display("t=%0t cpol=%b cpha=%b cs=%b sclk=%b mosi=%b busy=%b done=%b",
                   $time, cpol, cpha, cs, sclk, mosi, busy, done);
end

endmodule