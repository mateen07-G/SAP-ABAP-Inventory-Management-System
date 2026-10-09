*&---------------------------------------------------------------------*
*& Include          ZINVENT_MANAGE_TOP
*&---------------------------------------------------------------------*

TABLES: zmaterial_mast,
        zstock_trans,
        sscrfields.

  TYPES: BEGIN OF ty_stock,
           mat_num       TYPE zmaterial_mast-mat_num,
           mat_name      TYPE zmaterial_mast-mat_name,
           unit_price    TYPE zmaterial_mast-unit_price,
           min_stock     TYPE zmaterial_mast-min_stock,
           total_in      TYPE zstock_trans-quantity,
           total_out     TYPE zstock_trans-quantity,
           current_stock TYPE zstock_trans-quantity,
           total_amount  TYPE p LENGTH 15 DECIMALS 2,
           status        TYPE char20,
           status_m      TYPE Zmaterial_mast-status,
         END OF ty_stock.

DATA: gv_total_mat    TYPE i,
      gv_available    TYPE i,
      gv_low_stock    TYPE i,
      gv_out_stock    TYPE i,
      gv_last_trans_id TYPE zstock_trans-trans_id.