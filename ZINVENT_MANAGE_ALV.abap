*&---------------------------------------------------------------------*
*& Include          ZINVENT_MANAGE_ALV
*&---------------------------------------------------------------------*

FORM display_stock.

  DATA: it_stock TYPE TABLE OF ty_stock,
        wa_stock TYPE ty_stock.

  DATA: it_master TYPE TABLE OF zmaterial_mast,
        wa_master TYPE zmaterial_mast.

  DATA: it_trans TYPE TABLE OF zstock_trans,
        wa_trans TYPE zstock_trans.

  DATA: it_fieldcat TYPE slis_t_fieldcat_alv,
        wa_fieldcat LIKE LINE OF it_fieldcat.

  "Get Materials
  IF s_matnum[] IS INITIAL.

    SELECT mat_num mat_name unit_price min_stock Status
      FROM zmaterial_mast
      INTO CORRESPONDING FIELDS OF TABLE it_master.

  ELSE.

    SELECT mat_num mat_name unit_price min_stock Status
      FROM zmaterial_mast
      INTO CORRESPONDING FIELDS OF TABLE it_master
      WHERE mat_num IN s_matnum.

  ENDIF.

  IF it_master IS INITIAL.
    MESSAGE 'No material found' TYPE 'I'.
    RETURN.
  ENDIF.

  "Get Transactions
  SELECT mat_num trans_type quantity
    FROM zstock_trans
    INTO CORRESPONDING FIELDS OF TABLE it_trans.

  "Calculate Stock
  LOOP AT it_master INTO wa_master.

    CLEAR wa_stock.

    wa_stock-mat_num    = wa_master-mat_num.
    wa_stock-mat_name   = wa_master-mat_name.
    wa_stock-unit_price = wa_master-unit_price.
    wa_stock-min_stock  = wa_master-min_stock.
    wa_stock-status_m   = wa_master-status.

    LOOP AT it_trans INTO wa_trans
      WHERE mat_num = wa_master-mat_num.

      IF wa_trans-trans_type = 'IN'.

        wa_stock-total_in =
          wa_stock-total_in + wa_trans-quantity.

      ELSEIF wa_trans-trans_type = 'OUT'.

        wa_stock-total_out =
          wa_stock-total_out + wa_trans-quantity.

      ENDIF.

    ENDLOOP.

    wa_stock-current_stock =
      wa_stock-total_in - wa_stock-total_out.

    wa_stock-total_amount =
      wa_stock-current_stock * wa_stock-unit_price.

    "Status
    IF wa_stock-current_stock = 0.

      wa_stock-status = 'OUT OF STOCK'.

    ELSEIF wa_stock-current_stock < wa_stock-min_stock.

      wa_stock-status = 'LOW STOCK'.

    ELSE.

      wa_stock-status = 'AVAILABLE'.

    ENDIF.

    APPEND wa_stock TO it_stock.

  ENDLOOP.

  "Field Catalog
  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'MAT_NUM'.
  wa_fieldcat-seltext_l = 'Material Number'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'MAT_NAME'.
  wa_fieldcat-seltext_l = 'Material Name'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'UNIT_PRICE'.
  wa_fieldcat-seltext_l = 'Unit Price'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'MIN_STOCK'.
  wa_fieldcat-seltext_l = 'Minimum Stock'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'TOTAL_IN'.
  wa_fieldcat-seltext_l = 'Total IN'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'TOTAL_OUT'.
  wa_fieldcat-seltext_l = 'Total OUT'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'CURRENT_STOCK'.
  wa_fieldcat-seltext_l = 'Current Stock'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'TOTAL_AMOUNT'.
  wa_fieldcat-seltext_l = 'Total Amount'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'STATUS'.
  wa_fieldcat-seltext_l = 'Status'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'STATUS_M'.
  wa_fieldcat-seltext_l = 'Status of Material'.
  APPEND wa_fieldcat to it_fieldcat.

  "Display ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      i_callback_user_command = 'DISPLAY'
      I_GRID_TITLE       = 'Stock Overview'
      it_fieldcat             = it_fieldcat
    TABLES
      t_outtab                = it_stock
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.

ENDFORM.


FORM display USING r_ucomm LIKE sy-ucomm
                   rs_selfield TYPE slis_selfield.

  DATA: it_trans TYPE TABLE OF zstock_trans.

  CASE r_ucomm.

    WHEN '&IC1'.

      IF rs_selfield-fieldname = 'MAT_NUM'.

        SELECT *
          FROM zstock_trans
          INTO TABLE it_trans
          WHERE mat_num = rs_selfield-value.

        IF it_trans IS INITIAL.
          MESSAGE 'No transactions found' TYPE 'I'.
          RETURN.
        ENDIF.

        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
          EXPORTING
            i_callback_program = sy-repid
            i_structure_name   = 'ZSTOCK_TRANS'
            I_GRID_TITLE       = 'Transaction Details'
          TABLES
            t_outtab           = it_trans
          EXCEPTIONS
            program_error = 1
            OTHERS        = 2.

      ENDIF.


  ENDCASE.

ENDFORM.

FORM low_stock.

  DATA: it_stock TYPE TABLE OF ty_stock,
        wa_stock TYPE ty_stock.

  DATA: it_master TYPE TABLE OF zmaterial_mast,
        wa_master TYPE zmaterial_mast.

  DATA: it_trans TYPE TABLE OF zstock_trans,
        wa_trans TYPE zstock_trans.

  DATA: it_fieldcat TYPE slis_t_fieldcat_alv,
        wa_fieldcat LIKE LINE OF it_fieldcat.

  "Get Materials
  SELECT mat_num mat_name min_stock
    FROM zmaterial_mast
    INTO CORRESPONDING FIELDS OF TABLE it_master.

  IF it_master IS INITIAL.
    MESSAGE 'No material found' TYPE 'I'.
    RETURN.
  ENDIF.

  "Get Transactions
  SELECT mat_num trans_type quantity
    FROM zstock_trans
    INTO CORRESPONDING FIELDS OF TABLE it_trans.

  "Calculate stock
  LOOP AT it_master INTO wa_master.

    CLEAR wa_stock.

    wa_stock-mat_num    = wa_master-mat_num.
    wa_stock-mat_name   = wa_master-mat_name.
    wa_stock-min_stock  = wa_master-min_stock.

    LOOP AT it_trans INTO wa_trans
      WHERE mat_num = wa_master-mat_num.

      IF wa_trans-trans_type = 'IN'.

        wa_stock-current_stock =
          wa_stock-current_stock + wa_trans-quantity.

      ELSEIF wa_trans-trans_type = 'OUT'.

        wa_stock-current_stock =
          wa_stock-current_stock - wa_trans-quantity.

      ENDIF.

    ENDLOOP.

    "Check LOW STOCK
    IF wa_stock-current_stock < wa_stock-min_stock
       AND wa_stock-current_stock <> 0.

      wa_stock-status = 'LOW STOCK'.

      APPEND wa_stock TO it_stock.

    ENDIF.

  ENDLOOP.

  IF it_stock IS INITIAL.
    MESSAGE 'No low stock materials' TYPE 'I'.
    RETURN.
  ENDIF.

  "Field Catalog
  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'MAT_NUM'.
  wa_fieldcat-seltext_m = 'Material Number'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'MAT_NAME'.
  wa_fieldcat-seltext_m = 'Material Name'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'MIN_STOCK'.
  wa_fieldcat-seltext_m = 'Minimum Stock'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'CURRENT_STOCK'.
  wa_fieldcat-seltext_m = 'Current Stock'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'STATUS'.
  wa_fieldcat-seltext_m = 'Status'.
  APPEND wa_fieldcat TO it_fieldcat.

   CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'STATUS M'.
  wa_fieldcat-seltext_m = 'Status Of Material'.
  APPEND wa_fieldcat TO it_fieldcat.

  "Display ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      I_GRID_TITLE       = 'Low Stock'
      it_fieldcat        = it_fieldcat
    TABLES
      t_outtab           = it_stock
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.

ENDFORM.

FORM out_of_stock.

  DATA: it_stock TYPE TABLE OF ty_stock,
        wa_stock TYPE ty_stock.

  DATA: it_master TYPE TABLE OF zmaterial_mast,
        wa_master TYPE zmaterial_mast.

  DATA: it_trans TYPE TABLE OF zstock_trans,
        wa_trans TYPE zstock_trans.

  DATA: it_fieldcat TYPE slis_t_fieldcat_alv,
        wa_fieldcat LIKE LINE OF it_fieldcat.

  "Get Materials
  SELECT mat_num mat_name min_stock
    FROM zmaterial_mast
    INTO CORRESPONDING FIELDS OF TABLE it_master.

  IF it_master IS INITIAL.
    MESSAGE 'No material found' TYPE 'I'.
    RETURN.
  ENDIF.

  "Get Transactions
  SELECT mat_num trans_type quantity
    FROM zstock_trans
    INTO CORRESPONDING FIELDS OF TABLE it_trans.

  "Calculate stock
  LOOP AT it_master INTO wa_master.

    CLEAR wa_stock.

    wa_stock-mat_num   = wa_master-mat_num.
    wa_stock-mat_name  = wa_master-mat_name.
    wa_stock-min_stock = wa_master-min_stock.

    LOOP AT it_trans INTO wa_trans
      WHERE mat_num = wa_master-mat_num.

      IF wa_trans-trans_type = 'IN'.

        wa_stock-current_stock =
          wa_stock-current_stock + wa_trans-quantity.

      ELSEIF wa_trans-trans_type = 'OUT'.

        wa_stock-current_stock =
          wa_stock-current_stock - wa_trans-quantity.

      ENDIF.

    ENDLOOP.

    "Check OUT OF STOCK
    IF wa_stock-current_stock = 0.

      wa_stock-status = 'OUT OF STOCK'.

      APPEND wa_stock TO it_stock.

    ENDIF.

  ENDLOOP.

  IF it_stock IS INITIAL.
    MESSAGE 'No out of stock materials' TYPE 'I'.
    RETURN.
  ENDIF.

  "Field Catalog
  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'MAT_NUM'.
  wa_fieldcat-seltext_m = 'Material Number'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'MAT_NAME'.
  wa_fieldcat-seltext_m = 'Material Name'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'MIN_STOCK'.
  wa_fieldcat-seltext_m = 'Minimum Stock'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'CURRENT_STOCK'.
  wa_fieldcat-seltext_m = 'Current Stock'.
  APPEND wa_fieldcat TO it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = 'STATUS'.
  wa_fieldcat-seltext_m = 'Status'.
  APPEND wa_fieldcat TO it_fieldcat.

  "Display ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      I_GRID_TITLE       = 'Out Of Stock'
      it_fieldcat        = it_fieldcat
    TABLES
      t_outtab           = it_stock
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.

ENDFORM.