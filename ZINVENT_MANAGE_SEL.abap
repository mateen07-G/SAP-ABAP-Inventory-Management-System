*&---------------------------------------------------------------------*
*& Include          ZINVENT_MANAGE_SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.

SELECT-OPTIONS s_matnum FOR zmaterial_mast-mat_num.

SELECTION-SCREEN END OF BLOCK b1.


SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-002.

SELECTION-SCREEN PUSHBUTTON 5(20)  btn_disp USER-COMMAND DISP.
SELECTION-SCREEN PUSHBUTTON 30(25) btn_add  USER-COMMAND ADDM.
SELECTION-SCREEN PUSHBUTTON 60(20) btn_rece USER-COMMAND RECE.


SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE text-004.

SELECTION-SCREEN PUSHBUTTON 5(20) btn_Low USER-COMMAND LOW.
SELECTION-SCREEN PUSHBUTTON 33(20) btn_out USER-COMMAND OUT.

SELECTION-SCREEN end OF BLOCK b3.



SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE text-003.

PARAMETERS: p_total TYPE i,
            p_avail TYPE i,
            p_low   TYPE i,
            p_out   TYPE i.


SELECTION-SCREEN END OF BLOCK b4.

SELECTION-SCREEN BEGIN OF SCREEN 100 AS WINDOW.

PARAMETERS: p_tmat TYPE zstock_trans-mat_num,
            p_qty  TYPE zstock_trans-quantity.

PARAMETERS: p_in  RADIOBUTTON GROUP g1 DEFAULT 'X',
            pp_out RADIOBUTTON GROUP g1.

SELECTION-SCREEN PUSHBUTTON /10(15) btn_savt
             USER-COMMAND SAVT.
SELECTION-SCREEN PUSHBUTTON 35(25) btn_prnt
             USER-COMMAND PRNT.

SELECTION-SCREEN END OF SCREEN 100.

SELECTION-SCREEN BEGIN OF SCREEN 200 as WINDOW.

PARAMETERS: p_add RADIOBUTTON GROUP g2 DEFAULT 'X'
            USER-COMMAND ACT,
            p_upd RADIOBUTTON GROUP g2,
            p_del RADIOBUTTON GROUP g2.

PARAMETERS: p_matnum  TYPE zmaterial_mast-mat_num,
            p_matnam TYPE zmaterial_mast-mat_name MODIF ID NAM,
            p_price   TYPE zmaterial_mast-unit_price MODIF ID AU,
            p_min     TYPE zmaterial_mast-min_stock MODIF ID AU,
            p_status     TYPE zmaterial_mast-status MODIF ID STA.

SELECTION-SCREEN PUSHBUTTON /10(15) btn_save
             USER-COMMAND SAVM.



SELECTION-SCREEN end OF SCREEN 200.

INITIALIZATION.

  btn_disp = 'STOCK OVERVIEW'.
  btn_add  = 'MATERIAL MANAGEMENT'.
  btn_rece = 'STOCK TRANSACTION'.
  btn_out = 'OUT OF STOCK'.
  btn_low = 'LOW STOCK'.
  btn_savt = 'SAVE'.
  btn_prnt = 'PRINT OUTWARD SLIP'.
  btn_save = 'SAVE'.

AT SELECTION-SCREEN OUTPUT.


  PERFORM display_summary.

  p_total = gv_total_mat.
  p_avail = gv_available.
  p_low   = gv_low_stock.
  p_out   = gv_out_stock.


  LOOP AT SCREEN.

    IF screen-name = 'P_TOTAL'
    OR screen-name = 'P_AVAIL'
    OR screen-name = 'P_LOW'
    OR screen-name = 'P_OUT'.


      screen-input = 0.
      MODIFY SCREEN.

    ENDIF.

  ENDLOOP.



  LOOP AT SCREEN.

    "Material Name
    IF screen-group1 = 'NAM'.

      IF p_add = 'X' OR p_upd = 'X' OR p_del = 'X' .
        screen-active = 1.
      ELSE.
        screen-active = 0.
      ENDIF.

      IF p_add = 'X'.
        screen-input = 1.
      ELSE.
        screen-input = 0.
      ENDIF.

      MODIFY SCREEN.

    ENDIF.


    "Unit Price and Minimum Stock
    IF screen-group1 = 'AU'.

      IF p_add = 'X' OR p_upd = 'X'.
        screen-active = 1.
        screen-input = 1.
      ELSE.
        screen-active = 0.
      ENDIF.

      MODIFY SCREEN.

    ENDIF.

        IF screen-group1 = 'STA'.

      IF p_upd = 'X'.
        screen-active = 1.
        screen-input = 1.
      ELSE.
        screen-active = 0.
      ENDIF.

      MODIFY SCREEN.

    ENDIF.

  ENDLOOP.


AT SELECTION-SCREEN.

  CASE sscrfields-ucomm.

    WHEN 'DISP'.

      PERFORM display_stock.

    WHEN 'RECE'.

      CALL SELECTION-SCREEN 100
        STARTING AT 20 5.

   WHEN 'SAVT'.

      PERFORM save_transaction.

   WHEN 'PRNT'.
  PERFORM print_outward_slip.

  WHEN 'LOW'.
    PERFORM low_stock.
  WHEN 'OUT'.
    PERFORM out_of_stock.

  WHEN 'ADDM'.

    CALL SELECTION-SCREEN 200
    STARTING AT 20 5.

  WHEN 'SAVM'.

  IF p_add = 'X'.

    PERFORM add_material.

  ELSEIF p_upd = 'X'.

    PERFORM update_material.

  ELSEIF p_del = 'X'.

    PERFORM delete_material.

  ENDIF.
  ENDCASE.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_matnum.

  IF p_upd = 'X' OR p_del = 'X'.



    SELECT mat_num, mat_name
      FROM zmaterial_mast
      INTO TABLE @DATA(it_mat2).

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield    = 'MAT_NUM'
        dynpprog    = sy-repid
        dynpnr      = sy-dynnr
        dynprofield = 'P_MATNUM'
        value_org   = 'S'
      TABLES
        value_tab   = it_mat2
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.

  ENDIF.

AT SELECTION-SCREEN ON p_matnum.

  IF ( p_upd = 'X' OR p_del = 'X' ) AND p_matnum is not INITIAL..

    SELECT SINGLE mat_name
      FROM zmaterial_mast
      INTO p_matnam
      WHERE mat_num = p_matnum.

    IF sy-subrc <> 0.

      MESSAGE 'Material does not exist' TYPE 'I'.
      CLEAR p_matnam.

    ENDIF.

  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_status.

  DATA: BEGIN OF it_status OCCURS 0,
          status TYPE zmaterial_mast-status,
        END OF it_status.

  it_status-status = 'ACTIVE'.
  APPEND it_status.

  CLEAR it_status.
  it_status-status = 'INACTIVE'.
  APPEND it_status.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'STATUS'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P_STATUS'
      value_org   = 'S'
    TABLES
      value_tab   = it_status
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

 AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_matnum-low.

  SELECT mat_num, mat_name
    FROM zmaterial_mast
    INTO TABLE @DATA(it_mat1).

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'MAT_NUM'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'S_MATNUM'
      value_org   = 'S'
    TABLES
      value_tab   = it_mat1
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_tmat.


  SELECT mat_num, mat_name
    FROM zmaterial_mast
    INTO TABLE @DATA(it_mat).

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'MAT_NUM'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P_TMAT'
      value_org   = 'S'
    TABLES
      value_tab   = it_mat
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.