`include "../lc3_mem_path.svh"

class lc3_checker;
  // Golden bubble sort (signed compare)
  function automatic void bubble_sort_ref(ref bit [15:0] a[]);
    for (int i=0;i<a.size()-1;i++)
      for (int j=0;j<a.size()-1-i;j++)
        if ($signed(a[j]) > $signed(a[j+1])) begin
          bit [15:0] t = a[j]; 
			 a[j] = a[j+1]; 
			 a[j+1] = t;
        end
  endfunction

  // ---------- pretty printer ----------
  task print_array(string tag, bit [15:0] a[]);
  $display("[CHK] %s (N=%0d):", tag, a.size());
  for (int i = 0; i < a.size(); i++) begin
    // show signed decimal and hex per line
    $display("  idx %0d : %0d (0x%04h)", i, $signed(a[i]), a[i]);
  end
endtask


  // Read back from DUT memory and compare
  task compare_array(bit [15:0] base, int N);
    bit [15:0] got[]; 
    bit [15:0] exp[];
    int mism = 0;

    got = new[N];
    for (int i=0;i<N;i++) begin
      got[i] = `LC3_MEM(base + i);
    end

    //if (orig.size() == N) print_array("UNSORTED (from generator)", orig);
    

    exp = got;
    bubble_sort_ref(exp);

  print_array("SORTED Array (memory after sort)", exp);
    for (int i=0;i<N;i++)begin 
	if (got[i] != exp[i]) begin
      	   $display("[CHK] MISM i=%0d got= %0d exp= %0d", i, $signed(got[i]), $signed(exp[i])); 
	   mism++;
	end
    end
    if (mism==0) $display("[CHK] PASS: array sorted.");
    else         $fatal(1, "[CHK] FAIL: %0d mismatches", mism);
  endtask
endclass
