module tb_spi_top;

    logic clk = 0, rst_n = 0;
    logic start = 0;
    logic [15:0] tx_data = 0;      // now 16 bits
    logic [15:0] rx_data;          // now 16 bits
    logic busy, done;
    logic cpol = 0, cpha = 0;
    logic [15:0] clk_div = 4;
    logic cs, sclk, mosi, miso;

    spi_m #(.wid(16)) master_dut (   // <-- override wid to 16
        .clk, .rst_n, .start, .tx_data, .rx_data,
        .busy, .done, .clk_div, .cpol, .cpha,
        .cs, .sclk, .mosi, .miso
    );

    spi_s slave_dut (                // slave is unchanged, still 8-bit internally
        .clk, .rst_n,
        .cs, .sclk, .mosi, .miso,
        .cpol, .cpha
    );

    always #5 clk = ~clk;

    task do_tx(input [15:0] data);
        begin
            @(posedge clk);
            tx_data = data;
            start   = 1;
            @(posedge clk);
            start   = 0;
            wait(done == 1);
            @(posedge clk);
        end
    endtask

    initial begin
        rst_n = 0;
        #20 rst_n = 1;
        cpol = 0; cpha = 0;

        // WRITE 0x3C to control_reg (addr=1): command=0x10, data=0x3C, ONE transfer
        do_tx({8'h10, 8'h3C});
        $display("Wrote 0x3C to control_reg");

        // READ control_reg back: command=0x90, dummy=0x00, ONE transfer
        do_tx({8'h90, 8'h00});
        $display("Read back control_reg = 0x%0h (expect 0x3C)", rx_data[7:0]);
        if (rx_data[7:0] == 8'h3C)
            $display("PASS: write+read-back matched");
        else
            $display("FAIL: expected 0x3C, got 0x%0h", rx_data[7:0]);

        // READ device_id_reg: command=0x80, dummy=0x00
        do_tx({8'h80, 8'h00});
        $display("Read device_id_reg = 0x%0h (expect 0xA5)", rx_data[7:0]);
        if (rx_data[7:0] == 8'hA5)
            $display("PASS: device_id correct");
        else
            $display("FAIL: expected 0xA5, got 0x%0h", rx_data[7:0]);

        $display("All tests done.");
        $finish;
    end

    always @(posedge clk) begin
        $display("t=%0t cs=%b sclk=%b mosi=%b miso=%b busy=%b done=%b",
                   $time, cs, sclk, mosi, miso, busy, done);
    end

endmodule