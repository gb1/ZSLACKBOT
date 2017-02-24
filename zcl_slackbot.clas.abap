class ZCL_SLACKBOT definition
  public
  final
  create public .

public section.

  interfaces IF_APC_WSP_EVENT_HANDLER_BASE .
  interfaces IF_APC_WSP_EVENT_HANDLER .

  methods CONSTRUCTOR .
  methods SHOW_RESULTS
    importing
      !P_TASK type STRING .
  protected section.
private section.

  data CANARY type STRING .
  data MESSAGE_MANAGER type ref to IF_APC_WSP_MESSAGE_MANAGER .
  data WS_CLIENT type ref to IF_APC_WSP_CLIENT .
  data WS_MESSAGE type ref to IF_APC_WSP_MESSAGE .
  data READ_PACKAGE_NAME type BOOLEAN .
  data STORED_WS_URL type STRING .
  data TEST_RESULTS type ZTTTEST_RESULT .

  methods PARSE_PACKAGE_NAME
    importing
      !MESSAGE type STRING
    returning
      value(PACKAGE) type STRING .
  methods IS_RUN_TESTS
    importing
      !MESSAGE type STRING
    returning
      value(IS_RUN_TESTS) type BOOLEAN .
  methods IS_HEALTH_CHECK
    importing
      !MESSAGE type STRING
    returning
      value(IS_HEALTH_CHECK) type BOOLEAN .
  methods IS_MESSAGE
    importing
      !MESSAGE type STRING
    returning
      value(IS_MESSAGE) type BOOLEAN .
  methods IS_DONKEY_CAM
    importing
      !MESSAGE type STRING
    returning
      value(IS_DONKEY) type BOOLEAN .
  methods SEND_MESSAGE
    importing
      !MESSAGE type STRING .
  methods TIME_TO_QUIT
    importing
      !MESSAGE type STRING
    returning
      value(DIE) type STRING .
  methods CONNECT_TO_WS
    importing
      !URL type STRING
      !TEST type BOOLEAN optional .
  methods CONNECT
    returning
      value(WEB_SOCKET_URL) type STRING .
  methods HEALTH_CHECK .
  methods RUN_TESTS .
ENDCLASS.



CLASS ZCL_SLACKBOT IMPLEMENTATION.


  method connect.

    "curl https://slack.com/api/rtm.start?token=xoxb-140489528977-nzVptdasm0HqqvOzxcJM1qq7 | grep -Po (wss:.*)"

    cl_http_client=>create_by_url(
      exporting
        url           = 'https://slack.com'
        ssl_id        = 'ANONYM'
      importing
         client        = data(http_client) ).

    cl_http_utility=>set_request_uri( request = http_client->request
                                      uri  = '/api/rtm.start?token=xoxb-140489528977-nzVptdasm0HqqvOzxcJM1qq7' ).

    http_client->send( ).

    http_client->receive(
      exceptions
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        others                     = 4
    ).

    http_client->response->get_status(
        importing
          code = data(code) ).

    data(json_response) = http_client->response->if_http_entity~get_cdata( ).

    http_client->close(
        exceptions
          http_invalid_state = 1
          others             = 2
      ).

    find first occurrence of regex `(wss:.*)"` in json_response submatches web_socket_url.

    replace all occurrences of `\/` in web_socket_url with `/`.

    stored_ws_url = web_socket_url.

  endmethod.


  method connect_to_ws.

    try.
        ws_client = cl_apc_wsp_client_manager=>create_by_url( i_url = url
                                                              i_event_handler = me ).

        ws_client->connect( ).

        message_manager ?= ws_client->get_message_manager( ).
        ws_message         ?= message_manager->create_message( ).
        ws_message->set_text( `{"id": 1,"type": "message","channel": "C33E57ZHD","text": "Hello world"}` ).
        message_manager->send( ws_message ).

*    if test = abap_true. ":-)
*      wait for push channels until me->canary is not initial up to 1 seconds.
*    else.
        wait for push channels until me->canary is not initial.
*    endif.

      catch cx_apc_error into data(lx_error).

        data(error) = lx_error->get_text( ).

    endtry.

  endmethod.


  method constructor.

    data(test_runner) = new zcl_test_runner( 'ZCT' ).
    test_results = test_runner->go( ).

  endmethod.


  method health_check.

    send_message( `Looking for short dumps... :hankey:` ).

    data: oh_snap   type rssrc_t_snap_found,
          date_from type d,
          date_to   type d.

    date_from = sy-datum - 100.
    date_to = sy-datum.

    select * from snap_beg into table @data(dumps).

    loop at dumps into data(dump) where seqno = '000'.

      me->send_message( `Naughty user ` && dump-uname && ` caused a short dump on ` && dump-datum && ` at`
        && dump-uzeit && ` ,the error was ` && dump-flist+5(50)
      ).

    endloop.

*    call function 'RSSEARCHLOGS_ST22'
*      exporting
*        i_date_from    = date_from
*        i_date_to      = date_to
*        i_time_from    = '000000'
*        i_time_to      = '235959'
*      importing
*        e_t_snap_found = oh_snap.

*    loop at oh_snap into data(snap).
*
*      me->send_message( `Naughty user ` && snap-uname && ` caused a short dump on ` && snap-datum && ` at`
*        && snap-uzeit && ` ,the error was ` && snap-errid && ` -> ` && snap-text
*      ).
*
*    endloop.

  endmethod.


  method if_apc_wsp_event_handler~on_close.

  endmethod.


  method if_apc_wsp_event_handler~on_error.

  endmethod.


  method if_apc_wsp_event_handler~on_message.

    data(my_message) = i_message->get_text( ).

    if time_to_quit( my_message ).
      send_message('bye bye').
      me->canary = 'die'.
    endif.


    if is_donkey_cam( my_message ).
      send_message(':horse: :horse: :horse:').
      send_message('https://www.thedonkeysanctuary.org.uk/webcam1').
    endif.

    if is_health_check( my_message ).
      health_check( ).
    endif.

    if is_message( my_message ) and read_package_name = abap_true.
      send_message(':runner: running tests...').
      run_tests( ).
*      data(package) = parse_package_name( my_message ).
*      data(test_runner) = new zcl_test_runner( parse_package_name( my_message ) ).
*      send_message(':runner: running tests...').
*      data(test_results) = test_runner->go( ).
**
*      loop at test_results into data(result).
*        send_message( result-method ).
*      endloop.

    endif.

    if is_run_tests( my_message ).
      send_message( ':squirrel: OK, which package would you like to test?' ).
      read_package_name = abap_true.
    endif.


  endmethod.


  method if_apc_wsp_event_handler~on_open.

  endmethod.


  method is_donkey_cam.

    if message cp `*donkeys*` and message cs `<@U44EDFJUR>`.
      is_donkey = abap_true.
    endif.

  endmethod.


  method is_health_check.

    if message cp `*health check*` and message cs `<@U44EDFJUR>`.
      is_health_check = abap_true.
    endif.

  endmethod.


  method is_message.

    if message cp `*"type":"message"*`. "and message cs `<@U44EDFJUR>`.
      is_message = abap_true.
    endif.

  endmethod.


  method is_run_tests.

    if message cp `*run tests*` and message cs `<@U44EDFJUR>`.
      is_run_tests = abap_true.
    endif.

  endmethod.


  method parse_package_name.

    find first occurrence of regex `"text":"([A-Z]*)"` in message submatches package.

  endmethod.


  method run_tests.



*    me->canary = 'die'.

*    data(test_runner) = new zcl_test_runner( 'ZCT' ).
*    data(results) = test_runner->go( ).
*
*    connect_to_ws( me->stored_ws_url ).
*
    read_package_name = abap_false.

    loop at test_results into data(result).

      if result-result = 'FAIL'.
        send_message( `:red_circle: Failing test ` && result-method && ` in class`
        && result-class && ` -> ` && result-description ).
      endif.

      if result-result = 'PASS'.
        send_message( `:white_check_mark: Passing test ` && result-method && ` in class`
          && result-class ).
      endif.

    endloop.


*    call function 'ZFM_TEST_RUNNER'
*      destination 'NONE'
*      starting new task 'TESTS'
*      calling me->show_results on end of task
*      exporting
*        package = 'ZCT'.

  endmethod.


  method send_message.

    message_manager ?= ws_client->get_message_manager( ).
    ws_message         ?= message_manager->create_message( ).
    ws_message->set_text( `{"id": 1,"type": "message","channel": "C33E57ZHD","text": "` && message && `"}` ).
    message_manager->send( ws_message ).

  endmethod.


  method show_results.

    break-point.

  endmethod.


  method time_to_quit.

    if message cp '*/nex*'.
      die = abap_true.
    endif.

  endmethod.
ENDCLASS.