(* File: odepack.ml

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3 or
   later as published by the Free Software Foundation, with the special
   exception on linking described in the file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. *)

open Bigarray

type vec = (float, float64_elt, fortran_layout) Array1.t
type mat = (float, float64_elt, fortran_layout) Array2.t
type int_vec = (int, int_elt, fortran_layout) Array1.t

(* specialize version to int (for speed) *)
let max i j = if (i:int) > j then i else j

type vec_field = float -> vec -> vec -> unit
(* [f t y y'] where y' must be used for the storage of the fector
   field at (t,y):  y' <- f(t,y). *)

type jacobian =
| Auto_full
| Auto_band of int * int
| Full of (float -> vec -> mat -> unit)
| Band of int * int * (float -> vec -> int -> mat -> unit)

type task = TOUT | One_step | First_msh_point | TOUT_TCRIT | One_step_TCRIT

type t = {
  f: vec_field;
  mutable t: float;
  y: vec;
  mutable state: int;
  rwork: vec;
  iwork: int_vec;
  advance: float -> unit;
}

let t ode = ode.t
let vec ode = ode.y
let hu ode = ode.rwork.{11}
let hcur ode = ode.rwork.{12}
let tcur ode = ode.rwork.{13}
let tolsf ode = ode.rwork.{14}
let tsw ode = ode.rwork.{15} (* only for lsoda *)
let nst ode = ode.iwork.{11}
let nfe ode = ode.iwork.{12}
let nje ode = ode.iwork.{13}
let nqu ode = ode.iwork.{14}
let nqcur ode = ode.iwork.{15}
let imxer ode = ode.iwork.{16} (* FIXME: fortran/C layout *)
let advance ode = ode.advance

let sol ode t =
  ode.advance t;
  ode.y

(* The Jacobian must have Fortran layout as it must be presented in a
   columnwise manner *)
external lsoda_ : vec_field -> vec -> float -> float ->
  itol:int -> rtol:vec -> atol:vec -> task -> state:int ->
  rwork:vec -> iwork:int_vec ->
  jac:(float -> vec -> int -> mat -> unit) -> jt:int ->
  ydot:vec -> pd:mat -> int
    = "ocaml_odepack_dlsoda_bc" "ocaml_odepack_dlsoda"

external set_iwork : int_vec -> ml:int -> mu:int -> mxstep:int -> unit
  = "ocaml_odepack_set_iwork"

let tolerances name neq rtol rtol_vec atol atol_vec =
  let itol, rtol = match rtol_vec with
    | None ->
      let v = Array1.create float64 fortran_layout 1 in
      v.{1} <- rtol;
      1, v
    | Some v ->
      if Array1.dim v <> neq then
        invalid_arg(name ^ ": dim rtol_vec <> size ODE system");
      3, v  in
  let itol, atol = match atol_vec with
    | None ->
      let v = Array1.create float64 fortran_layout 1 in
      v.{1} <- atol;
      itol, v
    | Some v ->
      if Array1.dim v <> neq then
        invalid_arg(name ^ ": dim atol_vec <> size ODE system");
      itol + 1, v  in
  itol, rtol, atol

let dummy_jac _ _ _ _ = ()

let lsoda ?(rtol=1e-6) ?rtol_vec ?(atol=1e-6) ?atol_vec ?(jac=Auto_full)
    ?(mxstep=500) ?(copy_y0=true) f y0 t0 tout =
  let neq = Array1.dim y0 in
  let itol, rtol, atol =
    tolerances "Odepack.lsoda" neq rtol rtol_vec atol atol_vec in
  (* FIXME: int allocates "long" on the C side, hence too much is alloc?? *)
  let iwork = Array1.create int fortran_layout (20 + neq) in
  let jt, ml, mu, jac, dim1_jac, lrs = match jac with
    | Auto_full ->
      2, 0, 0, dummy_jac, neq, 22 + (9 + neq) * neq
    | Auto_band(ml, mu) ->
      5, ml, mu, dummy_jac, ml + mu + 1, 22 + 10 * neq + (2 * ml + mu) * neq
    | Full jac ->
      1, 0, 0, (fun t y _ pd -> jac t y pd), neq, 22 + (9 + neq) * neq
    | Band (ml, mu, jac) ->
      4, ml, mu, jac, ml + mu + 1, 22 + 10 * neq + (2 * ml + mu) * neq in
  let lrn = 20 + 16 * neq in
  let rwork = Array1.create float64 fortran_layout (max lrs lrn) in
  (* Create bigarrays, proxy for rwork, that will encapsulate the
     array of devivatives or the jacobian for OCaml. *)
  let ydot = Array1.sub rwork 1 neq in
  let pd = genarray_of_array1 (Array1.sub rwork 1 (dim1_jac * neq)) in
  let pd = reshape_2 pd dim1_jac neq in
  (* Optional inputs. 0 = default value. *)
  rwork.{5} <- 0.; (* H0 *)
  rwork.{6} <- 0.; (* HMAX *)
  rwork.{7} <- 0.; (* HMIN *)
  set_iwork iwork ml mu mxstep;
  let y0 =
    if copy_y0 then
      let y = Array1.create float64 fortran_layout (Array1.dim y0) in
      Array1.blit y0 y;
      y
    else y0 in
  let state = lsoda_ f y0 t0 tout ~itol ~rtol ~atol TOUT ~state:1
    ~rwork ~iwork ~jac ~jt  ~ydot ~pd in
  if state = -3 then
    invalid_arg "Odepack.lsoda (see message written on stdout)";

  let rec advance t =
    let state = lsoda_ f y0 t0 t ~itol ~rtol ~atol TOUT ~state:ode.state
      ~rwork ~iwork ~jac ~jt ~ydot ~pd in
    if state = -3 then
      invalid_arg "Odepack.advance (see message written on stdout)";
    ode.t <- t;
    ode.state <- state
  and ode = { f = f;  t = tout; y = y0;
              state = state;  rwork = rwork;  iwork = iwork;
              advance = advance } in
  ode


(* Error messages
 ***********************************************************************)

external xsetf : int -> unit = "ocaml_odepack_xsetf"

let () =
  xsetf 1 (* using XSETUN(LUN=0) to redirect to stderr does not work *)
