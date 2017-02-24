class tests definition deferred.
class zcl_slackbot definition local friends tests.

class tests definition for testing
  duration short
  risk level harmless
.
  private section.
    data:
      f_cut type ref to zcl_slackbot.  "class under test

    class-methods: class_setup.
    class-methods: class_teardown.
    methods: setup.
    methods: teardown.
    methods: connect for testing.
    methods: connect_to_ws for testing.
    methods: is_message for testing.
    methods: health_check for testing.
endclass.       "tests

class tests implementation.

  method class_setup.
  endmethod.

  method class_teardown.
  endmethod.

  method setup.
    create object f_cut.
  endmethod.

  method teardown.
  endmethod.

  method connect.

*    cl_abap_unit_assert=>assert_not_initial(
*    act = f_cut->connect( )
*    msg = 'we should be able to connect to the Slack RTM api and get a WS url back' ).

  endmethod.

  method connect_to_ws.
    f_cut->connect_to_ws( exporting url = f_cut->connect( )  test = abap_true ).
  endmethod.

  method is_message.

    cl_abap_unit_assert=>assert_equals(
    act = f_cut->is_message( '{"type":"message", } <@U44EDFJUR>' )
    exp = abap_true
    msg = 'test if an incoming message is a message typed by a user' ).

  endmethod.

  method health_check.

*    FIELD-SYMBOLS: <ok> type any.
*    <ok> = 'oops'.

*    f_cut->health_check( ).

  endmethod.

endclass.