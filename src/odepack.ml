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

type 'a vec = (float, float64_elt, 'a) Array1.t
type 'a mat = (float, float64_elt, 'a) Array2.t
type 'a int_vec = (int, int_elt, 'a) Array1.t

external set_layout : ('a, 'b, _) Array1.t -> 'l layout -> ('a, 'b, 'l) Array1.t
  = "ocaml_odepack_set_layout"
(* [set_layout ba l] _modifies_ the bigarray [ba] to it becomes of the
   new layout.  [ba] should not be used after that (its internal
   informations do not correspond anymore to those of the type
   system). *)

type 'a vec_field = float -> 'a vec -> 'a vec -> unit
(* [f t y y'] where y' must be used for the storage of the fector
   field at (t,y):  y' <- f(t,y). *)

type 'a jacobian =
| Auto_full
| Auto_band of int * int
| Full of (float -> 'a vec -> 'a mat -> unit)
| Band of (float -> 'a vec -> int -> 'a mat -> unit)

type task = TOUT | One_step | First_msh_point | TOUT_TCRIT | One_step_TCRIT

type 'a t = {
  f: 'a vec_field;
  mutable t: float;
  y: 'a vec;
  mutable state: int;
  rwork: fortran_layout vec;
  iwork: fortran_layout int_vec;
  advance: float -> unit
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

external lsoda_fortran : 'a vec_field -> 'a vec -> float -> float ->
  itol:int -> rtol:'b vec -> atol:'c vec -> task -> state:int ->
  rwork:fortran_layout vec -> iwork:fortran_layout int_vec -> 'a vec -> int
    = "ocaml_odepack_dlsoda_bc" "ocaml_odepack_dlsoda"

let tolerances name neq layout rtol rtol_vec atol atol_vec =
  let itol, rtol = match rtol_vec with
    | None ->
      let v = Array1.create float64 fortran_layout 1 in
      v.{1} <- rtol;
      1, set_layout v layout
    | Some v ->
      if Array1.dim v <> neq then
        invalid_arg(name ^ ": dim rtol_vec <> size ODE system");
      3, v  in
  let itol, atol = match atol_vec with
    | None ->
      let v = Array1.create float64 fortran_layout 1 in
      v.{1} <- atol;
      itol, set_layout v layout
    | Some v ->
      if Array1.dim v <> neq then
        invalid_arg(name ^ ": dim atol_vec <> size ODE system");
      itol + 1, v  in
  itol, rtol, atol

let lsoda ?(rtol=1e-6) ?rtol_vec ?(atol=1e-6) ?atol_vec ?jac f t0 y0 tout =
  let neq = Array1.dim y0 in
  let layout = Array1.layout y0 in
  let itol, rtol, atol =
    tolerances "Odepack.lsoda" neq layout rtol rtol_vec atol atol_vec in
  (* For now, JT = 2 *)
  let lrn = 20 + 16 * neq in
  let lrs = 22 + 9 * neq + neq * neq in
  let dim_rwork = if lrn > lrs then lrn else lrs in
  let rwork = Array1.create float64 fortran_layout dim_rwork
  and iwork = Array1.create int fortran_layout (20 + neq) in
  (* Create a bigarray, proxy for rwork, that will encapsulate the
     array of devivatives for OCaml. *)
  let ydot = set_layout (Array1.sub rwork 1 neq) layout in
  let state = lsoda_fortran f y0 t0 tout ~itol ~rtol ~atol TOUT ~state:1
    ~rwork ~iwork ydot in
  if state = -3 then invalid_arg "Odepack.lsoda (see written message)";

  let rec advance t =
    let state = lsoda_fortran f y0 t0 t ~itol ~rtol ~atol TOUT ~state:ode.state
      ~rwork ~iwork ydot in
    if state = -3 then invalid_arg "Odepack.advance (see written message)";
    ode.t <- t;
    ode.state <- state
  and ode = { f = f;  t = tout; y = y0;
              state = state;  rwork = rwork;  iwork = iwork;
              advance = advance } in
  ode

