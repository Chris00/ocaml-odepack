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

#define CALL(name) d ## name ## _
#define SUBROUTINE(name) extern void CALL(name)
#define FUN(name) ocaml_odepack_d ## name

typedef doublereal* vec;
typedef doublereal* mat; /* fortran (columnwise) layout */
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

extern void xsetf_(integer* MFLAG);

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

CAMLexport
value ocaml_odepack_xsetf(value vflag)
{
  /* noalloc */
  integer mflag = Int_val(vflag);
  xsetf_(&mflag);
  return Val_unit;
}

/* Since NEQ may be an array (with NEQ(1) only used by LSODA), one
 * will use it to) pass to the function evaluating the Caml closure,
 * pass the bigarray Y (to avoid recreating it) and pass a bigarray
 * structure to YDOT (created on the first call),...  */
static void eval_vec_field(integer* NEQ, doublereal* T, vec Y, vec YDOT)
{
  CAMLparam0();
  CAMLlocal1(vT);
  value *vNEQ = (value *) NEQ;
  value *closure_f = (value *) vNEQ[1];
  value vYDOT = vNEQ[2];
  value vY = vNEQ[5]; /* data location is always the same */

  Caml_ba_array_val(vYDOT)->data = YDOT; /* update RWORK location */
  vT = caml_copy_double(*T);
  caml_callback3(*closure_f, vT, vY, vYDOT);
  CAMLreturn0;
}

static void eval_jac(integer* NEQ, doublereal* T, vec Y,
                     integer* ML, integer* MU, mat PD, integer* NROWPD)
{
  CAMLparam0();
  CAMLlocal1(vT);
  value *vNEQ = (value *) NEQ;
  value *closure_jac = (value *) vNEQ[3];
  value vPD = vNEQ[7];
  
  vT = caml_copy_double(*T);
  vNEQ[4] = vT;
  Caml_ba_array_val(vPD)->data = PD; /* update location */
  caml_callbackN(*closure_jac, 4, &(vNEQ[4])); /* vT, vY, vd, vPD */
  CAMLreturn0;
}


CAMLexport
value ocaml_odepack_set_iwork(value vIWORK, value vML, value vMU,
                              value vIXPR, value vMXSTEP)
{
  /* noalloc */
  INT_VEC_PARAMS(IWORK);
  IWORK_data[0] = Int_val(vML);
  IWORK_data[1] = Int_val(vMU);
  IWORK_data[4] = (Bool_val(vIXPR))? 1 : 0;
  IWORK_data[5] = Int_val(vMXSTEP);
  IWORK_data[6] = 0; /* MXHNIL */
  IWORK_data[7] = 0; /* MXORDN */
  IWORK_data[8] = 0; /* MXORDS */
  return Val_unit;
}

CAMLexport
value FUN(lsoda)(value vY, value vT, value vTOUT,
                 value vITOL, value vRTOL, value vATOL, value vITASK,
                 value vISTATE, value vRWORK, value vIWORK,
                 value vJT,  value vYDOT, value vPD)
{
  CAMLparam5(vY, vT, vTOUT, vITOL, vRTOL);
  CAMLxparam5(vATOL, vITASK, vISTATE, vRWORK, vIWORK);
  CAMLxparam3(vJT, vYDOT, vPD);
  value *closure_f = NULL;
  value *closure_jac = NULL;
  VEC_PARAMS(Y);
  value NEQ[8]; /* a "value" is large enough to contain any integer */
  doublereal T = Double_val(vT), TOUT = Double_val(vTOUT);
  integer ITOL = Int_val(vITOL);
  integer ITASK = Int_val(vITASK) + 1;
  integer ISTATE = Int_val(vISTATE);
  integer IOPT = 1;
  VEC_PARAMS(RWORK);
  INT_VEC_PARAMS(IWORK);
  integer JT = Int_val(vJT);

  /* The function registered can vary between calls.  For a given
     registration, the *pointer* returned by caml_named_value is
     constant (thus is passed as a param to eval_vec_field,...). */
  closure_f = caml_named_value("Odepack.lsoda.f");
  closure_jac = caml_named_value("Odepack.lsoda.jac");

  /* Organized so one can pass this array to the callback */
  ((int *) NEQ)[0] = dim_Y;
  NEQ[1] = (value) closure_f; /* "value" can hold any pointer */
  NEQ[2] = vYDOT;
  NEQ[3] = (value) closure_jac;
  /* NEQ[4] reserved for vT */
  NEQ[5] = vY;
  NEQ[6] = Val_int(IWORK_data[1]+1); /* MU+1, row corresponding to diagonal */
  NEQ[7] = vPD;

  CALL(lsoda)(&eval_vec_field, (integer *) NEQ, Y_data, &T, &TOUT,
              &ITOL, VEC_DATA(RTOL), VEC_DATA(ATOL), &ITASK, &ISTATE, &IOPT,
              RWORK_data, &dim_RWORK,  IWORK_data, &dim_IWORK,
              &eval_jac, &JT);
  
  CAMLreturn(Val_int(ISTATE));
}

CAMLexport
value FUN(lsoda_bc)(value * argv, int argn)
{
  return FUN(lsoda)(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5],
                    argv[6], argv[7], argv[8], argv[9], argv[10], argv[11],
                    argv[12]);
}

