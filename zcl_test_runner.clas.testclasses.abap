class tests definition deferred.
class zcl_test_runner definition local friends tests.

class tests definition for testing
  duration short
  risk level harmless
.
  private section.
    data:
      f_cut type ref to zcl_test_runner.  "class under test

    class-methods: class_setup.
    class-methods: class_teardown.
    methods: setup.
    methods: teardown.
    methods: go for testing.
    methods: send_test_result for testing.
    methods: get_classes_in_package for testing.
    methods: read_source_code for testing.
    methods: read_test_class_source for testing.
endclass.       "tests


class tests implementation.

  method class_setup.



  endmethod.


  method class_teardown.



  endmethod.


  method setup.

    f_cut = new zcl_test_runner( 'ZCT' ).
  endmethod.


  method teardown.



  endmethod.

  method go.
    f_cut->go( ).
  endmethod.


  method send_test_result.

*    data: test_result type zcl_pilchard=>test_result.
*
*    test_result-class = 'class'.
*    test_result-description = 'fails'.
*
*    f_cut->send_test_result( test_result ).

  endmethod.

  method get_classes_in_package.
*
*    data(classes_to_test) = f_cut->get_classes_in_package( 'ZPILCHARD' ).
*
*    cl_abap_unit_assert=>assert_not_initial( classes_to_test ).
*

  endmethod.

  method read_source_code.

    data(source) = f_cut->read_source_code( 'ZCL_CT_DEMO' ).

    cl_abap_unit_assert=>assert_not_initial( source ).

  endmethod.

  method read_test_class_source.


  endmethod.


endclass.