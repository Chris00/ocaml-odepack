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

type task = TOUT | One_step | First_msh_point | TOUT_TCRIT | One_step_TCRIT

external lsoda_fortran : 'a vec_field -> 'a vec -> float -> float ->
  itol:int -> rtol:float -> atol:'a vec -> task -> state:int ->
  rwork:fortran_layout vec -> iwork:fortran_layout int_vec -> 'a vec -> int
    = "ocaml_odepack_dlsoda_bc" "ocaml_odepack_dlsoda"

type 'a t = {
  f: 'a vec_field;
  mutable t: float;
  y: 'a vec;
  itol: int;
  rtol: float;
  atol: 'a vec;
  mutable state: int;
  rwork: fortran_layout vec;
  iwork: fortran_layout int_vec;
  ydot: 'a vec; (* The bigarray created to pass ydot to [f]. *)
}

let get ode = ode.y
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

let lsoda ?(rtol=1e-6) ?(atol=1e-6) ?atol_vec f t y tout =
  let neq = Array1.dim y in
  let itol, atol = match atol_vec with
    | Some v ->
      if Array1.dim v <> neq then
        invalid_arg "Odepack.lsoda: dim atol_vec <> size ODE system";
      2, v
    | None ->
      let v = Array1.create float64 (Array1.layout y) 1 in
      v.{1} <- atol;
      1, v in
  (* For now, JT = 2 *)
  let lrn = 20 + 16 * neq in
  let lrs = 22 + 9 * neq + neq * neq in
  let dim_rwork = if lrn > lrs then lrn else lrs in
  let rwork = Array1.create float64 fortran_layout dim_rwork
  and iwork = Array1.create int fortran_layout (20 + neq) in
  let ydot = set_layout (Array1.sub rwork 1 neq) (Array1.layout y) in
  let state = lsoda_fortran f y t tout ~itol ~rtol ~atol TOUT ~state:1
    ~rwork ~iwork ydot in
  if state = -3 then invalid_arg "Odepack.lsoda (see written message)";
  { f = f;  t = t; y = y;  itol = itol; rtol = rtol; atol = atol;
    state = state;  rwork = rwork;  iwork = iwork;  ydot = ydot }

let advance o t =
  let state = lsoda_fortran o.f o.y o.t t
    ~itol:o.itol ~rtol:o.rtol ~atol:o.atol TOUT ~state:o.state
    ~rwork:o.rwork ~iwork:o.iwork o.ydot in
  if state = -3 then invalid_arg "Odepack.advance (see written message)";
  o.t <- t;
  o.state <- state
