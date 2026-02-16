module fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16
) (
  input  logic               clk,
  input  logic               rst_n,

  input  logic               wr_en,
  input  logic [WIDTH-1:0]   wr_data,
  output logic               full,

  input  logic               rd_en,
  output logic [WIDTH-1:0]   rd_data,
  output logic               empty
);

  localparam int ADDR_W = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_W:0]  wptr, rptr;     // +1 bit pentru full/empty
  logic [ADDR_W:0]  count;

  assign full  = (count == DEPTH);
  assign empty = (count == 0);

  // read data combinational (simplu)
  assign rd_data = mem[rptr[ADDR_W-1:0]];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr  <= '0;
      rptr  <= '0;
      count <= '0;
    end else begin
      // write
      if (wr_en && !full) begin
        mem[wptr[ADDR_W-1:0]] <= wr_data;
        wptr <= wptr + 1;
      end

      // read
      if (rd_en && !empty) begin
        rptr <= rptr + 1;
      end

      // update count (tratăm cazurile simultane)
      unique case ({(wr_en && !full), (rd_en && !empty)})
        2'b10: count <= count + 1;
        2'b01: count <= count - 1;
        default: count <= count; // 00 sau 11
      endcase
    end
  end

endmodule
