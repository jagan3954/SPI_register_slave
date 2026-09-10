module spi_s (
    input  logic clk, rst_n,

    input  logic cs,
    input  logic sclk,
    input  logic mosi,
    output logic miso,

    input  logic cpol, cpha
);

    // ---- memory-mapped registers ----
    logic [7:0] device_id_reg;
    logic [7:0] control_reg;
    logic [7:0] status_reg;
    logic [7:0] data_reg;

    initial device_id_reg = 8'hA5;   // fixed, read-only

    // ---- sync sclk into clk domain (sclk comes from another module/domain) ----
    logic sclk_d0, sclk_d1;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_d0 <= 0;
            sclk_d1 <= 0;
        end else begin
            sclk_d0 <= sclk;
            sclk_d1 <= sclk_d0;
        end
    end

    // ---- edge detection, same trick as master ----
    logic edge_now;
    logic leading_edge, trailing_edge, sample_edge, shift_edge;

    assign edge_now      = (sclk_d0 != sclk_d1);
    assign leading_edge  = edge_now && (sclk_d0 != cpol); // just left idle level
    assign trailing_edge = edge_now && (sclk_d0 == cpol); // just returned to idle level

    assign sample_edge = cpha ? trailing_edge : leading_edge;
    assign shift_edge  = cpha ? leading_edge  : trailing_edge;

    // ---- shift regs + protocol state ----
    logic [7:0] rx_shift, tx_shift;
    logic [3:0] bit_count;
    logic       cmd_done;
    logic       rw_bit;
    logic [2:0] addr_field;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count   <= 0;
            rx_shift    <= 0;
            tx_shift    <= 0;
            cmd_done    <= 0;
            rw_bit      <= 0;
            addr_field  <= 0;
            control_reg <= 0;
            status_reg  <= 0;
            data_reg    <= 0;
        end
        else if (cs) begin
            // deselected -> reset per-transaction state, keep register contents
            bit_count <= 0;
            cmd_done  <= 0;
        end
        else begin
            if (sample_edge) begin
                logic [7:0] next_rx;
                next_rx  = {rx_shift[6:0], mosi};
                rx_shift <= next_rx;

                if (bit_count == 7) begin
                    bit_count <= 0;

                    if (!cmd_done) begin
                        // command byte just finished
                        rw_bit     <= next_rx[7];
                        addr_field <= next_rx[6:4];
                        cmd_done   <= 1;

                        // preload tx_shift now, in case master wants to read
                        case (next_rx[6:4])
                            3'd0: tx_shift <= device_id_reg;
                            3'd1: tx_shift <= control_reg;
                            3'd2: tx_shift <= status_reg;
                            3'd3: tx_shift <= data_reg;
                            default: tx_shift <= 8'h00;
                        endcase
                    end
                    else begin
                        // data byte just finished -> write, only if rw_bit says write
                        if (!rw_bit) begin
                            case (addr_field)
                                3'd1: control_reg <= next_rx;
                                3'd3: data_reg    <= next_rx;
                                default: ; // device_id, status: read-only
                            endcase
                        end
                    end
                end
                else begin
                    bit_count <= bit_count + 1;
                end
            end

            if (shift_edge && cmd_done) begin
                tx_shift <= {tx_shift[6:0], 1'b0};
            end
        end
    end

    assign miso = tx_shift[7];

endmodule