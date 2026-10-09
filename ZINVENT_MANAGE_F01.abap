*&---------------------------------------------------------------------*
*& Include          ZINVENT_MANAGE_F01
*&---------------------------------------------------------------------*

FORM display_summary.

  DATA: it_master TYPE TABLE OF zmaterial_mast,
        wa_master TYPE zmaterial_mast.

  DATA: it_trans TYPE TABLE OF zstock_trans,
        wa_trans TYPE zstock_trans.

  DATA: lv_stock TYPE zstock_trans-quantity.

  CLEAR: gv_total_mat,
         gv_available,
         gv_low_stock,
         gv_out_stock.

  "Get materials
  SELECT mat_num min_stock
    FROM zmaterial_mast
    INTO CORRESPONDING FIELDS OF TABLE it_master.

  IF it_master IS INITIAL.
    RETURN.
  ENDIF.

  "Get transactions
  SELECT mat_num trans_type quantity
    FROM zstock_trans
    INTO CORRESPONDING FIELDS OF TABLE it_trans.

  LOOP AT it_master INTO wa_master.

    CLEAR lv_stock.

    "Calculate current stock
    LOOP AT it_trans INTO wa_trans
      WHERE mat_num = wa_master-mat_num.

      IF wa_trans-trans_type = 'IN'.

        lv_stock = lv_stock + wa_trans-quantity.

      ELSEIF wa_trans-trans_type = 'OUT'.

        lv_stock = lv_stock - wa_trans-quantity.

      ENDIF.

    ENDLOOP.

    gv_total_mat = gv_total_mat + 1.

    IF lv_stock = 0.

      gv_out_stock = gv_out_stock + 1.

    ELSEIF lv_stock < wa_master-min_stock.

      gv_low_stock = gv_low_stock + 1.

    ELSE.

      gv_available = gv_available + 1.

    ENDIF.

  ENDLOOP.

ENDFORM.

FORM add_material.

  DATA: wa_material TYPE zmaterial_mast.

  "Validation
  IF p_matnum IS INITIAL.
    MESSAGE 'Enter Material Number' TYPE 'I'.
    RETURN.
  ENDIF.

  IF p_matnam IS INITIAL.
    MESSAGE 'Enter Material Name' TYPE 'I'.
    RETURN.
  ENDIF.

  IF p_price <= 0.
    MESSAGE 'Enter valid Unit Price' TYPE 'I'.
    RETURN.
  ENDIF.

  IF p_min <= 0.
    MESSAGE 'Enter valid Minimum Stock' TYPE 'I'.
    RETURN.
  ENDIF.

  "Check whether material already exists
  SELECT SINGLE mat_num
    FROM zmaterial_mast
    INTO @wa_material-mat_num
    WHERE mat_num = @p_matnum.

  IF sy-subrc = 0.
    MESSAGE 'Material already exists' TYPE 'I'.
    RETURN.
  ENDIF.

  "Prepare material
  wa_material-mat_num    = p_matnum.
  wa_material-mat_name   = p_matnam.
  wa_material-unit_price = p_price.
  wa_material-min_stock  = p_min.
  wa_material-status     = 'ACTIVE'.

  "Insert material
  INSERT zmaterial_mast FROM @wa_material.

  IF sy-subrc = 0.

    COMMIT WORK.

    MESSAGE 'Material added successfully' TYPE 'S'.

    CLEAR: p_matnum,
           p_matnam,
           p_price,
           p_min.

  ELSE.

    MESSAGE 'Material could not be added' TYPE 'I'.

  ENDIF.

ENDFORM.

FORM update_material.

  DATA: lv_matnum TYPE zmaterial_mast-mat_num.

  IF p_matnum IS INITIAL.
    MESSAGE 'Enter Material Number' TYPE 'I'.
    RETURN.
  ENDIF.

  IF p_price <= 0.
    MESSAGE 'Enter valid Unit Price' TYPE 'I'.
    RETURN.
  ENDIF.

  IF p_min < 0.
    MESSAGE 'Enter valid Minimum Stock' TYPE 'I'.
    RETURN.
  ENDIF.

  IF p_status IS INITIAL.
    MESSAGE 'Enter Status' TYPE 'I'.
    RETURN.
  ENDIF.

  SELECT SINGLE mat_num
    FROM zmaterial_mast
    INTO @lv_matnum
    WHERE mat_num = @p_matnum.

  IF sy-subrc <> 0.
    MESSAGE 'Material does not exist' TYPE 'I'.
    RETURN.
  ENDIF.

  UPDATE zmaterial_mast
    SET unit_price = @p_price,
        min_stock  = @p_min,
        status     = @p_status
    WHERE mat_num  = @p_matnum.

  IF sy-subrc = 0.

    COMMIT WORK.

    MESSAGE 'Material updated successfully' TYPE 'S'.

  ELSE.

    MESSAGE 'Material could not be updated' TYPE 'I'.

  ENDIF.

ENDFORM.

FORM delete_material.

  DATA: lv_matnum TYPE zmaterial_mast-mat_num.

  "Check material exists
  SELECT SINGLE mat_num
    FROM zmaterial_mast
    INTO @lv_matnum
    WHERE mat_num = @p_matnum.

  IF sy-subrc <> 0.
    MESSAGE 'Material does not exist' TYPE 'I'.
    RETURN.
  ENDIF.

  "Check whether transactions exist
  SELECT SINGLE mat_num
    FROM zstock_trans
    INTO @lv_matnum
    WHERE mat_num = @p_matnum.

  IF sy-subrc <> 0.

    "No transactions - physically delete
    DELETE FROM zmaterial_mast
      WHERE mat_num = @p_matnum.

    IF sy-subrc = 0.

      COMMIT WORK.

      MESSAGE 'Material deleted successfully' TYPE 'S'.

      CLEAR: p_matnum,
             p_matnam.

    ELSE.

      MESSAGE 'Material could not be deleted' TYPE 'I'.

    ENDIF.

  ELSE.

    "Transactions exist - make inactive
    UPDATE zmaterial_mast
      SET status = 'INACTIVE'
      WHERE mat_num = @p_matnum.

    IF sy-subrc = 0.

      COMMIT WORK.

      MESSAGE 'Material has transactions and was made inactive'
              TYPE 'S'.

      CLEAR: p_matnum,
             p_matnam.

    ELSE.

      MESSAGE 'Material could not be made inactive' TYPE 'I'.

    ENDIF.

  ENDIF.

ENDFORM.

FORM save_transaction.

  DATA: wa_trans TYPE zstock_trans.

  DATA: lv_max_id TYPE zstock_trans-trans_id,
        lv_stock  TYPE zstock_trans-quantity,
        lv_new_id TYPE zstock_trans-trans_id.

  DATA: it_trans TYPE TABLE OF zstock_trans,
        wa_old   TYPE zstock_trans.

  "Check active material
  SELECT SINGLE mat_num
    FROM zmaterial_mast
    INTO @DATA(lv_matnum)
    WHERE mat_num = @p_tmat
      AND status  = 'ACTIVE'.

  IF sy-subrc <> 0.
    MESSAGE 'Material does not exist' TYPE 'I'.
    RETURN.
  ENDIF.

  "Check quantity
  IF p_qty <= 0.
    MESSAGE 'Quantity must be greater than zero' TYPE 'I'.
    RETURN.
  ENDIF.

  "Get previous transactions
  SELECT mat_num, trans_type, quantity
    FROM zstock_trans
    INTO CORRESPONDING FIELDS OF TABLE @it_trans
    WHERE mat_num = @p_tmat.

  "Calculate current stock
  CLEAR lv_stock.

  LOOP AT it_trans INTO wa_old.

    IF wa_old-trans_type = 'IN'.

      lv_stock = lv_stock + wa_old-quantity.

    ELSEIF wa_old-trans_type = 'OUT'.

      lv_stock = lv_stock - wa_old-quantity.

    ENDIF.

  ENDLOOP.

  "Check OUT quantity
  IF pp_out = 'X'.

    IF p_qty > lv_stock.
      MESSAGE i007(zmh_message) WITH lv_stock.
      RETURN.
    ENDIF.

  ENDIF.

  "Prepare transaction
  CLEAR wa_trans.

  wa_trans-mat_num     = p_tmat.
  wa_trans-quantity    = p_qty.
  wa_trans-trans_date  = sy-datum.
  wa_trans-trans_time  = sy-uzeit.
  wa_trans-created_by  = sy-uname.

  IF p_in = 'X'.

    wa_trans-trans_type = 'IN'.

  ELSEIF pp_out = 'X'.

    wa_trans-trans_type = 'OUT'.

  ENDIF.

  "Generate transaction ID
  SELECT MAX( trans_id )
    FROM zstock_trans
    INTO @lv_max_id.

  IF lv_max_id IS INITIAL.
    lv_new_id = 100001.
  ELSE.
    lv_new_id = lv_max_id + 1.
  ENDIF.

  wa_trans-trans_id = lv_new_id.

  "Save transaction
  INSERT zstock_trans FROM @wa_trans.

  IF sy-subrc = 0.

    COMMIT WORK.

    "Remember exact saved transaction
    gv_last_trans_id = wa_trans-trans_id.

    MESSAGE 'Transaction saved successfully' TYPE 'S'.

  ELSE.

    MESSAGE 'Transaction could not be saved' TYPE 'I'.

  ENDIF.

ENDFORM.


FORM print_outward_slip.

  DATA: lv_fm_name TYPE rs38l_fnam,
        wa_trans   TYPE zstock_trans,
        wa_master  TYPE zmaterial_mast.

  DATA: it_trans TYPE TABLE OF zstock_trans,
        wa_old   TYPE zstock_trans.

  DATA: lv_previous_stock TYPE zstock_trans-quantity,
        lv_remaining_stock TYPE zstock_trans-quantity.

  "Check whether a transaction was saved
  IF gv_last_trans_id IS INITIAL.
    MESSAGE 'Please save a transaction first' TYPE 'I'.
    RETURN.
  ENDIF.

  "Get exact saved transaction
  SELECT SINGLE *
    FROM zstock_trans
    INTO wa_trans
    WHERE trans_id = gv_last_trans_id.

  IF sy-subrc <> 0.
    MESSAGE 'Transaction not found' TYPE 'I'.
    RETURN.
  ENDIF.

  "Print is only for OUT transaction
  IF wa_trans-trans_type <> 'OUT'.
    MESSAGE 'Print is available only for OUT transaction' TYPE 'I'.
    RETURN.
  ENDIF.

  "Get material master
  SELECT SINGLE *
    FROM zmaterial_mast
    INTO wa_master
    WHERE mat_num = wa_trans-mat_num.

  IF sy-subrc <> 0.
    MESSAGE 'Material does not exist' TYPE 'I'.
    RETURN.
  ENDIF.

  "Get transactions before current transaction
  SELECT *
    FROM zstock_trans
    INTO TABLE it_trans
    WHERE mat_num = wa_trans-mat_num
      AND trans_id < wa_trans-trans_id.

  "Calculate previous stock
  CLEAR lv_previous_stock.

  LOOP AT it_trans INTO wa_old.

    IF wa_old-trans_type = 'IN'.

      lv_previous_stock =
        lv_previous_stock + wa_old-quantity.

    ELSEIF wa_old-trans_type = 'OUT'.

      lv_previous_stock =
        lv_previous_stock - wa_old-quantity.

    ENDIF.

  ENDLOOP.

  "Calculate remaining stock
  lv_remaining_stock =
    lv_previous_stock - wa_trans-quantity.

  "Get Smart Form function module
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname = 'ZSF_OUTWARD_STOCK'
    IMPORTING
      fm_name  = lv_fm_name
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.

  IF sy-subrc <> 0.
    MESSAGE 'Smart Form not found' TYPE 'I'.
    RETURN.
  ENDIF.

  "Call Smart Form
  CALL FUNCTION lv_fm_name
    EXPORTING
      is_trans           = wa_trans
      is_master          = wa_master
      iv_previous_stock  = lv_previous_stock
      iv_remaining_stock = lv_remaining_stock.

ENDFORM.