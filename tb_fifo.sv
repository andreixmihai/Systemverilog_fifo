module tb_fifo;

  localparam int WIDTH = 8;
  localparam int DEPTH = 16;

  logic clk = 0;
  logic rst_n;

  logic wr_en;
  logic [WIDTH-1:0] wr_data;
  logic full;

  logic rd_en;
  logic [WIDTH-1:0] rd_data;
  logic empty;

  fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk, .rst_n,
    .wr_en, .wr_data, .full,
    .rd_en, .rd_data, .empty
  );

  // clock
  always #5 clk = ~clk;

  // scoreboard
  byte q[$];

  task do_write(input byte v);
    @(negedge clk);
    wr_en   <= 1;
    wr_data <= v;
    rd_en   <= 0;
    @(negedge clk);
    wr_en   <= 0;

    if (!full) q.push_back(v);
  endtask

  task do_read();
    byte exp;
    @(negedge clk);
    rd_en <= 1;
    wr_en <= 0;
    @(negedge clk);
    rd_en <= 0;

    if (!empty) begin
      exp = q.pop_front();
      // rd_data e combinational din mem[rptr], verificăm după un tick
      if (rd_data !== exp) begin
        $display("ERROR: expected %0d got %0d at time %0t", exp, rd_data, $time);
        $fatal;
      end
    end
  endtask

  initial begin
    // init
    wr_en = 0; rd_en = 0; wr_data = '0;
    rst_n = 0;
    repeat (3) @(negedge clk);
    rst_n = 1;

    // write DEPTH items
    for (int i = 0; i < DEPTH; i++) begin
      do_write(byte'(i));
    end

    // try one extra write (should be blocked)
    do_write(8'hAA);

    // read all
    for (int i = 0; i < DEPTH; i++) begin
      do_read();
    end

    // try extra read (should be blocked)
    do_read();

    // mixed ops
    for (int i = 0; i < 20; i++) begin
      do_write(byte'($urandom_range(0,255)));
      if ($urandom_range(0,1)) do_read();
    end

    // drain
    while (q.size() > 0) do_read();

    $display("PASS ✅");
    $finish;
  end

endmodule
