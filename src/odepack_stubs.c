/* File: odepack_stubs.c

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3 or
   later as published by the Free Software Foundation.  See the file
   LICENCE for more details.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. */

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/bigarray.h>
#include <caml/signals.h>

#include "f2c.h"

CAMLexport value
ocaml_odepack_set_layout(value vb, value layout)
{
  CAMLparam2(vb, layout);
  struct caml_ba_array *b = Caml_ba_array_val(vb);
  b->flags &= ~CAML_BA_LAYOUT_MASK;
  b->flags |= Int_val(layout);
  CAMLreturn(vb);
}

#define CALL(name) d ## name ## _
#define SUBROUTINE(name) extern void CALL(name)
#define FUN(name) ocaml_odepack_d ## name

typedef doublereal* vec;
typedef integer* int_vec;
typedef void (*VEC_FIELD)(integer*, doublereal*, vec, vec);
typedef void (*JACOBIAN)(integer*, doublereal*, vec,
                         integer*, integer*, doublereal*, integer*);

/* Fetch vector parameters from bigarray */
#define VEC_PARAMS(V) \
  struct caml_ba_array *big_##V = Caml_ba_array_val(v##V); \
  integer dim_##V = *big_##V->dim; \
  double *V##_data = ((double *) big_##V->data) /*+ (Long_val(vOFS##V) - 1)*/

#define VEC_DATA(V) \
  ((double *) Caml_ba_array_val(v##V)->data)

#define INT_VEC_PARAMS(V) \
  struct caml_ba_array *big_##V = Caml_ba_array_val(v##V); \
  integer dim_##V = *big_##V->dim; \
  int *V##_data = ((int *) big_##V->data) /*+ (Long_val(vOFS##V) - 1)*/

/*
 * Declaring Fortran functions
 **********************************************************************/

SUBROUTINE(lsode)(VEC_FIELD F,
                  integer *NEQ, /*  Number of first-order ODE's. */
                  vec Y,
                  doublereal *T,
                  doublereal *TOUT,
                  integer *ITOL,
                  doublereal *RTOL, /* Relative tolerance */
                  doublereal *ATOL, /* absolute tolerance, scalar or array */
                  integer *ITASK,   /* task to perform */
                  integer *ISTATE,  /* specify the state of the calculation */
                  integer *IOPT,    /* whether optional inputs are used */
                  vec RWORK, /* of size */ integer *LRW,
                  int_vec IWORK, /* of size */ integer *LIW,
                  JACOBIAN JAC, /* optional subroutine for Jacobian matrix */
                  integer *MF);

SUBROUTINE(lsodes)(VEC_FIELD F,
                  integer *NEQ, /*  Number of first-order ODE's. */
                  vec Y,
                  doublereal *T,
                  doublereal *TOUT,
                  integer *ITOL,
                  doublereal *RTOL, /* Relative tolerance */
                  doublereal *ATOL, /* absolute tolerance, scalar or array */
                  integer *ITASK,   /* task to perform */
                  integer *ISTATE,  /* specify the state of the calculation */
                  integer *IOPT,    /* whether optional inputs are used */
                  vec RWORK, /* of size */ integer *LRW,
                  int_vec IWORK, /* of size */ integer *LIW,
                  JACOBIAN JAC, /* optional subroutine for Jacobian matrix */
                  integer *MF);

SUBROUTINE(lsoda)(VEC_FIELD F,
                  integer *NEQ, /* size of the ODE system */
                  vec Y,
                  doublereal *T,
                  doublereal *TOUT,
                  integer *ITOL,
                  doublereal *RTOL,
                  doublereal *ATOL,
                  integer *ITASK,
                  integer *ISTATE,
                  integer *IOPT,
                  vec RWORK, /* of size */ integer *LRW,
                  int_vec IWORK, /* of size */ integer *LIW,
                  JACOBIAN JAC,
                  integer *JT);

SUBROUTINE(lsodar)(VEC_FIELD F,
                   integer *NEQ, /* size of the ODE system */
                   vec Y,
                   doublereal *T,
                   doublereal *TOUT,
                   integer *ITOL,
                   doublereal *RTOL,
                   doublereal *ATOL,
                   integer *ITASK,
                   integer *ISTATE,
                   integer *IOPT,
                   vec RWORK, /* of size */ integer *LRW,
                   int_vec IWORK, /* of size */ integer *LIW,
                   JACOBIAN JAC,
                   integer *JT,
                   void (*G)(integer*, doublereal*, vec, integer*, vec),
                   integer *NG,  /* number of functions */
                   integer *JROOT);

SUBROUTINE(lsodpk)(VEC_FIELD F,
                   integer *NEQ, /*  Number of first-order ODE's. */
                   vec Y,
                   doublereal *T,
                   doublereal *TOUT,
                   integer *ITOL,
                   doublereal *RTOL, /* Relative tolerance */
                   doublereal *ATOL, /* absolute tolerance, scalar or array */
                   integer *ITASK,   /* task to perform */
                   integer *ISTATE,  /* specify the state of the calculation */
                   integer *IOPT,    /* whether optional inputs are used */
                   vec RWORK, /* of size */ integer *LRW,
                   int_vec IWORK, /* of size */ integer *LIW,
                   JACOBIAN JAC, /* optional subroutine for Jacobian matrix */
                   void (*PSOL)(integer*, doublereal*, vec, vec),
                   integer *MF);

// DLSODKR, DLSODI, DLSOIBT, DLSODIS

/*
 * Bindings
 **********************************************************************/

/* Since NEQ may be an array (with NEQ(1) only used by LSODA), one
 * will use it to 1) pass to the function evaluating the Caml closure,
 * 2) pass the bigarray Y (to avoid recreating it) and 3) pass a
 * bigarray structure to YDOT (created on the first call).  */
static void eval_vec_field(integer* NEQ, doublereal* T, vec Y, vec YDOT)
{
  CAMLparam0();
  CAMLlocal1(vT);
  value *vNEQ = (value *) NEQ;
  value closure = vNEQ[1];
  value vY = vNEQ[2]; /* data location is always the same */
  value vYDOT = vNEQ[3];
  Caml_ba_array_val(vYDOT)->data = YDOT; /* update RWORK location */
  vT = caml_copy_double(*T);
  caml_callback3(closure, vT, vY, vYDOT);
  CAMLreturn0;
}


CAMLexport
value FUN(lsoda)(value f, value vY, value vT, value vTOUT,
                 value vITOL, value vRTOL, value vATOL, value vITASK,
                 value vISTATE, value vRWORK, value vIWORK,
                 value vYDOT)
{
  CAMLparam5(f, vY, vT, vTOUT, vITOL);
  CAMLxparam5(vRTOL, vATOL, vITASK, vISTATE, vRWORK);
  CAMLxparam2(vIWORK, vYDOT);
  VEC_PARAMS(Y);
  value NEQ[4]; /* a "value" is large enough to contain any integer */
  doublereal T = Double_val(vT), TOUT = Double_val(vTOUT);
  integer ITOL = Int_val(vITOL);
  integer ITASK = Int_val(vITASK) + 1;
  integer ISTATE = Int_val(vISTATE);
  integer IOPT = 0;
  VEC_PARAMS(RWORK);
  INT_VEC_PARAMS(IWORK);
  integer JT = 2;
  
  ((int *) NEQ)[0] = dim_Y;
  NEQ[1] = f;
  NEQ[2] = vY;
  NEQ[3] = vYDOT;

  CALL(lsoda)(&eval_vec_field, (integer *) NEQ, Y_data, &T, &TOUT,
              &ITOL, VEC_DATA(RTOL), VEC_DATA(ATOL), &ITASK, &ISTATE, &IOPT,
              RWORK_data, &dim_RWORK,  IWORK_data, &dim_IWORK,
              NULL, &JT);
  
  CAMLreturn(Val_int(ISTATE));
}

CAMLexport
value FUN(lsoda_bc)(value * argv, int argn)
{
  return FUN(lsoda)(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5],
                    argv[6], argv[7], argv[8], argv[9], argv[10], argv[11]);
}
