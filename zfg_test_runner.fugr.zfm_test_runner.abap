function zfm_test_runner.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(PACKAGE) TYPE  STRING
*"  TABLES
*"      RESULTS STRUCTURE  ZTEST_RESULT
*"----------------------------------------------------------------------

  data: lt_res type ztttest_result,
        ls_res type ztest_result.

  data(test_runner) = new zcl_test_runner( package ).
  lt_res = test_runner->go( ).

  loop at lt_res into ls_res.
    append ls_res to results.
  endloop.

endfunction.