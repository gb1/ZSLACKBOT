class ZCL_TEST_RUNNER definition
  public
  final
  create public .

public section.

  interfaces IF_AUNIT_LISTENER .

  methods CONSTRUCTOR
    importing
      !PACKAGE type STRING .
  methods GO
    returning
      value(RESULTS) type ZTTTEST_RESULT .
  protected section.
private section.

  data SERVER_ADDRESS type STRING .
  data TEST_FACTORY type ref to CL_AUNIT_FACTORY .
  data TEST_RESULTS type ZTTTEST_RESULT .
  data CLASS type PROGNAME .
  data PACKAGE type STRING .

  methods READ_SOURCE_CODE
    importing
      !CLASS_NAME type STRING
    returning
      value(SOURCE_CODE) type RSWSOURCET .
  methods SEND_TEST_RESULT
    importing
      !TEST_RESULT type ZTEST_RESULT .
  methods GET_CLASSES_IN_PACKAGE
    importing
      !PACKAGE type STRING
    returning
      value(CLASSES_TO_TEST) type TABLE_OF_STRINGS .
  methods SEND_HTTP_ERROR .
ENDCLASS.



CLASS ZCL_TEST_RUNNER IMPLEMENTATION.


  method constructor.

    me->package = package.

    test_factory = new cl_aunit_factory( ).

  endmethod.


  method GET_CLASSES_IN_PACKAGE.

    select obj_name from tadir as tadir
      inner join seoclassdf as seoclassdf
      on tadir~obj_name = seoclassdf~clsname
      into table @classes_to_test
      where tadir~devclass = @package
      and seoclassdf~with_unit_tests = 'X'.

  endmethod.


  method go.

    data(classes) = get_classes_in_package( me->package ).

    loop at classes into data(class_to_test).

      me->class = class_to_test.

      data(unit_test) = me->test_factory->create_task( me ).
      unit_test->add_class_pool( class ).
      unit_test->run( mode = if_aunit_task=>c_run_mode-external ).

    endloop.

    results = me->test_results.

  endmethod.


  method if_aunit_listener~assert_failure.

    data(desc) = failure->get_header_description( ).

    data: f_text_api type ref to if_aunit_text_description.

    f_text_api = test_factory->get_text_converter( language = 'E' ).

    data(description) = f_text_api->get_string( desc ).

    data(descrip) = failure->get_complete_description( ).


    data: test_result type ztest_result.

    test_result-class = class.
    test_result-description = description.
    test_result-result = 'FAIL'.
    test_result-method = descrip[ 4 ]-params[ 3 ].

    append test_result to test_results.

*    me->send_test_result( test_result ).

  endmethod.


  method IF_AUNIT_LISTENER~CLASS_END.
  endmethod.


  method IF_AUNIT_LISTENER~CLASS_START.
  endmethod.


  method IF_AUNIT_LISTENER~EXECUTION_EVENT.

    data(v) = execution_event->get_complete_description( ).
    data(n) = execution_event->get_header_description( ).


  endmethod.


  method IF_AUNIT_LISTENER~METHOD_END.

    data: test_result type ZTEST_RESULT.
    data(alert) = info->get_alert_summary( ).

    if alert-is_okay = abap_true. "test passed

      data(step) = info->get_step_summary( ).

      data: result type ref to cl_aunit_internal_step_end.
      result ?= info.
      data(description) = result->if_aunit_info_step~get_description( ).
      test_result-method = description-params[ 1 ].
      test_result-result = 'PASS'.
      test_result-class = class.
      append test_result to test_results.

    endif.

  endmethod.


  method IF_AUNIT_LISTENER~METHOD_START.
  endmethod.


  method IF_AUNIT_LISTENER~PROGRAM_END.
  endmethod.


  method IF_AUNIT_LISTENER~PROGRAM_START.
  endmethod.


  method IF_AUNIT_LISTENER~TASK_END.
  endmethod.


  method IF_AUNIT_LISTENER~TASK_START.

    "set up start time and program name here

  endmethod.


  method READ_SOURCE_CODE.

    data class_key type seoclskey.

    class_key-clsname = class_name.

    data(source_reader) = new cl_oo_source( clskey = class_key ).

    source_reader->read( version = 'A' ).

    source_code = source_reader->source.

  endmethod.


  method SEND_HTTP_ERROR.
  endmethod.


  method SEND_TEST_RESULT.

    cl_http_client=>create_by_url(
      exporting
        url           = 'http://192.168.33.1:4000'
      importing
        client        = data(http_client) ).


    data(json) = /ui2/cl_json=>serialize( data = test_result
                                          compress = abap_true
                                          pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    http_client->request->set_method( 'POST' ).
    http_client->request->set_content_type( 'application/json' ).
    http_client->request->set_cdata( json ).

    http_client->send( ).

    http_client->receive(
    exceptions
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      others                     = 4
  ).

    http_client->close( ).

  endmethod.
ENDCLASS.
